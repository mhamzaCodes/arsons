import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../exports.dart';

class OrderPdfGenerator {
  static Future<Uint8List> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    // Replicate up to 20 rows (or more if items > 20)
    final itemsCount = order.items.length > 20 ? order.items.length : 20;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header Row (HA Traders Box + Mobile Number)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // HA Traders Grey Header Box
                  pw.Container(
                    width: 220,
                    height: 50,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: PdfColor.fromInt(0xFF757575), // Dark grey banner
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'HA ',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 32,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Traders',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 22,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side Mobile number
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4, right: 4),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'Mobile.  ',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 16,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          order.mobile.isNotEmpty ? order.mobile : '03004685524',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 18,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              // 2. Customer / Shop Name Grey Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: PdfColor.fromInt(0xFFBDBDBD), // Medium Grey Bar
                child: pw.Text(
                  order.customerName.isNotEmpty
                      ? order.customerName
                      : 'Asghar Hardware and sentry store Narang Mandi',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                    fontItalic: pw.Font.helveticaBoldOblique(),
                    color: PdfColors.black,
                  ),
                ),
              ),

              // 3. Subtitle / Tagline
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  order.subtitle.isNotEmpty
                      ? order.subtitle
                      : 'UPVC PPRC PIPES & FITTINGS',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: PdfColors.black,
                  ),
                ),
              ),

              // Divider Line
              pw.Container(height: 1.5, color: PdfColors.black),

              // 4. Date Row
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Date.   ',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 15,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      order.date.isNotEmpty ? order.date : '02/02/26',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 15,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider Line
              pw.Container(height: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 8),

              // 5. Order Title Row (ORDER. + Brand in Red)
              pw.Row(
                children: [
                  pw.Text(
                    'ORDER.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      order.orderTitle.isNotEmpty ? order.orderTitle : 'POLO clear',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 26,
                        color: PdfColor.fromInt(0xFFD32F2F), // Bright Red
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // 6. Order Table
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 1.0,
                  ),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(48),   // Sr#
                    1: pw.FlexColumnWidth(3.8),   // Size.
                    2: pw.FlexColumnWidth(2.6),   // Gram
                    3: pw.FlexColumnWidth(2.6),   // Pipes
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFCFD8DC), // Light grey header
                      ),
                      children: [
                        _buildCell('Sr#', fontBold, 14, align: pw.TextAlign.center),
                        _buildCell('Size.', fontBold, 14, align: pw.TextAlign.center),
                        _buildCell('Gram', fontBold, 14, align: pw.TextAlign.center),
                        _buildCell('Pipes', fontBold, 14, align: pw.TextAlign.center),
                      ],
                    ),

                    // Table Rows (Dynamic items padded up to 20 minimum)
                    for (int i = 0; i < itemsCount; i++) ...[
                      _buildOrderRow(
                        srNo: i + 1,
                        item: i < order.items.length ? order.items[i] : null,
                        fontBold: fontBold,
                        fontRegular: fontRegular,
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Grey Footer Strip
              pw.Container(
                height: 20,
                width: double.infinity,
                color: PdfColor.fromInt(0xFF9E9E9E),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildOrderRow({
    required int srNo,
    OrderItemModel? item,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final sizeText = item?.size ?? '';
    final gramText = item?.gram ?? '';
    final pipesText = item?.pipes ?? '';

    return pw.TableRow(
      children: [
        // Sr#
        _buildCell('$srNo', fontRegular, 11, align: pw.TextAlign.center),

        // Size.
        _buildCell(
          sizeText,
          fontBold,
          12,
          align: sizeText.length > 15 ? pw.TextAlign.left : pw.TextAlign.center,
        ),

        // Gram
        _buildCell(gramText, fontBold, 12, align: pw.TextAlign.center),

        // Pipes
        _buildCell(pipesText, fontBold, 12, align: pw.TextAlign.center),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text,
    pw.Font font,
    double fontSize, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      height: 21,
      alignment: align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
