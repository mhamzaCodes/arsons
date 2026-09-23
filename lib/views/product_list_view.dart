import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../utils/responsive.dart';
import 'add_edit_product_view.dart';

/// Screen listing products for a specific company or category with Scaled Desktop Text
class ProductListView extends StatelessWidget {
  final String categoryName;
  final String? companyName;

  const ProductListView({
    super.key,
    required this.categoryName,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final InventoryController controller = Get.find<InventoryController>();
    final bool isMobile = Responsive.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
          title: Text(
            companyName != null && companyName!.isNotEmpty
                ? '$categoryName ($companyName)'
                : categoryName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: () {
                Get.to(() => AddEditProductView(
                      initialCategory: categoryName,
                      initialCompany: companyName,
                    ));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar Header
            Container(
              color: AppColors.primaryTeal,
              padding: const EdgeInsets.all(12),
              child: ResponsiveCenteredBody(
                child: TextField(
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                  ),
                  onChanged: (val) => controller.updateSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryTeal),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Product List Display
            Expanded(
              child: ResponsiveCenteredBody(
                padding: const EdgeInsets.all(12),
                child: Obx(() {
                  final allProducts = controller.products;
                  final query = controller.searchQuery.value.toLowerCase();

                  final products = allProducts.where((p) {
                    bool matchesCat = p.category == categoryName;
                    bool matchesComp = companyName == null ||
                        companyName!.isEmpty ||
                        p.company == companyName;
                    bool matchesSearch = query.isEmpty ||
                        p.name.toLowerCase().contains(query) ||
                        p.company.toLowerCase().contains(query);

                    return matchesCat && matchesComp && matchesSearch;
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.noItemsFound,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => AddEditProductView(
                                    initialCategory: categoryName,
                                    initialCompany: companyName,
                                  ));
                            },
                            icon: const Icon(Icons.add),
                            label: Text(
                              AppStrings.addNewItem,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isMobile) {
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final item = products[index];
                        return _buildProductCard(context, item, controller);
                      },
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisExtent: 230,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final item = products[index];
                        return _buildProductCard(context, item, controller);
                      },
                    );
                  }
                }),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => AddEditProductView(
                  initialCategory: categoryName,
                  initialCompany: companyName,
                ));
          },
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(
            AppStrings.addNewItem,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductModel item,
    InventoryController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Header with Title & Company Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.company,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Rates Grid
            Row(
              children: [
                Expanded(
                  child: _buildRateChip(
                    context,
                    label: AppStrings.purchaseRateLabel,
                    amount: item.purchaseRate,
                    unit: item.unit,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRateChip(
                    context,
                    label: AppStrings.wholesaleRateLabel,
                    amount: item.wholesaleRate,
                    unit: item.unit,
                    color: AppColors.editBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRateChip(
                    context,
                    label: AppStrings.customerRateLabel,
                    amount: item.customerRate,
                    unit: item.unit,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Edit & Delete Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => AddEditProductView(productToEdit: item));
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(
                    AppStrings.editItem,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.editBlue,
                    side: const BorderSide(color: AppColors.editBlue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, item, controller);
                  },
                  icon: const Icon(Icons.delete, size: 14),
                  label: Text(
                    AppStrings.deleteItem,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deleteRed,
                    side: const BorderSide(color: AppColors.deleteRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChip(
    BuildContext context, {
    required String label,
    required double amount,
    required String unit,
    required Color color,
  }) {
    String title = label.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 10, desktopSize: 13),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
          ),
          Text(
            '/ $unit',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 9, desktopSize: 12),
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ProductModel item,
    InventoryController controller,
  ) {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.deleteConfirmTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
              color: AppColors.deleteRed,
            ),
          ),
          content: Text(
            '${AppStrings.deleteConfirmMessage}\n\n"${item.name}"',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.deleteProduct(item.id);
                Get.back();
                Get.snackbar(
                  AppStrings.deleteItem,
                  AppStrings.itemDeletedSuccess,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.deleteRed,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(12),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppStrings.deleteItem,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
