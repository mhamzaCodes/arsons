import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as fl;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import '../constants/strings.dart';
import '../models/product_model.dart';

// =============================================================================
// Constants & Theme Palette
// =============================================================================

class _Palette {
  static const navy = PdfColor.fromInt(0xFF003846); // Brand Deep Teal
  static const navySoft = PdfColor.fromInt(0xFF005266);
  static const gold = PdfColor.fromInt(0xFFD4AF37); // Gold accent
  static const softWhite = PdfColor.fromInt(0xFFD5E6EA); // Secondary text on navy
  static const band = PdfColor.fromInt(0xFF1E293B); // Dark band for company
  static const text = PdfColor.fromInt(0xFF1E293B); // Dark text
  static const muted = PdfColor.fromInt(0xFF64748B); // Secondary text
  static const zebra = PdfColor.fromInt(0xFFF8FAFC); // Soft row tint
  static const line = PdfColor.fromInt(0xFFCBD5E1); // Subtle divider
  static const badgeBg = PdfColor.fromInt(0xFFF1F5F9); // Light badge background
}

const double _colGap = 12; // Gap between right & left columns
const double _marginH = 14;
const double _marginTop = 14;
const double _marginBottom = 14;

// Printable width inside margins: A4 width (595.28) - 2 * 14 = 567.28
// Two columns with a 12pt gap -> each column is (567.28 - 12) / 2 = 277.64
const double _tableWidth = 277.5;

// Column widths inside each table (total = 277.5):
// Visual order (left -> right): گاہک | تھوک | خرید | آئٹم | نمبر شمار
const double _noW = 24.0; // نمبر شمار
const double _nameW = 121.5; // آئٹم کا نام
const double _rateW = 44.0; // Each rate column (x3 = 132.0)

// -----------------------------------------------------------------------------
// Vertical budget (A4 height = 841.89pt). Every block has a FIXED height so the
// number of rows per column can be computed instead of guessed:
//
//   available  = 841.89 - 14 (top) - 14 (bottom)          = 813.89
//   header     = 88   (_headerH)
//   gold rules = 7.8  (_rulesH)  + 6 gap (_afterHeaderGap)
//   table head = 22   (_headH)
//   footer     = 24   (_footerH)
//   rows       = 32 * 20.5                                 = 656
//   ----------------------------------------------------------------
//   used       = 88 + 7.8 + 6 + 22 + 656 + 24              = 803.8   (10pt spare)
//
// If you change any header/footer/row height, re-check this sum. If pdf says
// "Widget won't fit into the page", reduce _rowsPerColumn by one.
// -----------------------------------------------------------------------------
const double _headerH = 88.0;
const double _rulesH = 7.8;
const double _afterHeaderGap = 6.0;
const double _headH = 22.0; // table header row
const double _footerH = 24.0;
const double _rowH = 20.5;

/// Rows (company banners + product rows) per column.
const int _rowsPerColumn = 32;

const String _nastaleeqAsset = 'assets/fonts/JameelNooriNastaleeq.ttf';
const String _defaultNastaleeqFamily = 'JameelNooriNastaleeq';

// =============================================================================
// Row Data Model
// =============================================================================

abstract class PdfRowEntry {}

class CompanyHeaderEntry extends PdfRowEntry {
  final String companyName;
  final bool continued;
  CompanyHeaderEntry(this.companyName, {this.continued = false});
}

class ProductItemEntry extends PdfRowEntry {
  final ProductModel product;
  final int itemNumber;
  ProductItemEntry(this.product, this.itemNumber);
}

// =============================================================================
// Main Utility Entry Point
// =============================================================================

class PdfGenerator {
  static final _reshaper = ArabicReshaper();

  /// Reshapes Urdu text so characters connect properly when rendered in vector font.
  static String formatUrdu(String input) {
    if (input.trim().isEmpty) return input;
    try {
      return _reshaper.reshape(input);
    } catch (_) {
      return input;
    }
  }

  /// Generates a printable PDF byte array for the store rate list.
  ///
  /// By default this uses **Nastaleeq raster text** (rendered via Flutter's
  /// native TextPainter into crisp high-dpi PNGs) so Urdu calligraphic ligatures
  /// render authentically with Jameel Noori Nastaliq. If the asset font cannot
  /// be loaded, it seamlessly falls back to Noto Naskh Arabic vector text.
  ///
  /// Set [useNastaleeq] to `false` if you explicitly want vector Naskh text.
  /// [nastaleeqFamily] must match the font-family declared in your app's
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
    // Group by company
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

