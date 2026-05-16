import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/models/app_user.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/privacy_service.dart';
import 'package:stategetx/services/theme_service.dart';

class ProfileController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  Rx<AppUser?> get user => _authService.currentUser;
  PrivacyService get privacyService => Get.find<PrivacyService>();
  ThemeService get themeService => Get.find<ThemeService>();

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
