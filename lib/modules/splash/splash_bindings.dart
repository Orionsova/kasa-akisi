import 'package:get/instance_manager.dart';
import 'package:stategetx/modules/splash/splash_controller.dart';

class SplashBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
