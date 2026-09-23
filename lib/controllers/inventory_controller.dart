import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/constants.dart';
import '../models/product_model.dart';

/// GetX Controller for Inventory State Management & Data Persistence
class InventoryController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Observable Product List
  final RxList<ProductModel> products = <ProductModel>[].obs;

  // Selected Category & Company for Tab Navigation
  final RxString selectedCategory = ''.obs;
  final RxString selectedCompany = ''.obs;

  // Search Filter Query
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize active category with default
    if (AppConstants.defaultCategories.isNotEmpty) {
      selectedCategory.value = AppConstants.defaultCategories.first;
    }
    loadProductsFromStorage();
  }

  /// Load products from GetStorage or seed default data if empty
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
      // Fallback to seed data on error
      products.value = List.from(AppConstants.seedProducts);
    }
  }

  /// Persist products list to GetStorage
  void saveProductsToStorage() {
    final List<Map<String, dynamic>> data =
        products.map((p) => p.toMap()).toList();
    _storage.write(AppConstants.storageKeyProducts, data);
  }

  /// Reset data to initial seed products
  void resetToSeedData() {
    products.value = List.from(AppConstants.seedProducts);
    saveProductsToStorage();
    Get.snackbar('ری سیٹ', 'ابتدائی ڈیٹا کامیابی سے لوڈ ہو گیا');
  }

  // --- CRUD Operations ---

  /// Add a new product
  void addProduct(ProductModel product) {
    products.add(product);
    saveProductsToStorage();
    update();
  }

  /// Update an existing product by ID
  void updateProduct(String id, ProductModel updatedProduct) {
    final int index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index] = updatedProduct;
      saveProductsToStorage();
      update();
    }
  }

  /// Delete a product by ID
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

  /// Get all categories (merges default categories with custom categories from products)
  List<String> get allCategories {
    final Set<String> categoriesSet = {};
    categoriesSet.addAll(AppConstants.defaultCategories);

    for (var p in products) {
      if (p.category.isNotEmpty) {
        categoriesSet.add(p.category);
      }
    }

    return categoriesSet.toList();
  }

  /// Get products for a specific category
  List<ProductModel> getProductsForCategory(String category) {
    return products.where((p) => p.category == category).toList();
  }

  /// Get companies available for a given category (merges store items & defaults)
  List<String> getCompaniesForCategory(String category) {
    final Set<String> companiesSet = {};

    // First add default predefined companies for category
    if (AppConstants.defaultCategoryCompanies.containsKey(category)) {
      companiesSet.addAll(AppConstants.defaultCategoryCompanies[category]!);
    }

    // Add companies from existing products in this category
    for (var p in products.where((item) => item.category == category)) {
      if (p.company.isNotEmpty) {
        companiesSet.add(p.company);
      }
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
}
