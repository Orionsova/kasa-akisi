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
  static const String marketOverview = "/market/overview";
}

class ApiService extends GetxService {
  static const Duration _defaultConnectTimeout = Duration(seconds: 20);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 20);
  static const int _maxRetryAttempts = 3;

  late StorageService _storageService;
  late Dio _dio;

  Future<ApiService> init() async {
    _storageService = Get.find<StorageService>();
    _dio = Dio(
      BaseOptions(
        baseUrl: AppRuntimeConfig.apiBaseUrl,
        connectTimeout: _defaultConnectTimeout,
        receiveTimeout: _defaultReceiveTimeout,
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
      await _requestWithRetry(
        () => _dio.get(
          ApiConstants.health,
          options: Options(
            sendTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ),
        ),
        debugLabel: 'GET ${ApiConstants.health}',
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
    return _requestWithRetry(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: 'GET $path',
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestWithRetry(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: 'POST $path',
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestWithRetry(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: 'PUT $path',
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestWithRetry(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: 'DELETE $path',
    );
  }

  Future<Response<dynamic>> _requestWithRetry(
    Future<Response<dynamic>> Function() request, {
    required String debugLabel,
  }) async {
    DioException? lastException;

    for (var attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        return await request();
      } on DioException catch (error) {
        lastException = error;
        final shouldRetry = _shouldRetry(error) && attempt < _maxRetryAttempts;
        debugPrint(
          '$debugLabel failed on attempt $attempt/$_maxRetryAttempts: ${error.type}',
        );

        if (!shouldRetry) {
          rethrow;
        }

        await Future<void>.delayed(Duration(seconds: attempt));
      } catch (e) {
        debugPrint('$debugLabel unexpected error: $e');
        rethrow;
      }
    }

    throw lastException!;
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
