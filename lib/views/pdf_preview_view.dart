import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../exports.dart';

// PDF rate list preview view
class PdfPreviewView extends StatefulWidget {
  final List<ProductModel>? products;
  final bool? includePurchaseRate;

  const PdfPreviewView({
    super.key,
    this.products,
    this.includePurchaseRate,
  });

  static Future<bool?> showOptionsDialog(BuildContext context) async {
    return await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primaryTeal,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.selectPdfOptionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.selectPdfOptionPrompt,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(result: true),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white,
                  ),
                  label: Text(
                    AppStrings.withPurchaseRate,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(result: false),
                  icon: const Icon(
                    Icons.block_outlined,
                    color: AppColors.primaryTeal,
                  ),
                  label: Text(
                    AppStrings.withoutPurchaseRate,
                    style: const TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PdfPreviewView> createState() => _PdfPreviewViewState();
}

class _PdfPreviewViewState extends State<PdfPreviewView> {
  late final RxBool _includePurchaseRate;

  @override
  void initState() {
    super.initState();
    _includePurchaseRate = (widget.includePurchaseRate ?? true).obs;

    if (widget.includePurchaseRate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final chosen = await PdfPreviewView.showOptionsDialog(context);
        if (chosen != null) {
          _includePurchaseRate.value = chosen;
        }
      });
    }
  }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.white),
              tooltip: AppStrings.selectPdfOptionTitle,
              onPressed: () async {
                final chosen = await PdfPreviewView.showOptionsDialog(context);
                if (chosen != null) {
                  _includePurchaseRate.value = chosen;
                }
              },
            ),
          ],
        ),
        body: Obx(() {
          final productsList = widget.products ?? controller.products;

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

          final includePurchase = _includePurchaseRate.value;

          return PdfPreview(
            key: ValueKey('pdf_preview_$includePurchase'),
            build: (format) => PdfGenerator.generateRateListPdf(
              productsList,
              pageFormat: format,
              includePurchaseRate: includePurchase,
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
