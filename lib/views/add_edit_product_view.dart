import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../constants/strings.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../utils/responsive.dart';

/// Form View to Add or Edit Inventory Items with Category, Company & Unit Dropdowns
class AddEditProductView extends StatefulWidget {
  final ProductModel? productToEdit;
  final String? initialCategory;
  final String? initialCompany;

  const AddEditProductView({
    super.key,
    this.productToEdit,
    this.initialCategory,
    this.initialCompany,
  });

  @override
  State<AddEditProductView> createState() => _AddEditProductViewState();
}

class _AddEditProductViewState extends State<AddEditProductView> {
  final _formKey = GlobalKey<FormState>();
  final InventoryController _controller = Get.find<InventoryController>();

  late TextEditingController _nameController;
  late TextEditingController _purchaseRateController;
  late TextEditingController _wholesaleRateController;
  late TextEditingController _customerRateController;
  late TextEditingController _unitController;
  late TextEditingController _companyController;
  late TextEditingController _categoryController;

  String _selectedCategory = AppConstants.defaultCategories.first;
  bool _isCustomCategory = false;

  String _selectedCompany = '';
  bool _isCustomCompany = false;

  String _selectedUnit = AppStrings.defaultUnit;
  bool _isCustomUnit = false;

  static const String _customCategoryKey = '__custom_new_category__';
  static const String _customCompanyKey = '__custom_new_company__';
  static const String _customUnitKey = '__custom_new_unit__';

