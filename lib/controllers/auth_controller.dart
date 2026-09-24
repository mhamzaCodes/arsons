import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../views/home_view.dart';
import '../views/login_view.dart';

/// GetX Controller for User Authentication, Local Storage Persistence & Profile Management
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final GetStorage _storage = GetStorage();

  // Storage Keys
  static const String keyUsersList = 'ar_sons_registered_users_v1';
  static const String keyCurrentUser = 'ar_sons_current_user_v1';
  static const String keyIsLoggedIn = 'ar_sons_is_logged_in_v1';

  // Observable User Session State
  final Rxn<UserModel> rxCurrentUser = Rxn<UserModel>();
  final RxBool isLoggedIn = false.obs;

  // Observable Registered Users List
  final RxList<UserModel> registeredUsers = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSessionAndUsers();
  }

  /// Load registered users and active session state from GetStorage
  void loadSessionAndUsers() {
    try {
      final List<dynamic>? storedUsers = _storage.read<List<dynamic>>(keyUsersList);
      if (storedUsers != null && storedUsers.isNotEmpty) {
        registeredUsers.value = storedUsers
            .map((item) => UserModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Seed initial admin/default user if list is empty
        final defaultUser = UserModel(
          id: 'user_default_1',
          name: 'محمد حماد',
          phone: '03001727174',
          password: '123456',
        );
        registeredUsers.value = [defaultUser];
        _saveUsersList();
      }

      // Check current login session
      final bool loggedInFlag = _storage.read<bool>(keyIsLoggedIn) ?? false;
      final Map<String, dynamic>? userMap = _storage.read<Map<String, dynamic>>(keyCurrentUser);

      if (loggedInFlag && userMap != null) {
        final sessionUser = UserModel.fromMap(Map<String, dynamic>.from(userMap));
        // Verify user still exists in registered list
        final int index = registeredUsers.indexWhere((u) => u.id == sessionUser.id || u.phone == sessionUser.phone);
        if (index != -1) {
          rxCurrentUser.value = registeredUsers[index];
          isLoggedIn.value = true;
        } else {
          _clearSession();
        }
      } else {
        _clearSession();
      }
    } catch (_) {
      _clearSession();
    }
  }

  /// Save registered users list to GetStorage
  void _saveUsersList() {
    final List<Map<String, dynamic>> data =
        registeredUsers.map((u) => u.toMap()).toList();
    _storage.write(keyUsersList, data);
  }

  /// Save current active user session to GetStorage
  void _saveSession(UserModel user) {
    rxCurrentUser.value = user;
    isLoggedIn.value = true;
    _storage.write(keyCurrentUser, user.toMap());
    _storage.write(keyIsLoggedIn, true);
  }

  /// Clear active session from GetStorage
  void _clearSession() {
    rxCurrentUser.value = null;
    isLoggedIn.value = false;
    _storage.remove(keyCurrentUser);
    _storage.write(keyIsLoggedIn, false);
  }

  // --- Auth Actions ---

  /// Login user with phone number and password
  bool loginUser({required String phone, required String password}) {
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();

    final int userIndex = registeredUsers.indexWhere(
      (u) => u.phone.trim() == cleanPhone && u.password == cleanPassword,
    );

    if (userIndex != -1) {
      final user = registeredUsers[userIndex];
      _saveSession(user);
      Get.offAll(() => const HomeView());
      return true;
    }
    return false;
  }

  /// Register a new user with name, phone, and password
  bool registerUser({
    required String name,
    required String phone,
    required String password,
  }) {
    final cleanPhone = phone.trim();
    final cleanName = name.trim();
    final cleanPassword = password.trim();

    // Check if phone number already registered
    final bool phoneExists = registeredUsers.any((u) => u.phone.trim() == cleanPhone);
    if (phoneExists) {
      return false;
    }

    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      phone: cleanPhone,
      password: cleanPassword,
    );

    registeredUsers.add(newUser);
    _saveUsersList();
    _saveSession(newUser);

    Get.offAll(() => const HomeView());
    return true;
  }

  /// Update profile details (Name, Phone, and optional new password)
  bool updateProfile({
    required String name,
    required String phone,
    String? currentPassword,
    String? newPassword,
  }) {
    final currentUser = rxCurrentUser.value;
    if (currentUser == null) return false;

    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    // Check if phone number changed and if new phone already taken by another user
    if (cleanPhone != currentUser.phone) {
      final bool phoneTaken = registeredUsers.any(
        (u) => u.phone.trim() == cleanPhone && u.id != currentUser.id,
      );
      if (phoneTaken) {
        return false;
      }
    }

    String updatedPassword = currentUser.password;

    // Handle password change if newPassword provided
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      if (currentPassword == null || currentPassword.trim() != currentUser.password) {
        return false; // Invalid current password
      }
      updatedPassword = newPassword.trim();
    }

    final updatedUser = currentUser.copyWith(
      name: cleanName,
      phone: cleanPhone,
      password: updatedPassword,
    );

    // Update in registeredUsers list
    final int index = registeredUsers.indexWhere((u) => u.id == currentUser.id);
    if (index != -1) {
      registeredUsers[index] = updatedUser;
    } else {
      registeredUsers.add(updatedUser);
    }

    _saveUsersList();
    _saveSession(updatedUser);
    return true;
  }

  /// Logout current user and redirect to LoginView
  void logout() {
    _clearSession();
    Get.offAll(() => const LoginView());
  }
}
