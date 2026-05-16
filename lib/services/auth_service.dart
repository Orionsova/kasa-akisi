import 'package:flutter/foundation.dart';
import 'package:get/state_manager.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:stategetx/models/app_user.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:get/instance_manager.dart';

class AuthService extends GetxService {
  late final GoogleSignIn _googleSignIn;
  late final ApiService _apiService;
  late final StorageService _storageService;

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);

  Future<AuthService> init() async {
    _storageService = Get.find<StorageService>();
    _apiService = Get.find<ApiService>();
    _googleSignIn = GoogleSignIn(
      serverClientId: AppRuntimeConfig.googleServerClientId,
    );
    return this;
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı giriş yapmayı iptal etti

      final googleAuthentication = await googleUser.authentication;
      debugPrint("Google User ${googleUser.toString()}");
      debugPrint("Google Auth ${googleAuthentication.idToken}");

      final response = await _apiService.post(
        ApiConstants.googleLogin,
        data: {'idToken': googleAuthentication.idToken},
      );
      if (response.statusCode == 200) {
        await _storageService.setValue<String>(
          StorageKeys.userToken,
          response.data['token'],
        );
        debugPrint("JWT TOKEN");
        debugPrint(response.data['token']);
        debugPrint("JWT TOKEN");

        var user = AppUser.fromJson(response.data['user']);
        currentUser.value = user;
        return user;
      } else {
        return null;
      }
    } catch (e, stack) {
      debugPrint("Google ile giriş yaparken hata oluştu: $e");
      debugPrint(stack.toString());
      if (e is DioException) {
        debugPrint('DioException status: ${e.response?.statusCode}');
        debugPrint('DioException data: ${e.response?.data}');
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storageService.remove(StorageKeys.userToken);
    } catch (e) {
      debugPrint("Çıkış yaparken hata oluştu: $e");
    }
  }

  Future<AppUser?> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        currentUser.value = AppUser.fromJson(response.data);
        return AppUser.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint("Profil bilgisi alınirken hata olustu: $e");
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = _storageService.getValue<String>(StorageKeys.userToken);
      if (token == null) {
        return false;
      }

      final response = await getProfile();
      if (response != null) {
        currentUser.value = response;
        return true;
      }
      return false;
    } catch (e) {
      await _storageService.remove(StorageKeys.userToken);
      currentUser.value = null;
      return false;
    }
  }

  bool get hasStoredToken {
    try {
      return _storageService.getValue<String>(StorageKeys.userToken) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshSessionInBackground() async {
    if (!hasStoredToken) {
      currentUser.value = null;
      return;
    }

    try {
      final response = await getProfile();
      if (response != null) {
        currentUser.value = response;
        return;
      }
      await signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      // Keep the user in-app on transient failures such as cold backend start.
    }
  }
}
