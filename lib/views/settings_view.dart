import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../controllers/auth_controller.dart';
import '../utils/responsive.dart';

/// Screen for Managing User Profile, Updating Password, and Logout
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    final currentUser = AuthController.to.rxCurrentUser.value;
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleUpdateProfile() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final bool success = AuthController.to.updateProfile(
      name: name,
      phone: phone,
      currentPassword: currentPassword.isNotEmpty ? currentPassword : null,
      newPassword: newPassword.isNotEmpty ? newPassword : null,
    );

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      Get.snackbar(
        'کامیابی',
        AppStrings.profileUpdatedSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } else {
      Get.snackbar(
        'اپ ڈیٹ ناکام',
        'موجودہ پاس ورڈ غلط ہے یا فون نمبر پہلے سے موجود ہے!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.deleteRed,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
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
              Icons.logout_rounded,
              size: 34,
              color: AppColors.deleteRed,
            ),
          ),
          title: Text(
            AppStrings.logoutConfirmTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18, desktopSize: 22),
              color: AppColors.deleteRed,
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              color: AppColors.textSecondary,
            ),
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
                Get.back();
                AuthController.to.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.logoutButton,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(AppStrings.settingsTitle),
            centerTitle: true,
            backgroundColor: AppColors.primaryTeal,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ResponsiveCenteredBody(
                child: Column(
                  children: [
                    _buildProfileHeaderCard(context),
                    const SizedBox(height: 20),
                    _buildEditProfileCard(context),
                    // const SizedBox(height: 20),
                    // _buildStoreDetailsCard(context),
                    // const SizedBox(height: 24),
                    // _buildLogoutButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    return Obx(() {
      final user = AuthController.to.rxCurrentUser.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primaryTealDark, AppColors.primaryTeal],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 38,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? '',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 19, desktopSize: 23),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
              ),
              child: IconButton(
                onPressed: () => _showLogoutConfirmation(context),
                icon: Icon(Icons.logout_rounded, size: 24, color: Colors.red,),
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildEditProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.manage_accounts_rounded,
                  color: AppColors.primaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'پروفائل اور پاس ورڈ تبدیل کریں',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 17, desktopSize: 20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTealDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Name Field
            Text(
              AppStrings.fullNameLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryTeal),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return AppStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone Field
            Text(
              AppStrings.phoneInputLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primaryTeal),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return AppStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),

            Text(
              'پاس ورڈ تبدیلی (اگر پاس ورڈ تبدیل کرنا چاہیں):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Current Password
            Text(
              'موجودہ پاس ورڈ',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              ),
              decoration: InputDecoration(
                hintText: 'موجودہ پاس ورڈ درج کریں...',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTeal),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // New Password
            Text(
              AppStrings.newPasswordLabel,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              ),
              decoration: InputDecoration(
                hintText: AppStrings.newPasswordHint,
                prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primaryTeal),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save / Update Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleUpdateProfile,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  AppStrings.updateProfileButton,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded, color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.appTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
                  color: AppColors.primaryTealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.ceoLabel} ${AppStrings.ceoName} | ${AppStrings.proprietorLabel} ${AppStrings.proprietorName}',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'پتہ: ${AppStrings.storeAddress}',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          AppStrings.logoutButton,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deleteRed,
          side: const BorderSide(color: AppColors.deleteRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
