import 'package:get/get.dart';
import 'package:stategetx/services/storage_service.dart';

class PrivacyService extends GetxService {
  static const String _storageKey = 'privacy_hide_amounts';

  late final StorageService _storageService;

  final RxBool hideAmounts = false.obs;

  Future<PrivacyService> init() async {
    _storageService = Get.find<StorageService>();
    hideAmounts.value =
        _storageService.getValue<bool>(_storageKey) ?? false;
    return this;
  }

  Future<void> toggleAmountVisibility() async {
    hideAmounts.value = !hideAmounts.value;
    await _storageService.setValue<bool>(_storageKey, hideAmounts.value);
  }
}
