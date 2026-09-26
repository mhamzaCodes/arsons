import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../exports.dart';

// User authentication and session controller
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String keyUsersList = AppConstants.storageKeyUsersList;
  static const String keyCurrentUser = AppConstants.storageKeyCurrentUser;
  static const String keyIsLoggedIn = AppConstants.storageKeyIsLoggedIn;

  // Session state
  final Rxn<UserModel> rxCurrentUser = Rxn<UserModel>();
  final RxBool isLoggedIn = false.obs;

  // Registered users list
  final RxList<UserModel> registeredUsers = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSessionAndUsers();
  }

  // Load registered users and active session from storage
  void loadSessionAndUsers() {
    try {
      final List<dynamic>? storedUsers = _storage.read<List<dynamic>>(keyUsersList);
      if (storedUsers != null && storedUsers.isNotEmpty) {
        registeredUsers.value = storedUsers
            .map((item) => UserModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Default admin user if list is empty
        final defaultUser = UserModel(
          id: AppConstants.defaultUserId,
          name: AppConstants.defaultUserName,
          phone: AppConstants.defaultUserPhone,
          password: AppConstants.defaultUserPassword,
        );
        registeredUsers.value = [defaultUser];
        _saveUsersList();
      }

      // Check current login session
      final bool loggedInFlag = _storage.read<bool>(keyIsLoggedIn) ?? false;
      final Map<String, dynamic>? userMap = _storage.read<Map<String, dynamic>>(keyCurrentUser);

      if (loggedInFlag && userMap != null) {
        final sessionUser = UserModel.fromMap(Map<String, dynamic>.from(userMap));
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

  // Save users list to storage
  void _saveUsersList() {
    final List<Map<String, dynamic>> data =
        registeredUsers.map((u) => u.toMap()).toList();
    _storage.write(keyUsersList, data);
  }

  // Save active user session
  void _saveSession(UserModel user) {
    rxCurrentUser.value = user;
    isLoggedIn.value = true;
    _storage.write(keyCurrentUser, user.toMap());
    _storage.write(keyIsLoggedIn, true);
  }

  // Clear active user session
  void _clearSession() {
    rxCurrentUser.value = null;
    isLoggedIn.value = false;
    _storage.remove(keyCurrentUser);
    _storage.write(keyIsLoggedIn, false);
  }

  // Login with phone and password
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

  // Register a new user
  bool registerUser({
    required String name,
    required String phone,
    required String password,
  }) {
    final cleanPhone = phone.trim();
    final cleanName = name.trim();
    final cleanPassword = password.trim();

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

  // Update profile details
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

    if (cleanPhone != currentUser.phone) {
      final bool phoneTaken = registeredUsers.any(
        (u) => u.phone.trim() == cleanPhone && u.id != currentUser.id,
      );
      if (phoneTaken) {
        return false;
      }
    }

    String updatedPassword = currentUser.password;

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      if (currentPassword == null || currentPassword.trim() != currentUser.password) {
        return false;
      }
      updatedPassword = newPassword.trim();
    }

    final updatedUser = currentUser.copyWith(
      name: cleanName,
      phone: cleanPhone,
      password: updatedPassword,
    );

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

  // Logout current user
  void logout() {
    _clearSession();
    Get.offAll(() => const LoginView());
  }
}
