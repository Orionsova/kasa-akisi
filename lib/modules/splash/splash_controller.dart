import 'package:stategetx/core/base_controller.dart';
import 'package:get/get.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/pin_service.dart';
import 'package:stategetx/services/storage_service.dart';

class SplashController extends BaseController {
  final status = 'starting'.obs;
  final message = RxnString();

  @override
  Future<void> onReady() async {
    super.onReady();
    await bootstrapAccess();
  }

  Future<void> bootstrapAccess() async {
    if (isLoading) return;

    setLoading(true);
    status.value = 'starting';
    message.value = null;

    try {
      await checkTokenAndRedirect();
    } finally {
      setLoading(false);
    }
  }

  Future<void> checkTokenAndRedirect() async {
    await waitForServices();

    final authService = Get.find<AuthService>();
    if (authService.hasStoredToken) {
      status.value = 'connecting';
      await _warmUpBackend();

      status.value = 'authenticating';
      try {
        final user = await authService.validateStoredSession();
        if (user == null) {
          Get.offAllNamed(AppRoutes.login);
          return;
        }

        final pinService = Get.find<PinService>();
        Get.offAllNamed(AppRoutes.pin, arguments: !pinService.hasPin);
        return;
      } catch (e) {
        status.value = 'error';
        message.value = e.toString().replaceFirst('Exception: ', '');
        return;
      }
    }

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> waitForServices() async {
    while (!Get.isRegistered<StorageService>() ||
        !Get.isRegistered<ApiService>() ||
        !Get.isRegistered<AuthService>() ||
        !Get.isRegistered<PinService>()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _warmUpBackend() async {
    final apiService = Get.find<ApiService>();
    await apiService.warmUpBackend();
  }
}
