import '../models/product_model.dart';

class AppConstants {
  // Font Family Name
  static const String fontFamily = 'JameelNooriNastaleeq';

  // Storage Keys
  static const String storageKeyProducts = 'al_haram_sanitary_products_v1';

  // Default Categories List
  static const List<String> defaultCategories = [
    'پائپ اور فٹنگ',
    'مکسر اور نل',
    'سینٹری ویئر / سیٹس',
    'پانی کی ٹینکیاں',
    'ٹائلز اور سلیب',
    'متفرق سامان',
  ];

  // Default Companies List per Category
  static const Map<String, List<String>> defaultCategoryCompanies = {
    'پائپ اور فٹنگ': ['ماسٹر', 'فاران', 'پاپولر', 'تارڑ', 'ایشیا', 'ٹویو'],
    'مکسر اور نل': ['فیصل', 'ماسٹر', 'سونیکس', 'تھری اسٹار', 'شاندار'],
    'سینٹری ویئر / سیٹس': ['ماسٹر', 'انعام', 'روائل', 'ایشیائی', 'کرمپورہ'],
    'پانی کی ٹینکیاں': ['ماسٹر', 'پاپولر', 'سپر', 'کلاسک'],
    'ٹائلز اور سلیب': ['ماسٹر', 'ٹائمز', 'اسٹار', 'ٹائمز سٹیل'],
    'متفرق سامان': ['عام', 'مقامی', 'چائنا'],
  };

  // Seed Data: Pre-populated items for Sanitary & Tile Store
  static final List<ProductModel> seedProducts = [
    ProductModel(
      id: 'prod_1',
      name: 'پائپ 3 انچ PPR (10 فٹ)',
      category: 'پائپ اور فٹنگ',
      company: 'ماسٹر',
      purchaseRate: 1200.0,
      wholesaleRate: 1350.0,
      customerRate: 1500.0,
      unit: 'فٹ',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_2',
      name: 'پائپ 4 انچ PVC (10 فٹ)',
      category: 'پائپ اور فٹنگ',
      company: 'پاپولر',
      purchaseRate: 1800.0,
      wholesaleRate: 2000.0,
      customerRate: 2200.0,
      unit: 'فٹ',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_3',
      name: 'ایلبو 3 انچ 90 ڈگری PPR',
      category: 'پائپ اور فٹنگ',
      company: 'فاران',
      purchaseRate: 250.0,
      wholesaleRate: 280.0,
      customerRate: 320.0,
      unit: 'عدد',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_4',
      name: 'بیسن مکسر ڈبل ہینڈل',
      category: 'مکسر اور نل',
      company: 'فیصل',
      purchaseRate: 4500.0,
      wholesaleRate: 5000.0,
      customerRate: 5500.0,
      unit: 'سیٹ',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_5',
      name: 'شاور مکسر وال ماؤنٹ',
      category: 'مکسر اور نل',
      company: 'ماسٹر',
      purchaseRate: 6200.0,
      wholesaleRate: 6800.0,
      customerRate: 7500.0,
      unit: 'سیٹ',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_6',
      name: 'مسلم شاور پیتل باڈی',
      category: 'مکسر اور نل',
      company: 'سونیکس',
      purchaseRate: 1100.0,
      wholesaleRate: 1300.0,
      customerRate: 1500.0,
      unit: 'عدد',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_7',
      name: 'انگلش کموڈ ڈبل پیس',
      category: 'سینٹری ویئر / سیٹس',
      company: 'ماسٹر',
      purchaseRate: 14500.0,
      wholesaleRate: 16000.0,
      customerRate: 18000.0,
      unit: 'سیٹ',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_8',
      name: 'ایشین ڈبلیو سی وائٹ',
      category: 'سینٹری ویئر / سیٹس',
      company: 'انعام',
      purchaseRate: 3200.0,
      wholesaleRate: 3600.0,
      customerRate: 4000.0,
      unit: 'عدد',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_9',
      name: 'پانی کی ٹینکی 500 گیلن 3 لئیر',
      category: 'پانی کی ٹینکیاں',
      company: 'پاپولر',
      purchaseRate: 18500.0,
      wholesaleRate: 20000.0,
      customerRate: 22500.0,
      unit: 'عدد',
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod_10',
      name: 'فلور ٹائل 60x60 سپرفائن',
      category: 'ٹائلز اور سلیب',
      company: 'ٹائمز',
      purchaseRate: 180.0,
      wholesaleRate: 210.0,
      customerRate: 240.0,
      unit: 'مربع فٹ',
      updatedAt: DateTime.now(),
    ),
  ];
}
