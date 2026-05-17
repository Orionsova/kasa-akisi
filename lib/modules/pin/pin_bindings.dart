import 'package:get/get.dart';
import 'package:stategetx/modules/pin/pin_controller.dart';

class PinBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PinController());
  }
}
