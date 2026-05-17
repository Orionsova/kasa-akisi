import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import 'package:stategetx/services/storage_service.dart';

abstract final class AppRuntimeConfig {
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _googleServerClientIdOverride =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
  static const String _productionApiBaseUrl =
      'https://kasa-akisi-backend.onrender.com/api';

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.trim().isNotEmpty) {
      return _apiBaseUrlOverride.trim();
    }
    return _productionApiBaseUrl;
  }

  static String get googleServerClientId {
    if (_googleServerClientIdOverride.trim().isNotEmpty) {
      return _googleServerClientIdOverride.trim();
    }

    return '459972794493-kn3tk0ec16ll8chdi1q961lnde2270ro.apps.googleusercontent.com';
  }
}

abstract class ApiConstants {
  static const String health = "/health";
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String googleLogin = "/auth/google";
  static const String appleLogin = "/auth/apple";
  static const String profile = "/auth/profile";

  static const String categories = "/categories";
  static const String transactions = "/transactions";
  static const String creditCards = "/credit-cards";
  static const String creditCardScoreHistory = "/credit-cards/score-history";
  static const String investments = "/investments";
  static const String recurringTransactions = "/recurring-transactions";
}

class ApiService extends GetxService {
  late StorageService _storageService;
  late Dio _dio;

  Future<ApiService> init() async {
    _storageService = Get.find<StorageService>();
    _dio = Dio(
      BaseOptions(
        baseUrl: AppRuntimeConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        contentType: "application/json",
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storageService.getValue<String>(StorageKeys.userToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storageService.remove(StorageKeys.userToken);
          }
          return handler.next(error);
        },
      ),
    );
    return this;
  }

  Future<void> warmUpBackend() async {
    try {
      await _dio.get(
        ApiConstants.health,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Backend warm-up skipped: $e');
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      debugPrint("Dio get error $e");
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      debugPrint("Dio post error $e");
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      debugPrint("Dio put error $e");
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      debugPrint("Dio delete error $e");
      rethrow;
    }
  }
}
