import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../exports.dart';

// View displaying companies under a chosen category
class CompanyListView extends StatefulWidget {
  final String categoryName;

  const CompanyListView({
    super.key,
    required this.categoryName,
  });

  @override
  State<CompanyListView> createState() => _CompanyListViewState();
}

class _CompanyListViewState extends State<CompanyListView> {
  late String _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.categoryName;
  }

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
            '$_currentCategory (${AppStrings.companiesTitle})',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              onPressed: () {
                Get.to(() => AddEditProductView(initialCategory: _currentCategory));
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.white),
              onSelected: (value) {
                if (value == 'delete_all_category') {
                  _showDeleteAllCategoryConfirmationDialog(context, controller);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_all_category',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: AppColors.deleteRed),
                      SizedBox(width: 8),
                      Text(
                        AppStrings.deleteAllItems,
                        style: TextStyle(color: AppColors.deleteRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ResponsiveCenteredBody(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildCategoryHorizontalBar(context, controller),
              Expanded(
                child: Obx(() {
                  final companies = controller.getCompaniesForCategory(_currentCategory);

                  if (companies.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.noCompaniesFound,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 16, desktopSize: 20),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => AddEditProductView(
                                    initialCategory: _currentCategory,
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
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isMobile) {
                    return ListView.builder(
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return _buildCompanyCard(context, company, controller);
                      },
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: 105,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return _buildCompanyCard(context, company, controller);
                      },
                    );
                  }
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => AddEditProductView(initialCategory: _currentCategory));
          },
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.white,
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

  Widget _buildCategoryHorizontalBar(
      BuildContext context, InventoryController controller) {
    return Obx(() {
      final categories = controller.categories;
      if (categories.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final bool isSelected = cat == _currentCategory;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.white : AppColors.textDark,
                  ),
                ),
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: isSelected ? AppColors.white : AppColors.textDark,
                selectedColor: AppColors.primaryTeal,
                backgroundColor: AppColors.white,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primaryTeal : AppColors.borderGrey,
                ),
                shape: const StadiumBorder(),
                onSelected: (_) {
                  setState(() {
                    _currentCategory = cat;
                  });
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildCompanyCard(
    BuildContext context,
    String company,
    InventoryController controller,
  ) {
    final itemCount = controller.getCompanyCount(_currentCategory, company);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business,
            color: AppColors.primaryTeal,
          ),
        ),
        title: Text(
          company,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 18, desktopSize: 21),
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${AppStrings.itemsCountPrefix}$itemCount',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: AppColors.primaryTeal,
        ),
        onTap: () {
          Get.to(() => ProductListView(
                categoryName: _currentCategory,
                companyName: company,
              ));
        },
      ),
    );
  }

  void _showDeleteAllCategoryConfirmationDialog(
    BuildContext context,
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
            AppStrings.deleteAllCategoryConfirmTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
              color: AppColors.deleteRed,
            ),
          ),
          content: Text(
            AppStrings.deleteAllCategoryMessage(_currentCategory),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
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
                controller.deleteAllItemsForCategory(_currentCategory);
                Get.back();
                Get.snackbar(
                  AppStrings.deletedTitle,
                  AppStrings.deleteAllSuccessMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.deleteRed,
                  colorText: AppColors.white,
                  margin: const EdgeInsets.all(12),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed,
                foregroundColor: AppColors.white,
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
