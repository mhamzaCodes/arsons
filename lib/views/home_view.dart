import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../utils/responsive.dart';
import 'add_edit_product_view.dart';
import 'company_list_view.dart';
import 'pdf_preview_view.dart';

/// Main Dashboard View with Category Tabs, Search, and Scaled Desktop Text
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final InventoryController controller = Get.put(InventoryController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.defaultCategories.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final category = AppConstants.defaultCategories[_tabController.index];
        controller.selectCategory(category);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
          toolbarHeight: isMobile ? 85 : 75,
          title: ResponsiveCenteredBody(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appTitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppStrings.proprietorLabel} ${AppStrings.proprietorName}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppColors.primaryTealDark),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.phoneNumber,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
                tooltip: AppStrings.quickPdfDownload,
                onPressed: () => Get.to(() => const PdfPreviewView()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search & Quick Action Header
            Container(
              color: AppColors.primaryTeal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    suffixIcon: controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => controller.updateSearchQuery(''),
                          )
                        : null,
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

            // Statistics Bar
            _buildStatsHeader(context, controller),

            // Category Tabs
            Container(
              color: Colors.white,
              child: ResponsiveCenteredBody(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryTeal,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryTeal,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                  ),
                  tabs: AppConstants.defaultCategories
                      .map((cat) => Tab(text: cat))
                      .toList(),
                ),
              ),
            ),

            // Companies Chips Bar
            _buildCompanyFilterChips(context, controller),

            // Main Product Display (Responsive Grid for Desktop / List for Mobile)
            Expanded(
              child: ResponsiveCenteredBody(
                padding: const EdgeInsets.all(12),
                child: Obx(() {
                  final items = controller.filteredProducts;

                  if (items.isEmpty) {
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
                                    initialCategory: controller.selectedCategory.value,
                                    initialCompany: controller.selectedCompany.value,
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
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildProductListItem(context, item, controller);
                      },
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisExtent: 235,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildProductListItem(context, item, controller);
                      },
                    );
                  }
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 8,
          child: ResponsiveCenteredBody(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => AddEditProductView(
                            initialCategory: controller.selectedCategory.value,
                            initialCompany: controller.selectedCompany.value,
                          ));
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: Text(
                      AppStrings.addNewItem,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => CompanyListView(
                          categoryName: controller.selectedCategory.value,
                        ));
                  },
                  icon: const Icon(Icons.business, color: AppColors.primaryTeal),
                  label: Text(
                    AppStrings.companiesTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildStatsHeader(BuildContext context, InventoryController controller) {
    return Container(
      color: AppColors.surfaceLight,
      child: ResponsiveCenteredBody(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Obx(() {
          final totalCount = controller.products.length;
          final categoryCount = controller.filteredProducts.length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory, size: 18, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.totalProducts}: ',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$totalCount',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.filter_alt, size: 18, color: AppColors.secondaryTeal),
                  const SizedBox(width: 6),
                  Text(
                    'دستیاب آئٹمز: ',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$categoryCount',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCompanyFilterChips(BuildContext context, InventoryController controller) {
    return Container(
      color: Colors.white,
      child: ResponsiveCenteredBody(
        child: Obx(() {
          final currentCategory = controller.selectedCategory.value;
          final companies = controller.getCompaniesForCategory(currentCategory);

          return SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              children: [
                // All Companies Chip
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(
                      AppStrings.allCompanies,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                      ),
                    ),
                    selected: controller.selectedCompany.value.isEmpty,
                    selectedColor: AppColors.primaryTeal,
                    labelStyle: TextStyle(
                      color: controller.selectedCompany.value.isEmpty
                          ? Colors.white
                          : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => controller.clearCompanyFilter(),
                  ),
                ),
                ...companies.map((comp) {
                  final isSelected = controller.selectedCompany.value == comp;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(
                        comp,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.secondaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => controller.selectCompany(comp),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductListItem(
    BuildContext context,
    ProductModel item,
    InventoryController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
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
            const SizedBox(height: 4),

            // Category badge
            Text(
              'کیٹیگری: ${item.category}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 12),

            // Rates Display
            Row(
              children: [
                Expanded(
                  child: _buildMiniRateBox(
                    context,
                    title: 'خرید/دوکاندار',
                    amount: item.purchaseRate,
                    unit: item.unit,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniRateBox(
                    context,
                    title: 'تھوک ریٹ',
                    amount: item.wholesaleRate,
                    unit: item.unit,
                    color: AppColors.editBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniRateBox(
                    context,
                    title: 'گاہک ریٹ',
                    amount: item.customerRate,
                    unit: item.unit,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit, color: AppColors.editBlue, size: 20),
                  tooltip: AppStrings.editItem,
                  onPressed: () {
                    Get.to(() => AddEditProductView(productToEdit: item));
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete, color: AppColors.deleteRed, size: 20),
                  tooltip: AppStrings.deleteItem,
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, item, controller);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRateBox(
    BuildContext context, {
    required String title,
    required double amount,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
