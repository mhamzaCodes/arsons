import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../exports.dart';

// Inventory state management and local storage controller
class InventoryController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Products list
  final RxList<ProductModel> products = <ProductModel>[].obs;

  // Categories list
  final RxList<String> categories = <String>[].obs;

  // Custom categories list
  final RxList<String> customCategories = <String>[].obs;

  // Custom companies map (category -> company list)
  final RxMap<String, List<String>> customCompanies = <String, List<String>>{}.obs;

  // Selected filters
  final RxString selectedCategory = ''.obs;
  final RxString selectedCompany = ''.obs;

  // Search query
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProductsFromStorage();
  }

  // Load products & custom categories/companies from local storage
  void loadProductsFromStorage() {
    try {
      final List<dynamic>? storedData =
          _storage.read<List<dynamic>>(AppConstants.storageKeyProducts);

      if (storedData != null && storedData.isNotEmpty) {
        products.value = storedData
            .map((item) => ProductModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        products.value = List.from(AppConstants.seedProducts);
        saveProductsToStorage();
      }
    } catch (e) {
      products.value = List.from(AppConstants.seedProducts);
    }

    try {
      final List<dynamic>? storedCategories =
          _storage.read<List<dynamic>>(AppConstants.storageKeyCustomCategories);
      if (storedCategories != null) {
        customCategories.value = List<String>.from(storedCategories);
      }
    } catch (_) {}

    try {
      final Map<String, dynamic>? storedCompanies =
          _storage.read<Map<String, dynamic>>(AppConstants.storageKeyCustomCompanies);
      if (storedCompanies != null) {
        customCompanies.value = storedCompanies.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }
    } catch (_) {}

    for (var p in products) {
      registerCategory(p.category);
      registerCompanyForCategory(p.category, p.company);
    }

    updateCategoriesList();

    if (categories.isNotEmpty && selectedCategory.value.isEmpty) {
      selectedCategory.value = categories.first;
    }
  }

  // Save category to storage
  void registerCategory(String category) {
    if (category.trim().isEmpty) return;
    final cat = category.trim();

    if (!customCategories.contains(cat)) {
      customCategories.add(cat);
      _storage.write(AppConstants.storageKeyCustomCategories, customCategories);
    }
  }

  // Save company for a category to storage
  void registerCompanyForCategory(String category, String company) {
    if (category.trim().isEmpty || company.trim().isEmpty) return;
    final cat = category.trim();
    final comp = company.trim();

    registerCategory(cat);

    final List<String> currentList =
        List<String>.from(customCompanies[cat] ?? []);
    if (!currentList.contains(comp)) {
      currentList.add(comp);
      customCompanies[cat] = currentList;
      _storage.write(AppConstants.storageKeyCustomCompanies, customCompanies);
    }
  }

  // Merge categories from default, custom storage, and products
  void updateCategoriesList() {
    final Set<String> categoriesSet = {};

    categoriesSet.addAll(AppConstants.defaultCategories);
    categoriesSet.addAll(customCategories);
    categoriesSet.addAll(customCompanies.keys);

    for (var p in products) {
      if (p.category.trim().isNotEmpty) {
        categoriesSet.add(p.category.trim());
      }
    }

    final newList = categoriesSet.toList();
    bool changed = categories.length != newList.length;
    if (!changed) {
      for (int i = 0; i < newList.length; i++) {
        if (categories[i] != newList[i]) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      categories.value = newList;
    }
  }

  // Save products list
  void saveProductsToStorage() {
    final List<Map<String, dynamic>> data =
        products.map((p) => p.toMap()).toList();
    _storage.write(AppConstants.storageKeyProducts, data);
    updateCategoriesList();
  }

  // Reset data to seed defaults
  void resetToSeedData() {
    products.value = List.from(AppConstants.seedProducts);
    saveProductsToStorage();
    if (categories.isNotEmpty) {
      selectedCategory.value = categories.first;
    }
    selectedCompany.value = '';
    Get.snackbar(AppStrings.reset, AppStrings.resetSuccessMessage);
  }

  // CRUD actions
  void addProduct(ProductModel product) {
    products.add(product);
    registerCompanyForCategory(product.category, product.company);
    saveProductsToStorage();

    if (product.category.isNotEmpty) {
      selectedCategory.value = product.category;
    }
    update();
  }

  void updateProduct(String id, ProductModel updatedProduct) {
    final int index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index] = updatedProduct;
      registerCompanyForCategory(
          updatedProduct.category, updatedProduct.company);
      saveProductsToStorage();
      update();
    }
  }

  void deleteProduct(String id) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final product = products[index];
      registerCompanyForCategory(product.category, product.company);
      products.removeAt(index);
      saveProductsToStorage();
      update();
    }
  }

  void deleteAllItemsForCompany(String category, String company) {
    registerCompanyForCategory(category, company);
    products.removeWhere((p) => p.category == category && p.company == company);
    saveProductsToStorage();
    update();
  }

  void deleteAllItemsForCategory(String category) {
    registerCategory(category);
    final companies = getCompaniesForCategory(category);
    for (var comp in companies) {
      registerCompanyForCategory(category, comp);
    }
    products.removeWhere((p) => p.category == category);
    saveProductsToStorage();
    update();
  }

  void deleteAllProducts() {
    for (var p in products) {
      registerCompanyForCategory(p.category, p.company);
    }
    products.clear();
    saveProductsToStorage();
    update();
  }

  // Filters
  void selectCategory(String category) {
    selectedCategory.value = category;
    selectedCompany.value = '';
  }

  void selectCompany(String company) {
    selectedCompany.value = company;
  }

  void clearCompanyFilter() {
    selectedCompany.value = '';
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  List<String> get allCategories => categories;

  List<String> get allCompanies {
    final Set<String> allSet = {};

    for (var list in AppConstants.defaultCategoryCompanies.values) {
      allSet.addAll(list);
    }
    for (var list in customCompanies.values) {
      allSet.addAll(list);
    }
    for (var p in products) {
      if (p.company.trim().isNotEmpty) {
        allSet.add(p.company.trim());
      }
    }

    return allSet.toList();
  }

  List<ProductModel> getProductsForCategory(String category) {
    return products.where((p) => p.category == category).toList();
  }

  List<String> getCompaniesForCategory(String category) {
    final Set<String> companiesSet = {};

    if (AppConstants.defaultCategoryCompanies.containsKey(category)) {
      companiesSet.addAll(AppConstants.defaultCategoryCompanies[category]!);
    }

    if (customCompanies.containsKey(category)) {
      companiesSet.addAll(customCompanies[category]!);
    }

    for (var p in products.where((item) => item.category == category)) {
      if (p.company.trim().isNotEmpty) {
        companiesSet.add(p.company.trim());
      }
    }

    if (companiesSet.isEmpty) {
      return allCompanies;
    }

    return companiesSet.toList();
  }

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      bool matchesCategory = selectedCategory.value.isEmpty ||
          product.category == selectedCategory.value;

      bool matchesCompany = selectedCompany.value.isEmpty ||
          product.company == selectedCompany.value;

      bool matchesSearch = searchQuery.value.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.company.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.category.toLowerCase().contains(searchQuery.value.toLowerCase());

      return matchesCategory && matchesCompany && matchesSearch;
    }).toList();
  }

  int getCategoryCount(String category) {
    return products.where((p) => p.category == category).length;
  }

  int getCompanyCount(String category, String company) {
    return products
        .where((p) => p.category == category && p.company == company)
        .length;
  }

  // Backup & Restore
  String generateBackupJson() {
    final Map<String, dynamic> backupMap = {
      'app': AppConstants.backupAppName,
      'version': AppConstants.backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalProducts': products.length,
      'customCategories': customCategories,
      'customCompanies': customCompanies,
      'products': products.map((p) => p.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  bool restoreFromBackupJson(String jsonString) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      List<dynamic>? productsList;

      if (decoded.containsKey('products')) {
        productsList = decoded['products'];
      } else if (decoded is List) {
        productsList = decoded as List<dynamic>;
      }

      if (decoded.containsKey('customCategories')) {
        try {
          final List<dynamic> catList = decoded['customCategories'];
          customCategories.value = List<String>.from(catList);
          _storage.write(AppConstants.storageKeyCustomCategories, customCategories);
        } catch (_) {}
      }

      if (decoded.containsKey('customCompanies')) {
        try {
          final Map<String, dynamic> compMap = decoded['customCompanies'];
          customCompanies.value = compMap.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
          _storage.write(AppConstants.storageKeyCustomCompanies, customCompanies);
        } catch (_) {}
      }

      if (productsList != null && productsList.isNotEmpty) {
        final List<ProductModel> restoredProducts = productsList
            .map((item) => ProductModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        if (restoredProducts.isNotEmpty) {
          products.value = restoredProducts;
          saveProductsToStorage();

          for (var p in products) {
            registerCompanyForCategory(p.category, p.company);
          }

          updateCategoriesList();
          if (categories.isNotEmpty) {
            selectedCategory.value = categories.first;
          }
          selectedCompany.value = '';
          update();
          return true;
        }
      }
    } catch (e) {
      // Error handling
    }
    return false;
  }
}