      // Built eagerly (not inside pw.Page.build) so the recording pass sees it.
      final content = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(page + 1, totalPages, dateText),
          _goldRules(),
          pw.SizedBox(height: _afterHeaderGap),
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
  // Header: framed letterhead (fixed height => predictable page budget)
  //
  //  [ ریٹ لسٹ / تاریخ / صفحہ ]   [ Shop name ]   [ Proprietor / CEO / Phone ]
  //                                 ─── • ───
  //                                  Address
  // ---------------------------------------------------------------------------

  pw.Widget _header(int page, int totalPages, String dateText) {
    const double innerH = _headerH - 12; // 6pt padding top + bottom

    // LEFT: document title, date and page badge
    final left = pw.SizedBox(
      width: 130,
      height: innerH,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.centerLeft,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            engine.text('ریٹ لسٹ', size: 14, color: _Palette.gold, bold: true),
            pw.SizedBox(height: 1),
            engine.text(
              'تاریخ: $dateText',
              size: 9.5,
              color: _Palette.softWhite,
            ),
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 1),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _Palette.gold, width: 0.8),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: engine.text(
                'صفحہ $page از $totalPages',
                size: 9,
                color: PdfColors.white,
                bold: true,
              ),
            ),
          ],
        ),
      ),
    );

    // CENTER: shop name + ornament + address
    final center = pw.SizedBox(
      width: 254,
      height: innerH,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            engine.text(
              AppStrings.appTitle,
              size: 22,
              color: PdfColors.white,
              bold: true,
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 46, height: 0.8, color: _Palette.gold),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: const pw.BoxDecoration(
                    color: _Palette.gold,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Container(width: 46, height: 0.8, color: _Palette.gold),
              ],
            ),
            pw.SizedBox(height: 2),
            engine.text(
              AppStrings.storeAddress,
              size: 11,
              color: _Palette.gold,
            ),
          ],
        ),
      ),
    );

    // RIGHT: proprietor, CEO and phone pill
    final right = pw.SizedBox(
      width: 150,
      height: innerH,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.centerRight,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            engine.text(
              '${AppStrings.ceoLabel} ${AppStrings.ceoName}',
              size: 10,
              color: PdfColors.white,
              bold: true,
            ),
            engine.text(
              '${AppStrings.proprietorLabel} ${AppStrings.proprietorName}',
              size: 10,
              color: _Palette.softWhite,
            ),
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: pw.BoxDecoration(
                color: _Palette.gold,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: engine.number(
                AppStrings.phoneNumber,
                size: 10.5,
                color: _Palette.navy,
              ),
            ),
          ],
        ),
      ),
    );

    return pw.Container(
      height: _headerH,
      decoration: pw.BoxDecoration(
        color: _Palette.navy,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Stack(
        children: [
          // Thin gold inner frame
          pw.Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: pw.Container(
              margin: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _Palette.gold, width: 0.7),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [left, center, right],
            ),
          ),
        ],
      ),
    );
  }

  /// Double gold rule under the header. Total height = [_rulesH] (7.8pt).
  pw.Widget _goldRules() {
    return pw.SizedBox(
      height: _rulesH,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(height: 2.5, color: _Palette.gold),
          pw.SizedBox(height: 1.5),
          pw.Container(height: 0.8, color: _Palette.gold),
        ],
      ),
    );
  }

  pw.Widget _footer(int totalItems) {
    return pw.SizedBox(
      height: _footerH,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(height: 0.8, color: _Palette.line),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              engine.text(
                'کل آئٹمز: $totalItems',
                size: 8.5,
                color: _Palette.muted,
              ),
              engine.text(
                'ریٹ بغیر اطلاع تبدیل ہو سکتے ہیں',
                size: 8.5,
                color: _Palette.muted,
              ),
            ],
          ),
        ],
      ),
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
              color: PdfColors.white,
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

  static String _money(num v) {
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
  }

  static String _formatDate(DateTime d) {
    const urduMonths = [
      'جنوری', 'فروری', 'مارچ', 'اپریل',
      'مئی', 'جون', 'جولائی', 'اگست',
      'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
    ];

    final day = d.day;
    final monthName = urduMonths[d.month - 1];
    final year = d.year;

    return '$day $monthName $year';
  }
}