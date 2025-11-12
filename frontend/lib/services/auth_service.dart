import 'dart:convert';

import 'package:get/get.dart';

import '../core/services/storage_service.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

class AuthService extends GetxService {
  final AuthRepository _authRepository = AuthRepository();
  final StorageService _storageService = StorageService();

  // Observable state
  final Rx<UserProfile?> currentUser = Rx<UserProfile?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  // Load user from storage on app start
  Future<void> _loadUserFromStorage() async {
    try {
      final userJson = await _storageService.getUserProfile();
      final accessToken = await _storageService.getAccessToken();

      if (userJson != null && accessToken != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        currentUser.value = UserProfile.fromJson(userMap);
        isAuthenticated.value = true;
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      await _storageService.clearAll();
    }
  }

  // Login function
  Future<void> login(String pin, String organizationId) async {
    try {
      isLoading.value = true;

      final authResponse = await _authRepository.login(pin, organizationId);

      // Store tokens
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);

      // Store user profile
      final userJson = jsonEncode(authResponse.user.toJson());
      await _storageService.saveUserProfile(userJson);

      // Update state
      currentUser.value = authResponse.user;
      isAuthenticated.value = true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Get refresh token before clearing
      final refreshToken = await _storageService.getRefreshToken();

      // Call logout API
      if (refreshToken != null) {
        await _authRepository.logout(refreshToken);
      }

      // Clear all stored data
      await _storageService.clearAll();

      // Update state
      currentUser.value = null;
      isAuthenticated.value = false;
    } catch (e) {
      print('Error during logout: $e');
      // Still clear local data even if API call fails
      await _storageService.clearAll();
      currentUser.value = null;
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get current access token
  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return currentUser.value?.role == role;
  }

  // Check if user can broadcast organization-wide
  bool canBroadcastOrgWide() {
    return currentUser.value?.canBroadcastOrgWide ?? false;
  }

  // Check if user can manage users
  bool canManageUsers() {
    return currentUser.value?.canManageUsers ?? false;
  }
}
