import 'package:get/state_manager.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  void setLoading(bool value) => _isLoading.value = value;
}
