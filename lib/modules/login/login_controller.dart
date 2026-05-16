import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:get/get.dart';

class LoginController extends BaseController {
  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  Future<void> googleIleGirisYap() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      Get.snackbar('Giriş Hatası', 'Google ile giriş yapılamadı');
    } catch (e) {
      Get.snackbar('Giriş Hatası', e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
