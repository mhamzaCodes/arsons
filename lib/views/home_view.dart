import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../utils/responsive.dart';
import 'add_edit_product_view.dart';
import 'company_list_view.dart';
import 'pdf_preview_view.dart';
import 'settings_view.dart';

/// Main Dashboard View with Dynamic Categories, Scaled Text & Data Backup/Restore
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with TickerProviderStateMixin {
  final InventoryController controller = Get.put(InventoryController());
  late TabController _tabController;
  bool _tabControllerInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _initTabController();

    // Listen for dynamic category list updates
    ever(controller.categories, (_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _initTabController();
            });
          }
        });
      }
    });
  }

  void _initTabController() {
    final catList = controller.categories;
    final int catLength = catList.isNotEmpty
        ? catList.length
        : (AppConstants.defaultCategories.isNotEmpty
            ? AppConstants.defaultCategories.length
            : 1);

    if (_tabControllerInitialized) {
      _tabController.dispose();
    }

    _tabController = TabController(
      length: catLength,
      vsync: this,
    );
    _tabControllerInitialized = true;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index < controller.categories.length) {
        final category = controller.categories[_tabController.index];
        controller.selectCategory(category);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(context, isMobile),
              _buildStatsHeader(context),
              _buildCategoryTabs(context),
              _buildCompanyFilterChips(context),
              const SizedBox(height: 4),
              Expanded(child: _buildProductsArea(context, isMobile)),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context),
        ),
      ),
    );
  }

  // ===========================================================================
  // Header (brand + phone + PDF + Backup & Search)
  // ===========================================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final phoneChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.goldAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_in_talk_rounded,
            size: 15,
            color: AppColors.primaryTealDark,
          ),
          const SizedBox(width: 6),
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
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryTealDark, AppColors.primaryTeal],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveCenteredBody(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize:
                                Responsive.fontSize(context, 18, desktopSize: 23),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${AppStrings.ceoLabel} ${AppStrings.ceoName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize:
                                    Responsive.fontSize(context, 12, desktopSize: 15),
                              ),
                            ),
                            SizedBox(width: 6.0,),
                            Text(
                              '|',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize:
                                Responsive.fontSize(context, 12, desktopSize: 15),
                              ),
                            ),
                            SizedBox(width: 6.0,),
                            Text(
                              '${AppStrings.proprietorLabel} ${AppStrings.proprietorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize:
                                Responsive.fontSize(context, 12, desktopSize: 15),
                              ),
                            ),
                          ],
                        ),
                        if (isMobile) ...[
                          const SizedBox(height: 6),
                          phoneChip,
                        ],
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    phoneChip,
                    const SizedBox(width: 10),
                    // _buildBackupButton(context),
                  ],
                  const SizedBox(width: 6),
                  _buildPdfButton(),
                  const SizedBox(width: 6),
                  _buildSettingsButton(context),
                ],
              ),
              const SizedBox(height: 14),
              _buildSearchField(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icon.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.storefront_rounded,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildBackupButton(BuildContext context) {
    return Tooltip(
      message: 'ڈیٹا بیک اپ اور ریسٹور (Backup & Restore)',
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showBackupRestoreDialog(context),
          child: const Padding(
            padding: EdgeInsets.all(11),
            child: Icon(
              Icons.cloud_sync_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfButton() {
    return Tooltip(
      message: AppStrings.quickPdfDownload,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => const PdfPreviewView()),
          child: const Padding(
            padding: EdgeInsets.all(11),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Tooltip(
      message: AppStrings.settingsTitle,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => const SettingsView()),
          child: const Padding(
            padding: EdgeInsets.all(11),
            child: Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
        ),
        onChanged: (val) {
          controller.updateSearchQuery(val);
          setState(() {}); // refresh clear button
        },
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryTeal,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    controller.updateSearchQuery('');
                    setState(() {});
                  },
                )
              : null,
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Stats
  // ===========================================================================

  Widget _buildStatsHeader(BuildContext context) {
    return ResponsiveCenteredBody(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Obx(() {
        final totalCount = controller.products.length;
        final categoryCount = controller.filteredProducts.length;

        return Row(
          children: [
            Expanded(
              child: _statTile(
                context,
                icon: Icons.inventory_2_rounded,
                label: AppStrings.totalProducts,
                value: totalCount,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                context,
                icon: Icons.filter_alt_rounded,
                label: 'دستیاب آئٹمز',
                value: categoryCount,
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 20, desktopSize: 25),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Category tabs (Dynamic Rx List) + company chips
  // ===========================================================================

  Widget _buildCategoryTabs(BuildContext context) {
    return ResponsiveCenteredBody(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final catList = controller.categories;
          if (catList.isEmpty) return const SizedBox.shrink();

          return TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            indicator: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            splashBorderRadius: BorderRadius.circular(22),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
            ),
            tabs: catList
                .map((cat) => Tab(height: 42, text: cat))
                .toList(),
          );
        }),
      ),
    );
  }

  Widget _buildCompanyFilterChips(BuildContext context) {
    return ResponsiveCenteredBody(
      child: Obx(() {
        final currentCategory = controller.selectedCategory.value;
        final companies = controller.getCompaniesForCategory(currentCategory);
        final selectedCompany = controller.selectedCompany.value;

        return SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            children: [
              _companyChip(
                context,
                label: AppStrings.allCompanies,
                selected: selectedCompany.isEmpty,
                selectedColor: AppColors.primaryTeal,
                onTap: controller.clearCompanyFilter,
              ),
              ...companies.map(
                (comp) => Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: _companyChip(
                    context,
                    label: comp,
                    selected: selectedCompany == comp,
                    selectedColor: AppColors.secondaryTeal,
                    onTap: () => controller.selectCompany(comp),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _companyChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: selectedColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? selectedColor : AppColors.borderGrey,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onSelected: (_) => onTap(),
    );
  }

  // ===========================================================================
  // Products area (list on mobile, adaptive grid on tablet/desktop)
  // ===========================================================================

  Widget _buildProductsArea(BuildContext context, bool isMobile) {
    return ResponsiveCenteredBody(
      padding: EdgeInsets.zero,
      child: Obx(() {
        final items = controller.filteredProducts;

        if (items.isEmpty) return _buildEmptyState(context);

        if (isMobile) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildProductCard(context, items[index]),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildProductCard(context, items[index]),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noItemsFound,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppStrings.addNewItem,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Product card
  // ===========================================================================

  Widget _buildProductCard(BuildContext context, ProductModel item) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      child: InkWell(
        onTap: () => Get.to(() => AddEditProductView(productToEdit: item)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + company badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:
                                Responsive.fontSize(context, 16, desktopSize: 19),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(
                                context,
                                12,
                                desktopSize: 15,
                              ),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0,),

                  // Category + actions
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'کیٹیگری: ${item.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:
                                Responsive.fontSize(context, 12, desktopSize: 15),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _iconAction(
                        icon: Icons.edit_rounded,
                        color: AppColors.editBlue,
                        tooltip: AppStrings.editItem,
                        onTap: () =>
                            Get.to(() => AddEditProductView(productToEdit: item)),
                      ),
                      const SizedBox(width: 6),
                      _iconAction(
                        icon: Icons.delete_rounded,
                        color: AppColors.deleteRed,
                        tooltip: AppStrings.deleteItem,
                        onTap: () => _showDeleteConfirmationDialog(context, item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rates (customer rate highlighted)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRateTile(
                          context,
                          title: 'خرید/دوکاندار',
                          amount: item.purchaseRate,
                          unit: item.unit,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildRateTile(
                          context,
                          title: 'تھوک ریٹ',
                          amount: item.wholesaleRate,
                          unit: item.unit,
                          color: AppColors.editBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildRateTile(
                          context,
                          title: 'گاہک ریٹ',
                          amount: item.customerRate,
                          unit: item.unit,
                          color: AppColors.successGreen,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Accent bar on start (right) edge
            const PositionedDirectional(
              top: 0,
              bottom: 0,
              start: 0,
              width: 5,
              child: ColoredBox(color: AppColors.primaryTeal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildRateTile(
    BuildContext context, {
    required String title,
    required double amount,
    required String unit,
    required Color color,
    bool filled = false,
  }) {
    final Color titleColor = filled ? Colors.white : color;
    final Color subColor = filled ? Colors.white70 : AppColors.textSecondary;

    Widget fit(Widget child) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: child,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? color : color.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          fit(
            Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 10, desktopSize: 13),
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          fit(
            Text(
              'Rs. ${_money.format(amount)}',
              maxLines: 1,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          fit(
            Text(
              '/ $unit',
              maxLines: 1,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 9, desktopSize: 12),
                color: subColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Bottom bar
  // ===========================================================================

  void _openAddProduct() {
    Get.to(
      () => AddEditProductView(
        initialCategory: controller.selectedCategory.value,
        initialCompany: controller.selectedCompany.value,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveCenteredBody(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openAddProduct,
                    icon: const Icon(Icons.add_circle_rounded),
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
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.to(
                      () => CompanyListView(
                        categoryName: controller.selectedCategory.value,
                      ),
                    );
                  },
                  icon: const Icon(Icons.business_rounded),
                  label: Text(
                    AppStrings.companiesTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 1.5,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  // ===========================================================================
  // Backup & Restore Dialog
  // ===========================================================================

  void _showBackupRestoreDialog(BuildContext context) {
    final TextEditingController pasteController = TextEditingController();

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              size: 36,
              color: AppColors.primaryTeal,
            ),
          ),
          title: Text(
            'ڈیٹا بیک اپ اور ریسٹور (Backup & Restore)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
              color: AppColors.primaryTealDark,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اپنے تمام ڈیٹا کی بیک اپ فائل محفوظ کریں یا دوسرے ڈیوائس سے بیک اپ فائل ریسٹور کریں۔',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Action 1: Export / Save Backup File
                ElevatedButton.icon(
                  onPressed: () async {
                    final jsonString = controller.generateBackupJson();
                    // Copy JSON text to clipboard
                    await Clipboard.setData(ClipboardData(text: jsonString));

                    // Save file via FilePicker
                    try {
                      final String? outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'بیک اپ فائل محفوظ کریں',
                        fileName:
                            'ar_sons_backup_${DateTime.now().millisecondsSinceEpoch}.json',
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );

                      if (outputFile != null) {
                        final file = File(outputFile);
                        await file.writeAsString(jsonString);
                      }
                    } catch (_) {}

                    Get.back();
                    Get.snackbar(
                      'بیک اپ کامیاب',
                      'ڈیٹا بیک اپ کلپ بورڈ اور فائل میں محفوظ کر دیا گیا ہے!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.primaryTeal,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(12),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    'ڈیٹا بیک اپ بنائیں (Export File)',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action 2: Import / Pick Backup File
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final content = await file.readAsString();
                        final success = controller.restoreFromBackupJson(content);

                        Get.back();
                        if (success) {
                          Get.snackbar(
                            'ریسٹور کامیاب',
                            'تمام ڈیٹا کامیابی سے ریسٹور ہو گیا ہے!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.successGreen,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(12),
                          );
                        } else {
                          Get.snackbar(
                            'خرابی',
                            'بیک اپ فائل پڑھنے میں ناکامی!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.deleteRed,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(12),
                          );
                        }
                        return;
                      }
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    'بیک اپ فائل منتخب کریں (Import File)',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                /*const Divider(),
                const SizedBox(height: 8),

                // Action 3: Paste Backup Code Input
                Text(
                  'یا کلپ بورڈ سے بیک اپ ٹیکسٹ پیسٹ کر کے ریسٹور کریں:',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pasteController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'بیک اپ کا JSON کوڈ یہاں پیسٹ کریں...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final text = pasteController.text.trim();
                    if (text.isNotEmpty) {
                      final success = controller.restoreFromBackupJson(text);
                      Get.back();
                      if (success) {
                        Get.snackbar(
                          'ریسٹور کامیاب',
                          'ڈیٹا کلپ بورڈ ٹیکسٹ سے کامیابی سے ریسٹور ہو گیا!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.successGreen,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(12),
                        );
                      } else {
                        Get.snackbar(
                          'خرابی',
                          'غیر موزوں بیک اپ کوڈ!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.deleteRed,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(12),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'ٹیکسٹ سے ریسٹور کریں (Restore from Text)',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),*/
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                AppStrings.close,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Delete dialog
  // ===========================================================================

  void _showDeleteConfirmationDialog(BuildContext context, ProductModel item) {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deleteRed.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 34,
              color: AppColors.deleteRed,
            ),
          ),
          title: Text(
            AppStrings.deleteConfirmTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
              color: AppColors.deleteRed,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.deleteConfirmMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
