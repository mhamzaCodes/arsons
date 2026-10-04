import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../exports.dart';

class OrderPdfGenerator {
  static Future<Uint8List> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    // Fallback default values
    final mobileText = order.mobile.trim().isNotEmpty
        ? order.mobile.trim()
        : AppStrings.defaultMobileNumber;
    final customerText = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()
        : AppStrings.defaultShopName;
    final subtitleText = order.subtitle.trim().isNotEmpty
        ? order.subtitle.trim()
        : AppStrings.defaultOrderSubtitle;
    final dateText = order.date.trim().isNotEmpty
        ? order.date.trim()
        : AppStrings.defaultOrderDate;
    final orderTitleText = order.orderTitle.trim().isNotEmpty
        ? order.orderTitle.trim()
        : AppStrings.defaultOrderTitle;

    final itemsList = order.items;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header Row (HA Traders Box + Mobile Number)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // HA Traders Dark Grey Banner Box
                  pw.Container(
                    width: 210,
                    height: 48,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: PdfColor.fromInt(0xFF525252), // Dark grey header box
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          AppStrings.haTradersPrefix,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 30,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          AppStrings.haTradersSuffix,
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
                    padding: const pw.EdgeInsets.only(top: 6, right: 4),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          AppStrings.mobilePrefix,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 15,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          mobileText,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 17,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              // 2. Customer / Shop Name Grey Banner Bar
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: PdfColor.fromInt(0xFFBDBDBD), // Medium Grey Bar
                child: pw.Text(
                  customerText,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 17,
                    fontItalic: pw.Font.helveticaBoldOblique(),
                    color: PdfColors.black,
                  ),
                ),
              ),

              // 3. Subtitle / Tagline
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: pw.Text(
                  subtitleText,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                    color: PdfColors.black,
                  ),
                ),
              ),

              // Solid Divider Line
              pw.Container(height: 1.5, color: PdfColors.black),

              // 4. Date Row
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${AppStrings.orderDateLabel}.   ',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 15,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      dateText,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 15,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Solid Divider Line
              pw.Container(height: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 8),

              // 5. Order Title Row (ORDER. + Brand in Red)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    AppStrings.orderHeaderPrefix,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      orderTitleText,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 26,
                        color: PdfColor.fromInt(0xFFD32F2F), // Vibrant Red
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // 6. Professional Order Items Table
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 1.0,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(42),   // Sr#
                  1: pw.FlexColumnWidth(4.0),   // Size.
                  2: pw.FlexColumnWidth(2.5),   // Gram
                  3: pw.FlexColumnWidth(2.5),   // Pipes
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFCFD8DC), // Soft slate blue-grey
                    ),
                    children: [
                      _buildCell(AppStrings.srNoHeader, fontBold, 13, align: pw.TextAlign.center),
                      _buildCell(AppStrings.sizeHeader, fontBold, 13, align: pw.TextAlign.center),
                      _buildCell(AppStrings.gramHeader, fontBold, 13, align: pw.TextAlign.center),
                      _buildCell(AppStrings.pipesHeader, fontBold, 13, align: pw.TextAlign.center),
                    ],
                  ),

                  // Table Rows (Only items that exist)
                  for (int i = 0; i < itemsList.length; i++) ...[
                    _buildOrderRow(
                      srNo: i + 1,
                      item: itemsList[i],
                      isEven: i % 2 == 0,
                      fontBold: fontBold,
                      fontRegular: fontRegular,
                    ),
                  ],
                ],
              ),

              pw.SizedBox(height: 8),

              // Total Items Count at the Bottom
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${AppStrings.totalItemsPrefix}${itemsList.length}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signature Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 160,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        AppStrings.authorizedSignature,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Bottom Grey Footer Strip
              pw.Container(
                height: 18,
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
    required OrderItemModel item,
    required bool isEven,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final sizeText = item.size;
    final gramText = item.gram;
    final pipesText = item.pipes;

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven
            ? PdfColors.white
            : PdfColor.fromInt(0xFFF8FAFC), // Zebra striping
      ),
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
      height: 22,
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
