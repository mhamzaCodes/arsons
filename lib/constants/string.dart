// Urdu strings used across the app
class AppStrings {
  // App Header & Store Details
  static const String appName = 'AR Sons';
  static const String appTitle = 'اصغر ہارڈ ویئر اینڈ سینٹری سٹور';
  static const String appSubtitle = 'انوینٹری اینڈ ریٹ لسٹ سسٹم';
  static const String ceoLabel = 'اونر:';
  static const String ceoName = 'اللہ رحم';
  static const String proprietorLabel = 'پروپرائیٹر:';
  static const String proprietorName = 'محمد حماد';
  static const String phoneLabel = 'فون نمبر:';
  static const String phoneNumber = '03001727174';
  static const String storeAddress = 'نارنگ منڈی';

  // Navigation & Titles
  static const String dashboardTitle = 'ڈیش بورڈ';
  static const String categoriesTitle = 'کیٹیگریز';
  static const String companiesTitle = 'کمپنیاں';
  static const String itemsTitle = 'آئٹمز';
  static const String rateListTitle = 'ریٹ لسٹ';

  // Statistics
  static const String totalProducts = 'کل آئٹمز';
  static const String totalCategories = 'کل کیٹیگریز';
  static const String totalCompanies = 'کل کمپنیاں';
  static const String availableItems = 'دستیاب آئٹمز';
  static const String quickPdfDownload = 'PDF ریٹ لسٹ جاری کریں';

  // Search & Filters
  static const String searchHint = 'آئٹم کا نام یا کمپنی تلاش کریں...';
  static const String allCategories = 'تمام کیٹیگریز';
  static const String allCompanies = 'تمام کمپنیاں';
  static const String noItemsFound = 'کوئی آئٹم نہیں ملا';
  static const String noCompaniesFound = 'اس کیٹیگری میں کوئی کمپنی دستیاب نہیں ہے';

  // Actions & Buttons
  static const String addNewItem = 'نیا آئٹم شامل کریں';
  static const String editItem = 'آئٹم میں ترمیم کریں';
  static const String deleteItem = 'حذف کریں';
  static const String deleteAllItems = 'تمام آئٹمز حذف کریں';
  static const String save = 'محفوظ کریں';
  static const String update = 'اپ ڈیٹ کریں';
  static const String cancel = 'منسوخ کریں';
  static const String confirm = 'تائید کریں';
  static const String close = 'بند کریں';
  static const String reset = 'ری سیٹ';

  // Dialogs
  static const String deleteConfirmTitle = 'آئٹم حذف کرنے کی تائید';
  static const String deleteConfirmMessage = 'کیا آپ واقعی اس آئٹم کو حذف کرنا چاہتے ہیں؟';
  static const String deleteAllCategoryConfirmTitle = 'تمام آئٹمز حذف کرنے کی تائید';
  static const String deletedTitle = 'حذف شدہ';

  static String deleteAllCategoryMessage(String category) =>
      'کیا آپ واقعی "$category" کے تمام آئٹمز حذف کرنا چاہتے ہیں؟ کیٹیگری اور تمام کمپنیاں موجود رہیں گی، صرف آئٹمز حذف ہوں گے۔';

  static String deleteAllCompanyMessage(String category, String company) =>
      'کیا آپ واقعی "$company" کے تمام آئٹمز حذف کرنا چاہتے ہیں؟ کیٹیگری اور کمپنی موجود رہے گی، صرف آئٹمز حذف ہوں گے۔';

  static const String deleteAllSuccessMessage =
      'تمام آئٹمز کامیابی سے حذف ہو گئے! کیٹیگری اور کمپنی محفوظ ہے۔';

  // Form fields
  static const String itemNameLabel = 'آئٹم کا نام (اردو)';
  static const String itemNameHint = 'مثلاً: ماسٹر مکسر سیٹ 3 ان 1';
  static const String categoryLabel = 'کیٹیگری منتخب کریں';
  static const String companyLabel = 'کمپنی کا نام';
  static const String companyHint = 'مثلاً: ماسٹر، فیصل، فاران، پاپولر';
  static const String purchaseRateLabel = 'دوکاندار/خرید ریٹ (روپے)';
  static const String purchaseRateHint = '0.00';
  static const String wholesaleRateLabel = 'تھوک ریٹ (روپے)';
  static const String wholesaleRateHint = '0.00';
  static const String customerRateLabel = 'گاہک ریٹ (روپے)';
  static const String customerRateHint = '0.00';
  static const String unitLabel = 'یونٹ (پیمائش)';
  static const String unitHint = 'مثلاً: عدد، فٹ، سیٹ، میٹر';
  static const String requiredField = 'یہ خانہ پر کرنا ضروری ہے';
  static const String validNumberError = 'صحیح عدد درج کریں';

