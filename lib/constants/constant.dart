import 'package:flutter/material.dart';
import '../exports.dart';

class AppConstants {
  // Fonts & Assets
  static const String fontFamily = 'JameelNooriNastaleeq';
  static const String appIconPath = 'assets/icon.jpg';
  static const String nastaleeqFontPath = 'assets/fonts/JameelNooriNastaleeq.ttf';

  // App details
  static const String backupAppName = 'AR Sons Inventory';
  static const int backupVersion = 1;

  // Locales
  static const Locale localeUrdu = Locale('ur', 'PK');
  static const Locale localeEnglish = Locale('en', 'US');

  // Storage keys
  static const String storageKeyProducts = 'al_haram_sanitary_products_v1';
  static const String storageKeyUsersList = 'ar_sons_registered_users_v1';
  static const String storageKeyCurrentUser = 'ar_sons_current_user_v1';
  static const String storageKeyIsLoggedIn = 'ar_sons_is_logged_in_v1';
  static const String storageKeyCustomCategories = 'ar_sons_custom_categories_v1';
  static const String storageKeyCustomCompanies = 'ar_sons_custom_companies_v1';

  // Responsive breakpoints
  static const double mobileMax = 600.0;
  static const double tabletMax = 1000.0;
  static const double maxContentWidth = 1200.0;

  // Dropdown keys
  static const String customCategoryKey = '__custom_new_category__';
  static const String customCompanyKey = '__custom_new_company__';
  static const String customUnitKey = '__custom_new_unit__';

  // Default credentials
  static const String defaultUserId = 'user_default_1';
  static const String defaultUserName = 'محمد حماد';
  static const String defaultUserPhone = '03001727174';
  static const String defaultUserPassword = '123456';

  // Default categories
  static const List<String> defaultCategories = [];

  // Default units
  static const List<String> defaultUnits = [
    'عدد',
    'فٹ',
    'سیٹ',
    'مربع فٹ',
    'میٹر',
    'گیلن',
    'کلو',
    'پیکٹ',
    'جوڑا',
    'انچ',
    'کارتوس',
    'لیٹر',
  ];

  // Default companies
  static const Map<String, List<String>> defaultCategoryCompanies = {};

  // Seed data
  static final List<ProductModel> seedProducts = [];
}
