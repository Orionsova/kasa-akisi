import 'package:get/instance_manager.dart';
import 'package:stategetx/modules/login/login_controller.dart';

class LoginBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginController());
  }
}
