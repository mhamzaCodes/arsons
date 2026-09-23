import 'dart:ui' as ui;

import 'package:flutter/painting.dart' as fl;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../constants/strings.dart';
import '../models/product_model.dart';

abstract class PdfRowEntry {}

class CompanyHeaderEntry extends PdfRowEntry {
  final String companyName;

  /// True when the company's list continues from the previous column/page.
  final bool continued;
  CompanyHeaderEntry(this.companyName, {this.continued = false});
}

class ProductItemEntry extends PdfRowEntry {
  final ProductModel product;
  final int itemNumber;
  ProductItemEntry(this.product, this.itemNumber);
}

// =============================================================================
// Design tokens / layout (A4 = 595.28 x 841.89 pt)
// =============================================================================

class _Palette {
  static const navy = PdfColor.fromInt(0xFF0F2A43);
  static const navySoft = PdfColor.fromInt(0xFF34506B);
  static const gold = PdfColor.fromInt(0xFFC8963E);
  static const band = PdfColor.fromInt(0xFFE3EAF2);
  static const zebra = PdfColor.fromInt(0xFFF6F8FA);
  static const line = PdfColor.fromInt(0xFFB8C2CC);
  static const text = PdfColor.fromInt(0xFF111827);
  static const muted = PdfColor.fromInt(0xFF5B6673);
  static const badgeBg = PdfColor.fromInt(0xFFF1F4F8);
}

// Everything is fixed-width on purpose (no Expanded/Flex + Table).
const double _marginH = 18;
const double _marginTop = 18;
const double _marginBottom = 16;
const double _colGap = 12;

// 2 * 273 + 12 = 558  <=  595.28 - 36 = 559.28
const double _tableWidth = 273;
const double _rateW = 42;
const double _noW = 32;
const double _nameW = _tableWidth - (_rateW * 3) - _noW; // 115

// Nastaleeq needs more vertical room than Naskh.
const double _rowH = 22;
const double _headH = 24;

/// Rows (company banners + items) per column. 27 * 2 = 54 rows per page.
/// If a page ever overflows, lower this number.
const int _rowsPerColumn = 27;

// Bundled font used (a) as the Nastaleeq family name registered in pubspec and
// (b) as the vector font for digits / fallback.
const String _defaultNastaleeqFamily = 'JameelNooriNastaleeq';
const String _nastaleeqAsset = 'assets/fonts/JameelNooriNastaleeq.ttf';

// =============================================================================
// Public API
// =============================================================================

/// Rate-list PDF: always A4, two side-by-side tables per page.
/// Fill order (RTL): RIGHT table first, then LEFT table, then next page.
class PdfGenerator {
  static final _reshaper = ArabicReshaper();

  /// Reshapes Urdu text so characters connect properly in vector PDF text.
  static String formatUrdu(String input) {
    if (input.trim().isEmpty) return input;
    try {
      return _reshaper.reshape(input);
    } catch (_) {
      return input;
    }
  }

  /// Generates printable A4 PDF bytes for the rate list.
  ///
  /// [pageFormat] is accepted only for backward compatibility and is IGNORED
  /// (always A4).
  ///
  /// [useNastaleeq] = true  -> Urdu text is rendered with Flutter's own text
  ///   engine using [nastaleeqFamily] (same look as the app) and embedded in
  ///   the PDF as high-resolution images.
  /// [useNastaleeq] = false -> vector Noto Naskh text (selectable/searchable).
  ///
  /// [nastaleeqFamily] MUST match the `family:` name of Jameel Noori in your
  /// pubspec.yaml.
  static Future<Uint8List> generateRateListPdf(
      List<ProductModel> products, {
        PdfPageFormat? pageFormat,
        bool useNastaleeq = true,
        String nastaleeqFamily = _defaultNastaleeqFamily,
      }) async {
    final fonts = await _loadVectorFonts(preferBundled: useNastaleeq);

    final engine = _TextEngine(
      useNastaleeq: useNastaleeq,
      family: nastaleeqFamily,
      vectorRegular: fonts.$1,
      vectorBold: fonts.$2,
    );

    final builder = _RateListBuilder(
      products: products,
      engine: engine,
      theme: pw.ThemeData.withFont(base: fonts.$1, bold: fonts.$2),
    );

    // Pass 1: dry run, only records which strings need rasterizing.
    engine.recording = true;
    builder.buildPages();
    await engine.rasterizePending();

    // Pass 2: real build using the rasterized text.
    engine.recording = false;
    final pdf = pw.Document();
    for (final page in builder.buildPages()) {
      pdf.addPage(page);
    }
    return pdf.save();
  }

