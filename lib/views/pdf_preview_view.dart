import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../utils/pdf_generator.dart';

/// Screen displaying PDF Rate List preview with print & share support
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
          title: const Text(
            AppStrings.rateListTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Obx(() {
          // If specific products passed, use them; otherwise default to ALL products in storage
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
              return Center(
                child: Text(
                  'PDF تیار کرنے میں خرابی',
                  style: const TextStyle(
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
