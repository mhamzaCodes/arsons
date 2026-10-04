import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../exports.dart';

class OrderPdfPreviewView extends StatelessWidget {
  final OrderModel order;

  const OrderPdfPreviewView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${order.orderTitle.isNotEmpty ? order.orderTitle : "Order"}${AppStrings.orderPdfTitleSuffix}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppStrings.regeneratePdfButton,
              onPressed: () {
                Get.forceAppUpdate();
              },
            ),
          ],
        ),
        body: PdfPreview(
          build: (format) => OrderPdfGenerator.generateOrderPdf(order),
          allowPrinting: true,
          canDebug: false,
          allowSharing: true,
          canChangePageFormat: false,
          canChangeOrientation: false,
          pdfFileName:
              'Order_${order.orderTitle.replaceAll(' ', '_')}_${order.date.replaceAll('/', '-')}.pdf',
          previewPageMargin: const EdgeInsets.all(12),
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          ),
        ),
      ),
    );
  }
}