  /// (regular, bold) vector fonts.
  static Future<(pw.Font, pw.Font)> _loadVectorFonts({
    required bool preferBundled,
  }) async {
    Future<(pw.Font, pw.Font)> bundled() async {
      final data = await rootBundle.load(_nastaleeqAsset);
      final f = pw.Font.ttf(data);
      return (f, f);
    }

    Future<(pw.Font, pw.Font)> google() async {
      return (
      await PdfGoogleFonts.notoNaskhArabicRegular(),
      await PdfGoogleFonts.notoNaskhArabicBold(),
      );
    }

    if (preferBundled) {
      try {
        return await bundled();
      } catch (_) {
        return await google();
      }
    }
    try {
      return await google();
    } catch (_) {
      return await bundled();
    }
  }
}

// =============================================================================
// Text engine: Nastaleeq raster text (with vector fallback)
// =============================================================================

class _Req {
  final String text;
  final double size;
  final PdfColor color;
  final bool bold;
  _Req(this.text, this.size, this.color, this.bold);
}

class _Raster {
  final pw.MemoryImage image;
  final double width; // PDF points
  final double height; // PDF points
  _Raster(this.image, this.width, this.height);
}

class _TextEngine {
  _TextEngine({
    required this.useNastaleeq,
    required this.family,
    required this.vectorRegular,
    required this.vectorBold,
  });

  final bool useNastaleeq;
  final String family;
  final pw.Font vectorRegular;
  final pw.Font vectorBold;

  bool recording = false;
  final Map<String, _Req> _pending = {};
  final Map<String, _Raster> _cache = {};

  /// 4x => ~288 dpi when printed at 100%. Sharp, still small files.
  static const double _scale = 4;

  static int _argb(PdfColor c) =>
      (0xFF << 24) |
      ((c.red * 255).round() << 16) |
      ((c.green * 255).round() << 8) |
      (c.blue * 255).round();

  String _key(String t, double s, PdfColor c, bool b) =>
      '${b ? 'b' : 'r'}|$s|${_argb(c)}|$t';

  /// Urdu / mixed Urdu-English text. Pass RAW (un-reshaped) strings.
  pw.Widget text(
      String raw, {
        required double size,
        required PdfColor color,
        bool bold = false,
      }) {
    final t = raw.trim();
    if (t.isEmpty) return pw.SizedBox();

    if (useNastaleeq) {
      final key = _key(t, size, color, bold);
      if (recording) {
        _pending.putIfAbsent(key, () => _Req(t, size, color, bold));
        return pw.SizedBox();
      }
      final r = _cache[key];
      if (r != null) {
        return pw.Image(
          r.image,
          width: r.width,
          height: r.height,
          fit: pw.BoxFit.fill,
        );
      }
    }
    return _vectorMixed(t, size: size, color: color, bold: bold);
  }

  Future<void> rasterizePending() async {
    for (final e in _pending.entries.toList()) {
      try {
        _cache[e.key] = await _rasterize(e.value);
      } catch (err, st) {
        // Falls back to vector text for this string.
        debugPrint('PDF text rasterize failed for "${e.value.text}": $err\n$st');
      }
    }
    _pending.clear();
  }

