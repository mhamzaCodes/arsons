import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../controllers/auth_controller.dart';
import '../utils/responsive.dart';
import 'register_view.dart';

/// Screen for User Login using Phone Number and Password
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final bool success = AuthController.to.loginUser(
      phone: phone,
      password: password,
    );

    if (success) {
      Get.snackbar(
        'خوش آمدید',
        AppStrings.loginSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } else {
      Get.snackbar(
        'لاگ ان ناکام',
        AppStrings.invalidCredentials,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.deleteRed,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ResponsiveCenteredBody(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderCard(context),
                      const SizedBox(height: 24),
                      _buildLoginForm(context),
                      const SizedBox(height: 16),
                      // _buildRegisterLink(context),
                      // const SizedBox(height: 20),
                      // _buildDefaultCredentialsHint(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryTealDark, AppColors.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.asset(
                'assets/icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.storefront_rounded,
                  size: 40,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.appTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20, desktopSize: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.appSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: Responsive.fontSize(context, 13, desktopSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
                  Icons.login_rounded,
                  color: AppColors.primaryTeal,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.loginTitle,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 19, desktopSize: 23),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTealDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

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
                hintText: AppStrings.phoneInputHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primaryTeal),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
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

            // Password Field
            Text(
              AppStrings.passwordLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15, desktopSize: 18),
              ),
              decoration: InputDecoration(
                hintText: AppStrings.passwordHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTeal),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return AppStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleLogin,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  AppStrings.loginButton,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16, desktopSize: 19),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'اکاؤنٹ موجود نہیں ہے؟ ',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const RegisterView()),
          child: Text(
            AppStrings.noAccountPrompt,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14, desktopSize: 17),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCredentialsHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryTealDark, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ڈیفالٹ لاگ ان: فون 03001727174 | پاس ورڈ 123456',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12, desktopSize: 15),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTealDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