  // Rate labels
  static const String ratesSectionTitle = 'ریٹس کا اندراج (قیمت فی یونٹ)';
  static const String purchaseRateAbbrev = 'خرید/دوکاندار';
  static const String wholesaleRateAbbrev = 'تھوک ریٹ';
  static const String customerRateAbbrev = 'گاہک ریٹ';

  // Prompts
  static const String enterNewCategoryPrompt = '+ نئی کیٹیگری کا نام درج کریں';
  static const String writeNewCategoryHint = 'نئی کیٹیگری کا نام لکھیں';
  static const String selectFromListTooltip = 'فہرست سے منتخب کریں';
  static const String enterNewCompanyPrompt = '+ نئی کمپنی کا نام درج کریں';
  static const String enterNewUnitPrompt = '+ نیا یونٹ درج کریں';

  // Units & Labels
  static const String currencyRs = 'روپے';
  static const String defaultUnit = 'عدد';
  static const String categoryLabelPrefix = 'کیٹیگری: ';
  static const String itemsCountPrefix = 'آئٹمز کی تعداد: ';

  // PDF
  static const String generatePdf = 'PDF ریٹ لسٹ ڈاؤن لوڈ / پرنٹ کریں';
  static const String pdfHeaderDate = 'تاریخ:';
  static const String pdfColumnNo = '#';
  static const String pdfColumnItem = 'آئٹم کا نام';
  static const String pdfColumnCategory = 'کیٹیگری';
  static const String pdfColumnCompany = 'کمپنی';
  static const String pdfColumnPurchase = 'خرید/دوکاندار';
  static const String pdfColumnWholesale = 'تھوک نرخ';
  static const String pdfColumnCustomer = 'گاہک نرخ';
  static const String pdfTotalItems = 'کل آئٹمز:';
  static const String pdfSignature = 'دستخط / مہر:';
  static const String pdfNotice = 'ریٹ بغیر اطلاع تبدیل ہو سکتے ہیں';
  static const String pdfErrorText = 'PDF تیار کرنے میں خرابی';
  static const String pdfCompanyPrefix = 'کمپنی: ';
  static const String pdfContinuedSuffix = ' (جاری)';

  // Notifications
  static const String itemAddedSuccess = 'آئٹم کاملاِ کامیابی سے شامل ہو گیا!';
  static const String itemUpdatedSuccess = 'آئٹم کاملاِ کامیابی سے اپ ڈیٹ ہو گیا!';
  static const String itemDeletedSuccess = 'آئٹم کامیابی سے حذف ہو گیا!';
  static const String fillAllFields = 'براہ کرم تمام لازمی خانے پر کریں!';
  static const String resetSuccessMessage = 'ابتدائی ڈیٹا کامیابی سے لوڈ ہو گیا';

