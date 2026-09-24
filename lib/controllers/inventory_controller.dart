import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/constants.dart';
import '../models/product_model.dart';

/// GetX Controller for Inventory State Management, Persistent Companies & Backup/Restore
class InventoryController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Observable Product List
  final RxList<ProductModel> products = <ProductModel>[].obs;

  // Observable Categories List (merges defaults with custom categories)
  final RxList<String> categories = <String>[].obs;

  // Persistent Custom Companies Map: Category -> List of Custom Companies
  final RxMap<String, List<String>> customCompanies = <String, List<String>>{}.obs;

  // Selected Category & Company for Tab Navigation
  final RxString selectedCategory = ''.obs;
  final RxString selectedCompany = ''.obs;

  // Search Filter Query
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProductsFromStorage();
  }

  /// Load products & stored custom companies from GetStorage
  void loadProductsFromStorage() {
    try {
      final List<dynamic>? storedData =
          _storage.read<List<dynamic>>(AppConstants.storageKeyProducts);

      if (storedData != null && storedData.isNotEmpty) {
        products.value = storedData
            .map((item) => ProductModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Seed initial products if storage is empty
        products.value = List.from(AppConstants.seedProducts);
        saveProductsToStorage();
      }
    } catch (e) {
      products.value = List.from(AppConstants.seedProducts);
    }

    // Load stored custom companies per category
    try {
      final Map<String, dynamic>? storedCompanies =
          _storage.read<Map<String, dynamic>>('ar_sons_custom_companies_v1');
      if (storedCompanies != null) {
        customCompanies.value = storedCompanies.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }
    } catch (_) {}

    // Synchronize company names from existing products into customCompanies storage
    for (var p in products) {
      registerCompanyForCategory(p.category, p.company);
    }

    updateCategoriesList();

    if (categories.isNotEmpty && selectedCategory.value.isEmpty) {
      selectedCategory.value = categories.first;
    }
  }

  /// Register and persist a company for a category in GetStorage so it remains permanently
  void registerCompanyForCategory(String category, String company) {
    if (category.trim().isEmpty || company.trim().isEmpty) return;
    final cat = category.trim();
    final comp = company.trim();

    final List<String> currentList =
        List<String>.from(customCompanies[cat] ?? []);
    if (!currentList.contains(comp)) {
      currentList.add(comp);
      customCompanies[cat] = currentList;
      _storage.write('ar_sons_custom_companies_v1', customCompanies);
    }
  }

  /// Synchronize categories list from default categories and current products
  void updateCategoriesList() {
    final Set<String> categoriesSet = {};
    categoriesSet.addAll(AppConstants.defaultCategories);

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

  /// Persist products list to GetStorage
  void saveProductsToStorage() {
    final List<Map<String, dynamic>> data =
        products.map((p) => p.toMap()).toList();
    _storage.write(AppConstants.storageKeyProducts, data);
    updateCategoriesList();
  }

  /// Reset data to initial seed products
  void resetToSeedData() {
    products.value = List.from(AppConstants.seedProducts);
    saveProductsToStorage();
    if (categories.isNotEmpty) {
      selectedCategory.value = categories.first;
    }
    selectedCompany.value = '';
    Get.snackbar('ری سیٹ', 'ابتدائی ڈیٹا کامیابی سے لوڈ ہو گیا');
  }

  // --- CRUD Operations ---

  /// Add a new product and preserve its company permanently
  void addProduct(ProductModel product) {
    products.add(product);
    registerCompanyForCategory(product.category, product.company);
    saveProductsToStorage();

    if (product.category.isNotEmpty) {
      selectedCategory.value = product.category;
    }
    update();
  }

  /// Update an existing product and preserve its company permanently
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

  /// Delete a product by ID (Company remains preserved in customCompanies storage)
  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    saveProductsToStorage();
    update();
  }

  // --- Filter & Query Helpers ---

  /// Set selected category
  void selectCategory(String category) {
    selectedCategory.value = category;
    selectedCompany.value = ''; // Reset company filter on category change
  }

  /// Set selected company
  void selectCompany(String company) {
    selectedCompany.value = company;
  }

  /// Clear company filter
  void clearCompanyFilter() {
    selectedCompany.value = '';
  }

  /// Set search query
  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  /// Get all categories (merges default categories with custom categories)
  List<String> get allCategories {
    return categories;
  }

  /// Get all unique companies across ALL categories in the store
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

  /// Get products for a specific category
  List<ProductModel> getProductsForCategory(String category) {
    return products.where((p) => p.category == category).toList();
  }

  /// Get companies available for a given category (merges defaults, saved custom companies, & active items)
  /// If no companies exist for a new category, returns all store companies as choices!
  List<String> getCompaniesForCategory(String category) {
    final Set<String> companiesSet = {};

    // 1. Add default predefined companies for category
    if (AppConstants.defaultCategoryCompanies.containsKey(category)) {
      companiesSet.addAll(AppConstants.defaultCategoryCompanies[category]!);
    }

    // 2. Add saved custom companies for category
    if (customCompanies.containsKey(category)) {
      companiesSet.addAll(customCompanies[category]!);
    }

    // 3. Add companies from active products in category
    for (var p in products.where((item) => item.category == category)) {
      if (p.company.trim().isNotEmpty) {
        companiesSet.add(p.company.trim());
      }
    }

    // Fallback: If category has no specific companies yet, show all store companies
    if (companiesSet.isEmpty) {
      return allCompanies;
    }

    return companiesSet.toList();
  }

  /// Filtered product list based on Category, Company & Search Query
  List<ProductModel> get filteredProducts {
    return products.where((product) {
      // Category Match
      bool matchesCategory = selectedCategory.value.isEmpty ||
          product.category == selectedCategory.value;

      // Company Match
      bool matchesCompany = selectedCompany.value.isEmpty ||
          product.company == selectedCompany.value;

      // Search Query Match (checks Item Name, Company, Category)
      bool matchesSearch = searchQuery.value.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.company.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.category.toLowerCase().contains(searchQuery.value.toLowerCase());

      return matchesCategory && matchesCompany && matchesSearch;
    }).toList();
  }

  /// Count products for a specific category
  int getCategoryCount(String category) {
    return products.where((p) => p.category == category).length;
  }

  /// Count products for a specific company in a category
  int getCompanyCount(String category, String company) {
    return products
        .where((p) => p.category == category && p.company == company)
        .length;
  }

  // --- Data Backup & Restore (Portability) ---

  /// Generate formatted JSON string containing full backup of all products & companies
  String generateBackupJson() {
    final Map<String, dynamic> backupMap = {
      'app': 'AR Sons Inventory',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalProducts': products.length,
      'customCompanies': customCompanies,
      'products': products.map((p) => p.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Restore inventory items & custom companies from JSON backup string
  bool restoreFromBackupJson(String jsonString) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      List<dynamic>? productsList;

      if (decoded.containsKey('products')) {
        productsList = decoded['products'];
      } else if (decoded is List) {
        productsList = decoded as List<dynamic>;
      }

      if (decoded.containsKey('customCompanies')) {
        try {
          final Map<String, dynamic> compMap = decoded['customCompanies'];
          customCompanies.value = compMap.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
          _storage.write('ar_sons_custom_companies_v1', customCompanies);
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
