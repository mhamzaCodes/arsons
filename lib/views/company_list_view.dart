import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../utils/responsive.dart';
import 'add_edit_product_view.dart';
import 'product_list_view.dart';

/// View displaying companies under a chosen Category with Scaled Desktop Text
class CompanyListView extends StatelessWidget {
  final String categoryName;

  const CompanyListView({
    super.key,
    required this.categoryName,
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
            '$categoryName (${AppStrings.companiesTitle})',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              onPressed: () {
                Get.to(() => AddEditProductView(initialCategory: categoryName));
              },
            ),
          ],
        ),
        body: ResponsiveCenteredBody(
          padding: const EdgeInsets.all(12),
          child: Obx(() {
            final companies = controller.getCompaniesForCategory(categoryName);

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
                              initialCategory: categoryName,
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => AddEditProductView(initialCategory: categoryName));
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

  Widget _buildCompanyCard(
    BuildContext context,
    String company,
    InventoryController controller,
  ) {
    final itemCount = controller.getCompanyCount(categoryName, company);

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
          'آئٹمز کی تعداد: $itemCount',
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
                categoryName: categoryName,
                companyName: company,
              ));
        },
      ),
    );
  }
}