  // Auth & Profile
  static const String welcomeTitle = 'خوش آمدید';
  static const String loginTitle = 'لاگ ان کریں';
  static const String loginFailedTitle = 'لاگ ان ناکام';
  static const String registerTitle = 'نیا اکاؤنٹ بنائیں (رجسٹریشن)';
  static const String createNewAccountHeader = 'نیا اکاؤنٹ بنائیں';
  static const String settingsTitle = 'سیٹنگز / پروائل';
  static const String fullNameLabel = 'مکمل نام';
  static const String fullNameHint = 'مثلاً: محمد حماد';
  static const String phoneInputLabel = 'فون نمبر';
  static const String phoneInputHint = '03001234567';
  static const String passwordLabel = 'پاس ورڈ';
  static const String passwordHint = '******';
  static const String newPasswordLabel = 'نیا پاس ورڈ (اختیاری)';
  static const String newPasswordHint = 'نیا پاس ورڈ درج کریں...';
  static const String confirmPasswordLabel = 'پاس ورڈ کی تصدیق کریں';
  static const String confirmPasswordHint = 'پاس ورڈ دوبارہ درج کریں...';
  static const String loginButton = 'لاگ ان کریں';
  static const String registerButton = 'رجسٹر کریں';
  static const String updateProfileButton = 'پروفائل اپ ڈیٹ کریں';
  static const String logoutButton = 'لاگ آؤٹ کریں';
  static const String noAccountPromptPrefix = 'اکاؤنٹ موجود نہیں ہے؟ ';
  static const String noAccountPrompt = 'اکاؤنٹ نہیں ہے؟ نیا اکاؤنٹ بنائیں';
  static const String hasAccountPrompt = 'پہلے سے اکاؤنٹ موجود ہے؟ لاگ ان کریں';
  static const String defaultCredentialsHint = 'ڈیفالٹ لاگ ان: فون 03001727174 | پاس ورڈ 123456';
  static const String logoutConfirmTitle = 'لاگ آؤٹ کی تائید';
  static const String logoutConfirmMessage = 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';
  static const String invalidCredentials = 'فون نمبر یا پاس ورڈ غلط ہے!';
  static const String userAlreadyExists = 'یہ فون نمبر پہلے سے رجسٹرڈ ہے!';
  static const String passwordMismatch = 'پاس ورڈز آپس میں نہیں ملتے!';
  static const String loginSuccess = 'کامیابی سے لاگ ان ہو گئے!';
  static const String registerSuccess = 'اکاؤنٹ کامیابی سے بن گیا!';
  static const String registerFailedTitle = 'رجسٹریشن ناکام';
  static const String profileUpdatedSuccess = 'پروفائل کامیابی سے اپ ڈیٹ ہو گیا!';
  static const String updateFailedTitle = 'اپ ڈیٹ ناکام';
  static const String updateFailedMessage = 'موجودہ پاس ورڈ غلط ہے یا فون نمبر پہلے سے موجود ہے!';
  static const String currentPasswordRequired = 'پاس ورڈ تبدیل کرنے کے لیے موجودہ پاس ورڈ درج کریں!';
  static const String incorrectCurrentPassword = 'موجودہ پاس ورڈ غلط ہے!';
  static const String editProfileSectionTitle = 'پروفائل اور پاس ورڈ تبدیل کریں';
  static const String passwordChangeSectionTitle = 'پاس ورڈ تبدیلی (اگر پاس ورڈ تبدیل کرنا چاہیں):';
  static const String currentPasswordLabel = 'موجودہ پاس ورڈ';
  static const String currentPasswordHint = 'موجودہ پاس ورڈ درج کریں...';
  static const String errorTitle = 'خرابی';
  static const String successTitle = 'کامیابی';

  // Backup & Restore
  static const String backupRestoreTooltip = 'ڈیٹا بیک اپ اور ریسٹور (Backup & Restore)';
  static const String backupRestoreTitle = 'ڈیٹا بیک اپ اور ریسٹور (Backup & Restore)';
  static const String backupRestoreDescription = 'اپنے تمام ڈیٹا کی بیک اپ فائل محفوظ کریں یا دوسرے ڈیوائس سے بیک اپ فائل ریسٹور کریں۔';
  static const String backupSaveTitle = 'بیک اپ فائل محفوظ کریں';
  static const String backupExportButton = 'ڈیٹا بیک اپ بنائیں (Export File)';
  static const String backupSuccessTitle = 'بیک اپ کامیاب';
  static const String backupSuccessMessage = 'ڈیٹا بیک اپ کلپ بورڈ اور فائل میں محفوظ کر دیا گیا ہے!';
  static const String backupImportButton = 'بیک اپ فائل منتخب کریں (Import File)';
  static const String restoreSuccessTitle = 'ریسٹور کامیاب';
  static const String restoreSuccessMessage = 'تمام ڈیٹا کامیابی سے ریسٹور ہو گیا ہے!';
  static const String restoreFailedMessage = 'بیک اپ فائل پڑھنے میں ناکامی!';
  static const String pasteBackupHint = 'بیک اپ کا JSON کوڈ یہاں پیسٹ کریں...';
  static const String restoreFromTextButton = 'ٹیکسٹ سے ریسٹور کریں (Restore from Text)';
  static const String pasteBackupInstruction = 'یا کلپ بورڈ سے بیک اپ ٹیکسٹ پیسٹ کر کے ریسٹور کریں:';
  static const String invalidBackupCode = 'غیر موزوں بیک اپ کوڈ!';
  static const String restoreFromTextSuccess = 'ڈیٹا کلپ بورڈ ٹیکسٹ سے کامیابی سے ریسٹور ہو گیا!';
}
