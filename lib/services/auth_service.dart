import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
    _hydrateCachedUser();
    return this;
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı giriş yapmayı iptal etti

      final googleAuthentication = await googleUser.authentication;
      final idToken = googleAuthentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google kimlik doğrulama anahtarı alınamadı. Google yapılandırmasını kontrol et.',
        );
      }
      debugPrint("Google User ${googleUser.toString()}");
      debugPrint("Google Auth $idToken");

      final response = await _apiService.post(
        ApiConstants.googleLogin,
        data: {'idToken': idToken},
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
        await _persistUserProfile(user);
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
        throw Exception(_humanizeDioException(e, fallback: 'Google ile giriş yapılamadı'));
      }
      if (e is PlatformException) {
        throw Exception(_humanizeGooglePlatformException(e));
      }
      if (e is Exception) rethrow;
    }
    return null;
  }

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      return _persistAuthenticatedUser(response);
    } catch (e) {
      if (e is DioException) {
        throw Exception(_humanizeDioException(e, fallback: 'Giriş yapılamadı'));
      }
      rethrow;
    }
  }

  Future<AppUser?> registerWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'firstName': firstName?.trim().isEmpty == true ? null : firstName?.trim(),
          'lastName': lastName?.trim().isEmpty == true ? null : lastName?.trim(),
        },
      );
      return _persistAuthenticatedUser(response);
    } catch (e) {
      if (e is DioException) {
        throw Exception(_humanizeDioException(e, fallback: 'Kayıt oluşturulamadı'));
      }
      rethrow;
    }
  }

  String _humanizeDioException(
    DioException exception, {
    required String fallback,
  }) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return 'Backend yanıt vermiyor. Sunucu şu an geç cevap veriyor veya ayakta değil.';
    }

    if (exception.type == DioExceptionType.connectionError) {
      final rawMessage = exception.message?.toLowerCase() ?? '';
      if (rawMessage.contains('failed host lookup')) {
        return 'Backend adresine ulaşılamadı. Sunucu alan adı veya DNS ayarını kontrol et.';
      }
      return 'Sunucuya bağlanılamadı. İnternetini veya backend bağlantısını kontrol et.';
    }

    final statusCode = exception.response?.statusCode;
    if (statusCode != null) {
      return '$fallback (kod: $statusCode)';
    }

    return fallback;
  }

  String _humanizeGooglePlatformException(PlatformException exception) {
    final code = exception.code.toLowerCase();
    final message = (exception.message ?? '').toLowerCase();

    if (code.contains('network') || message.contains('network')) {
      return 'Google oturumu açılamadı. Cihazın internetini ve backend bağlantısını kontrol et.';
    }

    if (code.contains('sign_in_canceled')) {
      return 'Google ile giriş iptal edildi.';
    }

    if (code.contains('sign_in_failed') ||
        message.contains('developer error') ||
        message.contains('10:')) {
      return 'Google giriş yapılandırması hatalı. SHA ve Google OAuth ayarları kontrol edilmeli.';
    }

    return 'Google ile giriş başarısız oldu: ${exception.code}';
  }

  Future<AppUser?> _persistAuthenticatedUser(Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }

    await _storageService.setValue<String>(
      StorageKeys.userToken,
      response.data['token'],
    );
    final user = AppUser.fromJson(response.data['user']);
    currentUser.value = user;
    await _persistUserProfile(user);
    return user;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storageService.remove(StorageKeys.userToken);
      await _storageService.remove(StorageKeys.userProfile);
      currentUser.value = null;
    } catch (e) {
      debugPrint("Çıkış yaparken hata oluştu: $e");
    }
  }

  Future<AppUser?> getProfile() async {
    try {
      return await _fetchProfileStrict();
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

      final response = await _fetchProfileStrict();
      if (response != null) {
        currentUser.value = response;
        return true;
      }
      return false;
    } catch (e) {
      await _storageService.remove(StorageKeys.userToken);
      await _storageService.remove(StorageKeys.userProfile);
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
      final response = await _fetchProfileStrict();
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

  Future<AppUser?> validateStoredSession() async {
    final token = _storageService.getValue<String>(StorageKeys.userToken);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await _fetchProfileStrict();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await signOut();
        return null;
      }
      throw Exception(
        _humanizeDioException(e, fallback: 'Oturum backend üzerinde doğrulanamadı'),
      );
    }
  }

  void _hydrateCachedUser() {
    final rawUser = _storageService.getValue<String>(StorageKeys.userProfile);
    if (rawUser == null || rawUser.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) {
        currentUser.value = AppUser.fromJson(decoded);
      } else if (decoded is Map) {
        currentUser.value = AppUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('Cached user hydrate failed: $e');
    }
  }

  Future<void> _persistUserProfile(AppUser user) async {
    await _storageService.setValue<String>(
      StorageKeys.userProfile,
      jsonEncode(user.toJson()),
    );
  }

  Future<AppUser?> _fetchProfileStrict() async {
    final response = await _apiService.get(ApiConstants.profile);
    if (response.statusCode != 200) {
      return null;
    }

    final user = AppUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    currentUser.value = user;
    await _persistUserProfile(user);
    return user;
  }
}
