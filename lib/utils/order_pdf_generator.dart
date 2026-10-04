import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../exports.dart';

class OrderPdfGenerator {
  static Future<Uint8List> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    // Try loading background image from assets
    pw.MemoryImage? bgImage;
    try {
      final imageBytes = await rootBundle.load('assets/pipes.png');
      bgImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
    } catch (_) {
      try {
        final imageBytes = await rootBundle.load('assets/pipes.png');
        bgImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
      } catch (_) {
        bgImage = null;
      }
    }

    // Default fallback values
    final mobileText = order.mobile.trim().isNotEmpty
        ? order.mobile.trim()
        : AppStrings.phoneNumber;
    final customerText = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()
        : AppStrings.defaultShopName;
    final subtitleText = AppStrings.defaultOrderSubtitle;
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
          return pw.Stack(
            children: [
              // Subtle background image watermark coming from bottom-right corner towards center
              if (bgImage != null)
                pw.Positioned(
                  right: 0,
                  bottom: 0,
                  child: pw.SizedBox(
                    width: 550,
                    height: 550,
                    child: pw.Opacity(
                      opacity: 0.10,
                      child: pw.Transform.rotate(
                        angle: -0.4, // Rotated from bottom-right towards center
                        child: pw.Image(
                          bgImage,
                          fit: pw.BoxFit.cover,
                          alignment: pw.Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),

              // Framed Border wrapping the page content
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFF005F73), // Primary Teal Frame
                    width: 2.0,
                  ),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Header Row (AR Sons + Owner on Left | Mobile at Right End)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Group: AR Sons Banner Box + Owner Tag beside it
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // AR Sons Primary Banner Box
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFF005F73), // Primary Teal
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(6),
                                ),
                              ),
                              child: pw.Text(
                                AppStrings.appName,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 24,
                                  color: PdfColors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),

                            pw.SizedBox(width: 12),

                            // Owner Tag Box (Increased font size)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFE2E8F0),
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              child: pw.Text(
                                '${AppStrings.ownerLabelEnglish}${AppStrings.ownerNameEnglish}',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 14, // Larger font size
                                  color: PdfColor.fromInt(0xFF005F73),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Right End: Mobile Number
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              AppStrings.mobilePrefix,
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 13,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.Text(
                              mobileText,
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 15,
                                color: PdfColor.fromInt(0xFF005F73),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 8),

                    // 2. Customer / Shop Name Grey Banner Bar
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF37474F), // Dark Slate
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        customerText,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // 3. Subtitle / Category Tagline (Hardcoded)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: pw.Text(
                        subtitleText,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 13,
                          letterSpacing: 1.2,
                          color: PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 4),

                    // 4. Date Row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            '${AppStrings.orderDateLabel}.   ',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            dateText,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    // 5. Order Title Row (ORDER. + Brand Name in Red)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          AppStrings.orderHeaderPrefix,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 15,
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
                              color: PdfColor.fromInt(0xFFD32F2F), // Red
                            ),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),

                    // 6. Compact & Neat Order Items Table
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColor.fromInt(0xFF005F73),
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
                            color: PdfColor.fromInt(0xFF005F73), // Primary Teal header
                          ),
                          children: [
                            _buildHeaderCell(AppStrings.srNoHeader, fontBold, 13),
                            _buildHeaderCell(AppStrings.sizeHeader, fontBold, 13),
                            _buildHeaderCell(AppStrings.gramHeader, fontBold, 13),
                            _buildHeaderCell(AppStrings.pipesHeader, fontBold, 13),
                          ],
                        ),

                        // Table Rows (Compact & Balanced Boxes)
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

                    pw.SizedBox(height: 10),

                    // Total Items Count Display
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFE2E8F0),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            '${AppStrings.totalItemsPrefix}${itemsList.length}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF005F73),
                            ),
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

                    // Bottom Teal Footer Strip inside frame
                    pw.Container(
                      height: 16,
                      width: double.infinity,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF005F73),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(
    String text,
    pw.Font font,
    double fontSize,
  ) {
    return pw.Container(
      height: 24,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: PdfColors.white,
        ),
      ),
    );
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
            : PdfColor.fromInt(0xFFF1F5F9), // Subtle zebra striping
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

        // Pipes Quantity
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
