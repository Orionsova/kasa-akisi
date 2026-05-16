import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/services/storage_service.dart';

class ThemeService extends GetxService {
  late final StorageService _storageService;
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  Future<ThemeService> init() async {
    _storageService = Get.find<StorageService>();
    loadThemeMode();
    return this;
  }

  void loadThemeMode() {
    final savedTheme = _storageService.getValue<String>(StorageKeys.themeMode);
    if (savedTheme != null) {
      _isDarkMode.value = savedTheme == 'dark';
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode.value = brightness == Brightness.dark;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    await _storageService.setValue<String>(
      StorageKeys.themeMode,
      _isDarkMode.value ? 'dark' : 'light',
    );
  }
}
