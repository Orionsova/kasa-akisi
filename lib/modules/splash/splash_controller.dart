import 'package:stategetx/core/base_controller.dart';
import 'package:get/get.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/pin_service.dart';
import 'package:stategetx/services/storage_service.dart';

class SplashController extends BaseController {
  @override
  Future<void> onReady() async {
    super.onReady();
    await checkTokenAndRedirect();
  }

  Future<void> checkTokenAndRedirect() async {
    await waitForServices();
    final authService = Get.find<AuthService>();
    if (authService.hasStoredToken) {
      final pinService = Get.find<PinService>();
      Get.offAllNamed(pinService.hasPin ? AppRoutes.pin : AppRoutes.home);
      authService.refreshSessionInBackground();
      return;
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
}
