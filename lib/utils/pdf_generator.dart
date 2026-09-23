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

/// Rate-list PDF: always A4, two side-by-side tables per page.
/// Fill order (RTL): RIGHT table first, then LEFT table, then next page.
class PdfGenerator {
  static final _reshaper = ArabicReshaper();

  // ---- Layout constants (A4 = 595.28 x 841.89 pt) -------------------------
  // Everything is fixed-width on purpose: no Expanded/Flex + Table, which is
  // what triggered "childSize <= maxChildExtent".
  static const double _marginH = 18;
  static const double _marginTop = 18;
  static const double _marginBottom = 16;
  static const double _colGap = 12;

  // 2 * 273 + 12 = 558  <=  595.28 - 36 = 559.28
  static const double _tableWidth = 273;
  static const double _rateW = 42;
  static const double _noW = 32;
  static const double _nameW = _tableWidth - (_rateW * 3) - _noW; // 115

  static const double _rowH = 20;
  static const double _headH = 24;

  /// Rows (company banners + items) per column. 30 * 2 = 60 rows per page.
  /// Lower this if you enlarge fonts / row height.
  static const int _rowsPerColumn = 30;

  /// Reshapes Urdu text so characters connect properly in PDF
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
  /// [pageFormat] is accepted only for backward compatibility and is IGNORED:
  /// PdfPreview / Printing.layoutPdf pass their own format (e.g. Letter with
  /// 72pt margins) which is what broke the layout. We always render A4.
  static Future<Uint8List> generateRateListPdf(
      List<ProductModel> products, {
        PdfPageFormat? pageFormat,
      }) async {
    final pdf = pw.Document();

    // ---- Fonts -------------------------------------------------------------
    pw.Font urduFontRegular;
    pw.Font urduFontBold;
    try {
      urduFontRegular = await PdfGoogleFonts.notoNaskhArabicRegular();
      urduFontBold = await PdfGoogleFonts.notoNaskhArabicBold();
    } catch (_) {
      final fontData =
      await rootBundle.load('assets/fonts/JameelNooriNastaleeq.ttf');
      urduFontRegular = pw.Font.ttf(fontData);
      urduFontBold = urduFontRegular;
    }

    // ---- Group by company (keeps original order inside each company) -------
    final grouped = <String, List<ProductModel>>{};
    for (final p in products) {
      grouped.putIfAbsent(p.company, () => <ProductModel>[]).add(p);
    }
    final companies = grouped.keys.toList()..sort();

    // ---- Split into columns, then pair columns into pages ------------------
    final columns = _splitIntoColumns(grouped, companies);
    final totalPages = columns.isEmpty ? 1 : (columns.length / 2).ceil();
    final dateText = _formatDate(DateTime.now());

    for (int page = 0; page < totalPages; page++) {
      // Column 2n   -> RIGHT table (filled first)
      // Column 2n+1 -> LEFT table  (filled second)
      final rightEntries =
      (page * 2) < columns.length ? columns[page * 2] : <PdfRowEntry>[];
      final leftEntries = (page * 2 + 1) < columns.length
          ? columns[page * 2 + 1]
          : <PdfRowEntry>[];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            _marginH,
            _marginTop,
            _marginH,
            _marginBottom,
          ),
          theme: pw.ThemeData.withFont(
            base: urduFontRegular,
            bold: urduFontBold,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildBanner(urduFontBold),
                pw.SizedBox(height: 3),
                pw.Container(height: 2.5, color: _Palette.gold),
                _buildInfoStrip(
                  font: urduFontBold,
                  page: page + 1,
                  totalPages: totalPages,
                  dateText: dateText,
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // LEFT table (second)
                    _buildTableOrSpace(
                      leftEntries,
                      urduFontBold,
                      urduFontRegular,
                    ),
                    pw.SizedBox(width: _colGap),
                    // RIGHT table (first)
                    _buildTableOrSpace(
                      rightEntries,
                      urduFontBold,
                      urduFontRegular,
                    ),
                  ],
                ),
                pw.Spacer(),
                _buildFooter(urduFontRegular, products.length),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // ===========================================================================
  // Pagination
  // ===========================================================================

  /// Flows companies/items into columns of [_rowsPerColumn] rows.
  /// - A company banner is never left alone at the bottom of a column.
  /// - If a company continues in the next column/page, its banner is repeated
  ///   with "(جاری)" so every column is self-explanatory.
  static List<List<PdfRowEntry>> _splitIntoColumns(
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
        // Need room for the banner + at least one item.
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

  // ===========================================================================
  // Page furniture
  // ===========================================================================

  static pw.Widget _buildBanner(pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _Palette.navy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            formatUrdu(AppStrings.appTitle),
            style: pw.TextStyle(
              font: bold,
              fontSize: 20,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            formatUrdu(AppStrings.storeAddress),
            style: pw.TextStyle(
              font: bold,
              fontSize: 10,
              color: _Palette.gold,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoStrip({
    required pw.Font font,
    required int page,
    required int totalPages,
    required String dateText,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Page badge (left)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _Palette.badgeBg,
              border: pw.Border.all(color: _Palette.navy, width: 1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              '${formatUrdu('صفحہ')} $page ${formatUrdu('از')} $totalPages',
              style: pw.TextStyle(
                font: font,
                fontSize: 9.5,
                color: _Palette.navy,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),

          // Date (center)
          pw.Text(
            '${formatUrdu('تاریخ')}: $dateText',
            style: pw.TextStyle(
              font: font,
              fontSize: 9.5,
              color: _Palette.muted,
            ),
            textDirection: pw.TextDirection.rtl,
          ),

          // Proprietor + phone (right)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                AppStrings.phoneNumber,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: _Palette.navy,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                formatUrdu(AppStrings.proprietorName),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10.5,
                  color: _Palette.text,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font, int totalItems) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 0.8, color: _Palette.line),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${formatUrdu('کل آئٹمز')}: $totalItems',
              style: pw.TextStyle(
                font: font,
                fontSize: 8.5,
                color: _Palette.muted,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            // Edit or remove this note as you like.
            pw.Text(
              formatUrdu('ریٹ بغیر اطلاع تبدیل ہو سکتے ہیں'),
              style: pw.TextStyle(
                font: font,
                fontSize: 8.5,
                color: _Palette.muted,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Table
  // ===========================================================================

  static pw.Widget _buildTableOrSpace(
      List<PdfRowEntry> entries,
      pw.Font bold,
      pw.Font regular,
      ) {
    if (entries.isEmpty) return pw.SizedBox(width: _tableWidth);
    return _buildTable(entries, bold, regular);
  }

  static pw.Widget _buildTable(
      List<PdfRowEntry> entries,
      pw.Font bold,
      pw.Font regular,
      ) {
    final rows = <pw.Widget>[_buildHeaderRow(bold)];
    var shaded = false;

    for (final entry in entries) {
      if (entry is CompanyHeaderEntry) {
        rows.add(_buildCompanyRow(entry, bold));
        shaded = false; // restart zebra after each banner
      } else if (entry is ProductItemEntry) {
        rows.add(_buildProductRow(entry, bold, regular, shaded: shaded));
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
  static pw.Widget _buildHeaderRow(pw.Font bold) {
    pw.Widget h(String label, double w, {bool divider = true}) => _cell(
      formatUrdu(label),
      width: w,
      height: _headH,
      font: bold,
      size: 9,
      color: PdfColors.white,
      divider: divider ? _Palette.navySoft : null,
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

  /// Full-width company band (no more squeezing the name into one cell).
  static pw.Widget _buildCompanyRow(CompanyHeaderEntry entry, pw.Font bold) {
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
            label, // raw: _mixedText reshapes Urdu tokens itself
            width: _tableWidth - 4,
            height: _rowH,
            font: bold,
            size: 9.5,
            color: _Palette.navy,
            mixed: true,
          ),
          // Gold accent bar on the right edge (RTL start)
          pw.Container(width: 4, height: _rowH, color: _Palette.gold),
        ],
      ),
    );
  }

  static pw.Widget _buildProductRow(
      ProductItemEntry entry,
      pw.Font bold,
      pw.Font regular, {
        required bool shaded,
      }) {
    final p = entry.product;
    const side = pw.BorderSide(color: _Palette.line, width: 0.6);

    pw.Widget rate(String v, {PdfColor color = _Palette.text, bool first = false}) =>
        _cell(
          v,
          width: _rateW,
          height: _rowH,
          font: bold,
          size: 9,
          color: color,
          divider: first ? null : _Palette.line,
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
          rate(_money(p.customerRate), color: _Palette.navy, first: true),
          rate(_money(p.wholesaleRate)),
          rate(_money(p.purchaseRate)),
          _cell(
            p.name, // raw: _mixedText reshapes Urdu tokens itself
            width: _nameW,
            height: _rowH,
            font: regular,
            size: 9,
            color: _Palette.text,
            alignment: pw.Alignment.centerRight,
            divider: _Palette.line,
            mixed: true,
          ),
          _cell(
            '${entry.itemNumber}',
            width: _noW,
            height: _rowH,
            font: bold,
            size: 8.5,
            color: _Palette.muted,
            divider: _Palette.line,
          ),
        ],
      ),
    );
  }

  /// One fixed-size cell. Text is wrapped in a scaleDown FittedBox, so a long
  /// product name shrinks slightly instead of overflowing or wrapping.
  static pw.Widget _cell(
      String text, {
        required double width,
        required double height,
        required pw.Font font,
        required double size,
        required PdfColor color,
        pw.Alignment alignment = pw.Alignment.center,
        PdfColor? divider,
        bool mixed = false, // true => pass RAW text (no formatUrdu), see _mixedText
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
      child: text.isEmpty
          ? null
          : pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        child: mixed
            ? _mixedText(text, font: font, size: size, color: color)
            : pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: size,
            color: color,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
    );
  }

  // ===========================================================================
  // Mixed Urdu + English/digits + brackets (e.g. "پائپ 3انچ PPR (10فٹ)")
  // ===========================================================================

  // Tokens, in this priority:
  //  1) Latin/digit chunk : PPR, 10, 500, 60x60, 1.5, 3/4
  //  2) bracket           : ( ) [ ]
  //  3) whitespace
  //  4) anything else     : Urdu/Arabic words and punctuation
  static final RegExp _tokenRe = RegExp(
    r'[A-Za-z0-9]+(?:[.\-/×][A-Za-z0-9]+)*'
    r'|[()\[\]]'
    r'|\s+'
    r'|[^\sA-Za-z0-9()\[\]]+',
  );

  static const Map<String, String> _mirror = {
    '(': ')',
    ')': '(',
    '[': ']',
    ']': '[',
  };

  /// Lays out a mixed-direction string ourselves instead of trusting the pdf
  /// package's bidi pass (which scrambles brackets / Latin words inside
  /// Urdu). Each token is drawn as its own single-direction Text, and the
  /// tokens are placed right-to-left. Brackets are mirrored manually, so
  /// "(10فٹ)" stays one properly enclosed group like in the app.
  static pw.Widget _mixedText(
      String raw, {
        required pw.Font font,
        required double size,
        required PdfColor color,
      }) {
    final style = pw.TextStyle(font: font, fontSize: size, color: color);
    final logical = <pw.Widget>[];

    for (final m in _tokenRe.allMatches(raw.trim())) {
      final tok = m[0]!;

      if (tok.trim().isEmpty) {
        logical.add(pw.SizedBox(width: size * 0.3)); // word gap
      } else if (_mirror.containsKey(tok)) {
        logical.add(pw.Text(_mirror[tok]!, style: style));
      } else if (RegExp(r'^[A-Za-z0-9]').hasMatch(tok)) {
        logical.add(
          pw.Text(tok, style: style, textDirection: pw.TextDirection.ltr),
        );
      } else {
        logical.add(
          pw.Text(
            formatUrdu(tok),
            style: style,
            textDirection: pw.TextDirection.rtl,
          ),
        );
      }
    }

    if (logical.isEmpty) return pw.SizedBox();

    // Logical order is right-to-left, a Row draws left-to-right -> reverse.
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: logical.reversed.toList(),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// 22500 -> "22,500". Zero / negative -> empty cell.
  static String _money(num v) {
    if (v <= 0) return '';
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