  Future<_Raster> _rasterize(_Req r) async {
    final painter = fl.TextPainter(
      text: fl.TextSpan(
        text: r.text,
        style: fl.TextStyle(
          fontFamily: family,
          fontSize: r.size * _scale,
          fontWeight: r.bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
          color: ui.Color(_argb(r.color)),
        ),
      ),
      // Flutter's engine does proper shaping + bidi (same as in the app).
      textDirection: ui.TextDirection.rtl,
    )..layout();

    const pad = 2;
    final w = painter.width.ceil() + pad * 2;
    final h = painter.height.ceil() + pad * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    painter.paint(canvas, const ui.Offset(2, 2));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return _Raster(
      pw.MemoryImage(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
      w / _scale,
      h / _scale,
    );
  }

  // ---------------------------------------------------------------------------
  // Vector fallback with manual RTL ordering (brackets / Latin safe)
  // ---------------------------------------------------------------------------

  static final RegExp _tokenRe = RegExp(
    r'[A-Za-z0-9]+(?:[.\-/×][A-Za-z0-9]+)*' // PPR, 10, 60x60, 1.5, 3/4
    r'|[()\[\]]' // brackets
    r'|\s+' // whitespace
    r'|[^\sA-Za-z0-9()\[\]]+', // Urdu words / punctuation
  );

  static const Map<String, String> _mirror = {
    '(': ')',
    ')': '(',
    '[': ']',
    ']': '[',
  };

  pw.Widget _vectorMixed(
      String raw, {
        required double size,
        required PdfColor color,
        required bool bold,
      }) {
    final style = pw.TextStyle(
      font: bold ? vectorBold : vectorRegular,
      fontSize: size,
      color: color,
    );
    final logical = <pw.Widget>[];

    for (final m in _tokenRe.allMatches(raw)) {
      final tok = m[0]!;
      if (tok.trim().isEmpty) {
        logical.add(pw.SizedBox(width: size * 0.3));
      } else if (_mirror.containsKey(tok)) {
        logical.add(pw.Text(_mirror[tok]!, style: style));
      } else if (RegExp(r'^[A-Za-z0-9]').hasMatch(tok)) {
        logical.add(
          pw.Text(tok, style: style, textDirection: pw.TextDirection.ltr),
        );
      } else {
        logical.add(
          pw.Text(
            PdfGenerator.formatUrdu(tok),
            style: style,
            textDirection: pw.TextDirection.rtl,
          ),
        );
      }
    }
    if (logical.isEmpty) return pw.SizedBox();

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: logical.reversed.toList(),
    );
  }

  /// Plain LTR text (numbers, phone) in the vector bold font.
  pw.Widget number(String t, {required double size, required PdfColor color}) {
    return pw.Text(
      t,
      style: pw.TextStyle(font: vectorBold, fontSize: size, color: color),
    );
  }
}

// =============================================================================
// Page builder
// =============================================================================

class _RateListBuilder {
  _RateListBuilder({
    required this.products,
    required this.engine,
    required this.theme,
  });

  final List<ProductModel> products;
  final _TextEngine engine;
  final pw.ThemeData theme;