  @override
  void initState() {
    super.initState();

    final isEdit = widget.productToEdit != null;
    final item = widget.productToEdit;

    _nameController = TextEditingController(text: isEdit ? item!.name : '');
    _purchaseRateController = TextEditingController(
        text: isEdit ? item!.purchaseRate.toStringAsFixed(0) : '');
    _wholesaleRateController = TextEditingController(
        text: isEdit ? item!.wholesaleRate.toStringAsFixed(0) : '');
    _customerRateController = TextEditingController(
        text: isEdit ? item!.customerRate.toStringAsFixed(0) : '');

    final initialUnitVal = isEdit ? item!.unit : AppStrings.defaultUnit;
    _selectedUnit = initialUnitVal;
    _unitController = TextEditingController(text: initialUnitVal);

    if (isEdit) {
      _selectedCategory = item!.category;
      _selectedCompany = item.company;
    } else {
      if (widget.initialCategory != null &&
          widget.initialCategory!.isNotEmpty) {
        _selectedCategory = widget.initialCategory!;
      }

      final categoryCompanies =
          _controller.getCompaniesForCategory(_selectedCategory);

      if (widget.initialCompany != null &&
          widget.initialCompany!.isNotEmpty) {
        _selectedCompany = widget.initialCompany!;
      } else if (categoryCompanies.isNotEmpty) {
        _selectedCompany = categoryCompanies.first;
      } else {
        _selectedCompany = 'ماسٹر';
      }
    }

    _categoryController = TextEditingController(text: _selectedCategory);
    _companyController = TextEditingController(text: _selectedCompany);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchaseRateController.dispose();
    _wholesaleRateController.dispose();
    _customerRateController.dispose();
    _unitController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      final category = _isCustomCategory
          ? _categoryController.text.trim()
          : (_selectedCategory.isNotEmpty
              ? _selectedCategory
              : _categoryController.text.trim());

      final company = _isCustomCompany
          ? _companyController.text.trim()
          : (_selectedCompany.isNotEmpty
              ? _selectedCompany
              : _companyController.text.trim());

      final purchaseRate =
          double.tryParse(_purchaseRateController.text.trim()) ?? 0.0;
      final wholesaleRate =
          double.tryParse(_wholesaleRateController.text.trim()) ?? 0.0;
      final customerRate =
          double.tryParse(_customerRateController.text.trim()) ?? 0.0;

      final unit = _isCustomUnit
          ? _unitController.text.trim()
          : (_selectedUnit.isNotEmpty
              ? _selectedUnit
              : (_unitController.text.trim().isEmpty
                  ? AppStrings.defaultUnit
                  : _unitController.text.trim()));

      if (widget.productToEdit != null) {
        // Update existing item
        final updatedProduct = widget.productToEdit!.copyWith(
          name: name,
          category: category,
          company: company,
          purchaseRate: purchaseRate,
          wholesaleRate: wholesaleRate,
          customerRate: customerRate,
          unit: unit,
          updatedAt: DateTime.now(),
        );

        _controller.updateProduct(widget.productToEdit!.id, updatedProduct);
        Get.back();
        Get.snackbar(
          AppStrings.update,
          AppStrings.itemUpdatedSuccess,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successGreen,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      } else {
        // Create new item
        final newProduct = ProductModel(
          id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          category: category,
          company: company,
          purchaseRate: purchaseRate,
          wholesaleRate: wholesaleRate,
          customerRate: customerRate,
          unit: unit,
          updatedAt: DateTime.now(),
        );

        _controller.addProduct(newProduct);
        Get.back();
        Get.snackbar(
          AppStrings.save,
          AppStrings.itemAddedSuccess,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryTeal,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productToEdit != null;
    final isMobile = Responsive.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
          title: Text(
            isEdit ? AppStrings.editItem : AppStrings.addNewItem,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20, desktopSize: 24),
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ResponsiveCenteredBody(
            maxWidth: 800,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category & Company Section (Row on Desktop, Column on Mobile)
                  if (!isMobile) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCategoryCard(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCompanyCard(context)),
                      ],
                    ),
                  ] else ...[
                    _buildCategoryCard(context),
                    const SizedBox(height: 12),
                    _buildCompanyCard(context),
                  ],
                  const SizedBox(height: 12),

                  // Item Name & Unit Section (Row on Desktop, Column on Mobile)
                  if (!isMobile) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildNameCard(context)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildUnitCard(context)),
                      ],
                    ),
                  ] else ...[
                    _buildNameCard(context),
                    const SizedBox(height: 12),
                    _buildUnitCard(context),
                  ],
                  const SizedBox(height: 12),

                  // Rates Section Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sell, color: AppColors.primaryTeal),
                              const SizedBox(width: 8),
                              Text(
                                'ریٹس کا اندراج (قیمت فی یونٹ)',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Rates Row on Desktop, Column on Mobile
                          if (!isMobile) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumericField(
                                    context,
                                    controller: _purchaseRateController,
                                    label: AppStrings.purchaseRateLabel,
                                    hint: AppStrings.purchaseRateHint,
                                    icon: Icons.shopping_cart,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumericField(
                                    context,
                                    controller: _wholesaleRateController,
                                    label: AppStrings.wholesaleRateLabel,
                                    hint: AppStrings.wholesaleRateHint,
                                    icon: Icons.store,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumericField(
                                    context,
                                    controller: _customerRateController,
                                    label: AppStrings.customerRateLabel,
                                    hint: AppStrings.customerRateHint,
                                    icon: Icons.person,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildNumericField(
                              context,
                              controller: _purchaseRateController,
                              label: AppStrings.purchaseRateLabel,
                              hint: AppStrings.purchaseRateHint,
                              icon: Icons.shopping_cart,
                            ),
                            const SizedBox(height: 12),
                            _buildNumericField(
                              context,
                              controller: _wholesaleRateController,
                              label: AppStrings.wholesaleRateLabel,
                              hint: AppStrings.wholesaleRateHint,
                              icon: Icons.store,
                            ),
                            const SizedBox(height: 12),
                            _buildNumericField(
                              context,
                              controller: _customerRateController,
                              label: AppStrings.customerRateLabel,
                              hint: AppStrings.customerRateHint,
                              icon: Icons.person,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Submit Button
                  ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      isEdit ? AppStrings.update : AppStrings.save,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context) {
    final availableCategories = _controller.allCategories;

    final List<String> dropdownOptions = List.from(availableCategories);
    if (_selectedCategory.isNotEmpty &&
        !dropdownOptions.contains(_selectedCategory)) {
      dropdownOptions.add(_selectedCategory);
    }

    final String activeVal = dropdownOptions.contains(_selectedCategory)
        ? _selectedCategory
        : (dropdownOptions.isNotEmpty ? dropdownOptions.first : AppConstants.defaultCategories.first);

    return _buildCardContainer(
      context,
      title: AppStrings.categoryLabel,
      icon: Icons.category,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isCustomCategory && dropdownOptions.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: activeVal,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: [
                ...dropdownOptions.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    )),
                DropdownMenuItem(
                  value: _customCategoryKey,
                  child: Text(
                    '+ نئی کیٹیگری کا نام درج کریں',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == _customCategoryKey) {
                  setState(() {
                    _isCustomCategory = true;
                    _categoryController.clear();
                    _selectedCategory = '';
                  });
                } else if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                    _categoryController.text = val;
                    _isCustomCategory = false;

                    // Reload available companies for newly chosen category
                    final categoryCompanies =
                        _controller.getCompaniesForCategory(_selectedCategory);

                    if (categoryCompanies.isNotEmpty) {
                      if (!categoryCompanies.contains(_selectedCompany)) {
                        _selectedCompany = categoryCompanies.first;
                        _companyController.text = _selectedCompany;
                        _isCustomCompany = false;
                      }
                    } else {
                      _isCustomCompany = true;
                      _companyController.clear();
                    }
                  });
                }
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    textAlign: TextAlign.right,
                    autofocus: _isCustomCategory,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'نئی کیٹیگری کا نام لکھیں',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      ),
                    ),
                    onChanged: (val) {
                      _selectedCategory = val.trim();
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
                if (dropdownOptions.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.list, color: AppColors.primaryTeal),
                    tooltip: 'فہرست سے منتخب کریں',
                    onPressed: () {
                      setState(() {
                        _isCustomCategory = false;
                        _selectedCategory = dropdownOptions.first;
                        _categoryController.text = _selectedCategory;
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context) {
    final categoryCompanies =
        _controller.getCompaniesForCategory(_selectedCategory);

    final List<String> dropdownOptions = List.from(categoryCompanies);
    if (_selectedCompany.isNotEmpty &&
        !dropdownOptions.contains(_selectedCompany)) {
      dropdownOptions.add(_selectedCompany);
    }

    final String activeVal = dropdownOptions.contains(_selectedCompany)
        ? _selectedCompany
        : (dropdownOptions.isNotEmpty ? dropdownOptions.first : '');

    return _buildCardContainer(
      context,
      title: AppStrings.companyLabel,
      icon: Icons.business,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isCustomCompany && dropdownOptions.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: activeVal,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: [
                ...dropdownOptions.map((comp) => DropdownMenuItem(
                      value: comp,
                      child: Text(
                        comp,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    )),
                DropdownMenuItem(
                  value: _customCompanyKey,
                  child: Text(
                    '+ نئی کمپنی کا نام درج کریں',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == _customCompanyKey) {
                  setState(() {
                    _isCustomCompany = true;
                    _companyController.clear();
                    _selectedCompany = '';
                  });
                } else if (val != null) {
                  setState(() {
                    _selectedCompany = val;
                    _companyController.text = val;
                  });
                }
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _companyController,
                    textAlign: TextAlign.right,
                    autofocus: _isCustomCompany,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.companyHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      ),
                    ),
                    onChanged: (val) {
                      _selectedCompany = val.trim();
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
                if (categoryCompanies.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.list, color: AppColors.primaryTeal),
                    tooltip: 'فہرست سے منتخب کریں',
                    onPressed: () {
                      setState(() {
                        _isCustomCompany = false;
                        _selectedCompany = categoryCompanies.first;
                        _companyController.text = _selectedCompany;
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNameCard(BuildContext context) {
    return _buildCardContainer(
      context,
      title: AppStrings.itemNameLabel,
      icon: Icons.inventory_2,
      child: TextFormField(
        controller: _nameController,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.itemNameHint,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
          ),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return AppStrings.requiredField;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context) {
    final List<String> unitOptions = List.from(AppConstants.defaultUnits);
    if (_selectedUnit.isNotEmpty && !unitOptions.contains(_selectedUnit)) {
      unitOptions.add(_selectedUnit);
    }

    final String activeUnitVal = unitOptions.contains(_selectedUnit)
        ? _selectedUnit
        : (unitOptions.isNotEmpty ? unitOptions.first : AppStrings.defaultUnit);

    return _buildCardContainer(
      context,
      title: AppStrings.unitLabel,
      icon: Icons.straighten,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isCustomUnit) ...[
            DropdownButtonFormField<String>(
              initialValue: activeUnitVal,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: [
                ...unitOptions.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(
                        u,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    )),
                DropdownMenuItem(
                  value: _customUnitKey,
                  child: Text(
                    '+ نیا یونٹ درج کریں',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == _customUnitKey) {
                  setState(() {
                    _isCustomUnit = true;
                    _unitController.clear();
                    _selectedUnit = '';
                  });
                } else if (val != null) {
                  setState(() {
                    _selectedUnit = val;
                    _unitController.text = val;
                  });
                }
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    textAlign: TextAlign.right,
                    autofocus: _isCustomUnit,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.unitHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                      ),
                    ),
                    onChanged: (val) {
                      _selectedUnit = val.trim();
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.list, color: AppColors.primaryTeal),
                  tooltip: 'فہرست سے منتخب کریں',
                  onPressed: () {
                    setState(() {
                      _isCustomUnit = false;
                      _selectedUnit = unitOptions.first;
                      _unitController.text = _selectedUnit;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardContainer(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
        ),
        prefixIcon: Icon(icon, color: AppColors.secondaryTeal),
        suffixText: AppStrings.currencyRs,
        suffixStyle: TextStyle(
          fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return AppStrings.requiredField;
        }
        if (double.tryParse(val.trim()) == null) {
          return 'صحیح عدد درج کریں';
        }
        return null;
      },
    );
  }
}
