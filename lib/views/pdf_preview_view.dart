import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../exports.dart';

// PDF rate list preview view
class PdfPreviewView extends StatelessWidget {
  final List<ProductModel>? products;

  const PdfPreviewView({
    super.key,
    this.products,
  });

  @override
  Widget build(BuildContext context) {
    final InventoryController controller = Get.find<InventoryController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
          title: Text(
            AppStrings.rateListTitle,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: Obx(() {
          final productsList = products ?? controller.products;

          if (productsList.isEmpty) {
            return const Center(
              child: Text(
                AppStrings.noItemsFound,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return PdfPreview(
            build: (format) => PdfGenerator.generateRateListPdf(
              productsList,
              pageFormat: format,
            ),
            useActions: true,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            initialPageFormat: PdfPageFormat.a4,
            pageFormats: const {'A4': PdfPageFormat.a4},
            canChangePageFormat: false,
            canChangeOrientation: false,
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
            onError: (context, error) {
              return const Center(
                child: Text(
                  AppStrings.pdfErrorText,
                  style: TextStyle(
                    color: AppColors.deleteRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
