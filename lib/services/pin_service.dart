import 'package:get/get.dart';
import 'package:stategetx/services/storage_service.dart';

class PinService extends GetxService {
  late final StorageService _storageService;

  Future<PinService> init() async {
    _storageService = Get.find<StorageService>();
    return this;
  }

  bool get hasPin {
    final pin = _storageService.getValue<String>(StorageKeys.userPin);
    return pin != null && pin.length == 6;
  }

  Future<void> savePin(String pin) async {
    await _storageService.setValue<String>(StorageKeys.userPin, pin);
  }

  bool verifyPin(String pin) {
    final savedPin = _storageService.getValue<String>(StorageKeys.userPin);
    return savedPin != null && savedPin == pin;
  }

  Future<void> clearPin() async {
    await _storageService.remove(StorageKeys.userPin);
  }
}