  List<pw.Page> buildPages() {
    // Group by company (keeps original order inside each company).
    final grouped = <String, List<ProductModel>>{};
    for (final p in products) {
      grouped.putIfAbsent(p.company, () => <ProductModel>[]).add(p);
    }
    final companies = grouped.keys.toList()..sort();

    final columns = _splitIntoColumns(grouped, companies);
    final totalPages = columns.isEmpty ? 1 : (columns.length / 2).ceil();
    final dateText = _formatDate(DateTime.now());

    final pages = <pw.Page>[];
    for (int page = 0; page < totalPages; page++) {
      // Column 2n -> RIGHT table (filled first); 2n+1 -> LEFT (second).
      final right =
      (page * 2) < columns.length ? columns[page * 2] : <PdfRowEntry>[];
      final left = (page * 2 + 1) < columns.length
          ? columns[page * 2 + 1]
          : <PdfRowEntry>[];

      // IMPORTANT: build the widget tree eagerly, NOT inside pw.Page.build.
      // pw.Page.build only runs later, during pdf.save(), so the recording
      // pass would never see any text and nothing would get rasterized.
      final content = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _banner(),
          pw.SizedBox(height: 3),
          pw.Container(height: 2.5, color: _Palette.gold),
          _infoStrip(page + 1, totalPages, dateText),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _tableOrSpace(left), // LEFT (second)
              pw.SizedBox(width: _colGap),
              _tableOrSpace(right), // RIGHT (first)
            ],
          ),
          pw.Spacer(),
          _footer(products.length),
        ],
      );

      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _marginH,
            _marginTop,
            _marginH,
            _marginBottom,
          ),
          theme: theme,
          build: (pw.Context context) => content,
        ),
      );
    }
    return pages;
  }

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  /// - A company banner is never left alone at the bottom of a column.
  /// - If a company continues in the next column/page, the banner repeats
  ///   with "(جاری)".
  List<List<PdfRowEntry>> _splitIntoColumns(
      Map<String, List<ProductModel>> grouped,
      List<String> companies,
      ) {
    final columns = <List<PdfRowEntry>>[];
    var itemNo = 1;

    for (final company in companies) {
      final items = grouped[company]!;
      var i = 0;
      var continued = false;

      while (i < items.length) {
        if (columns.isEmpty || _rowsPerColumn - columns.last.length < 2) {
          columns.add(<PdfRowEntry>[]);
        }
        final col = columns.last;
        col.add(CompanyHeaderEntry(company, continued: continued));
        while (i < items.length && col.length < _rowsPerColumn) {
          col.add(ProductItemEntry(items[i], itemNo++));
          i++;
        }
        continued = true;
      }
    }
    return columns;
  }

  // ---------------------------------------------------------------------------
  // Page furniture
  // ---------------------------------------------------------------------------

  pw.Widget _banner() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _Palette.navy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          engine.text(
            AppStrings.appTitle,
            size: 21,
            color: PdfColors.white,
            bold: true,
          ),
          engine.text(
            AppStrings.storeAddress,
            size: 10.5,
            color: _Palette.gold,
          ),
        ],
      ),
    );
  }

  pw.Widget _infoStrip(int page, int totalPages, String dateText) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Page badge (left)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            decoration: pw.BoxDecoration(
              color: _Palette.badgeBg,
              border: pw.Border.all(color: _Palette.navy, width: 1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: engine.text(
              'صفحہ $page از $totalPages',
              size: 10,
              color: _Palette.navy,
              bold: true,
            ),
          ),

          // Date (center)
          engine.text('تاریخ: $dateText', size: 10, color: _Palette.muted),

          // Proprietor + phone (right)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              engine.number(
                AppStrings.phoneNumber,
                size: 10,
                color: _Palette.navy,
              ),
              pw.SizedBox(width: 8),
              engine.text(
                AppStrings.proprietorName,
                size: 11,
                color: _Palette.text,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(int totalItems) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 0.8, color: _Palette.line),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            engine.text(
              'کل آئٹمز: $totalItems',
              size: 9,
              color: _Palette.muted,
            ),
            // Edit or remove this note as you like.
            engine.text(
              'ریٹ بغیر اطلاع تبدیل ہو سکتے ہیں',
              size: 9,
              color: _Palette.muted,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Table
  // ---------------------------------------------------------------------------

  pw.Widget _tableOrSpace(List<PdfRowEntry> entries) {
    if (entries.isEmpty) return pw.SizedBox(width: _tableWidth);
    return _table(entries);
  }

  pw.Widget _table(List<PdfRowEntry> entries) {
    final rows = <pw.Widget>[_headerRow()];
    var shaded = false;

    for (final entry in entries) {
      if (entry is CompanyHeaderEntry) {
        rows.add(_companyRow(entry));
        shaded = false; // restart zebra after each banner
      } else if (entry is ProductItemEntry) {
        rows.add(_productRow(entry, shaded: shaded));
        shaded = !shaded;
      }
    }

    return pw.SizedBox(
      width: _tableWidth,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  /// Visual order (left -> right): گاہک | تھوک | خرید | آئٹم | نمبر شمار
  pw.Widget _headerRow() {
    pw.Widget h(String label, double w, {bool divider = true}) => _cell(
      width: w,
      height: _headH,
      divider: divider ? _Palette.navySoft : null,
      child: engine.text(
        label,
        size: 9.5,
        color: PdfColors.white,
        bold: true,
      ),
    );

    return pw.Container(
      width: _tableWidth,
      height: _headH,
      color: _Palette.navy,
      child: pw.Row(
        children: [
          h('گاہک', _rateW, divider: false),
          h('تھوک', _rateW),
          h('خرید', _rateW),
          h('آئٹم', _nameW),
          h('نمبر شمار', _noW),
        ],
      ),
    );
  }

  /// Full-width company band with a gold accent bar on the right edge.
  pw.Widget _companyRow(CompanyHeaderEntry entry) {
    final label = entry.continued
        ? 'کمپنی: ${entry.companyName} (جاری)'
        : 'کمپنی: ${entry.companyName}';
    const side = pw.BorderSide(color: _Palette.line, width: 0.6);

    return pw.Container(
      width: _tableWidth,
      height: _rowH,
      decoration: const pw.BoxDecoration(
        color: _Palette.band,
        border: pw.Border(left: side, right: side, bottom: side),
      ),
      child: pw.Row(
        children: [
          _cell(
            width: _tableWidth - 4,
            height: _rowH,
            child: engine.text(
              label,
              size: 10,
              color: _Palette.navy,
              bold: true,
            ),
          ),
          pw.Container(width: 4, height: _rowH, color: _Palette.gold),
        ],
      ),
    );
  }

  pw.Widget _productRow(ProductItemEntry entry, {required bool shaded}) {
    final p = entry.product;
    const side = pw.BorderSide(color: _Palette.line, width: 0.6);

    pw.Widget rate(
        num value, {
          PdfColor color = _Palette.text,
          bool first = false,
        }) =>
        _cell(
          width: _rateW,
          height: _rowH,
          divider: first ? null : _Palette.line,
          child: value > 0
              ? engine.number(_money(value), size: 9, color: color)
              : null,
        );

    return pw.Container(
      width: _tableWidth,
      height: _rowH,
      decoration: pw.BoxDecoration(
        color: shaded ? _Palette.zebra : PdfColors.white,
        border: const pw.Border(left: side, right: side, bottom: side),
      ),
      child: pw.Row(
        children: [
          rate(p.customerRate, color: _Palette.navy, first: true),
          rate(p.wholesaleRate),
          rate(p.purchaseRate),
          _cell(
            width: _nameW,
            height: _rowH,
            alignment: pw.Alignment.centerRight,
            divider: _Palette.line,
            child: engine.text(p.name, size: 9.5, color: _Palette.text),
          ),
          _cell(
            width: _noW,
            height: _rowH,
            divider: _Palette.line,
            child: engine.number(
              '${entry.itemNumber}',
              size: 8.5,
              color: _Palette.muted,
            ),
          ),
        ],
      ),
    );
  }

  /// One fixed-size cell. The child is wrapped in a scaleDown FittedBox so a
  /// long name shrinks slightly instead of overflowing.
  pw.Widget _cell({
    required double width,
    required double height,
    pw.Widget? child,
    pw.Alignment alignment = pw.Alignment.center,
    PdfColor? divider,
  }) {
    return pw.Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      decoration: divider == null
          ? null
          : pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: divider, width: 0.5),
        ),
      ),
      child: child == null
          ? null
          : pw.FittedBox(fit: pw.BoxFit.scaleDown, child: child),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// 22500 -> "22,500"
  static String _money(num v) {
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}