import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageKeys {
  static const String userToken = "user_token";
  static const String themeMode = "theme_mode";
}

class StorageService extends GetxController {
  late final SharedPreferences _preferences;

  Future<StorageService> init() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> setValue<T>(String key, T value) async {
    try {
      if (value is String) {
        return await _preferences.setString(key, value);
      } else if (value is int) {
        return await _preferences.setInt(key, value);
      } else if (value is bool) {
        return await _preferences.setBool(key, value);
      } else if (value is List<String>) {
        return await _preferences.setStringList(key, value);
      } else {
        throw ArgumentError('Unsupported value type: ${value.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error occurred while setting value for key $key: $e');
      return false;
    }
  }

  T? getValue<T>(String key) {
    try {
      if (T == String) {
        return _preferences.getString(key) as T?;
      } else if (T == int) {
        return _preferences.getInt(key) as T?;
      } else if (T == bool) {
        return _preferences.getBool(key) as T?;
      } else if (T == List<String>) {
        return _preferences.getStringList(key) as T?;
      } else {
        throw ArgumentError('Unsupported value type: $T');
      }
    } catch (e) {
      debugPrint('Error occurred while getting value for key $key: $e');
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _preferences.remove(key);
    } catch (e) {
      debugPrint('Error occurred while removing key $key: $e');
      return false;
    }
  }

  bool hasKey(String key) {
    return _preferences.containsKey(key);
  }

  T getCalueOrDefualy<T>(String key, T defaultValue) {
    try {
      if (T == String) {
        return _preferences.getString(key) as T? ?? defaultValue;
      } else if (T == int) {
        return _preferences.getInt(key) as T? ?? defaultValue;
      } else if (T == bool) {
        return _preferences.getBool(key) as T? ?? defaultValue;
      } else if (T == List<String>) {
        return _preferences.getStringList(key) as T? ?? defaultValue;
      } else {
        throw ArgumentError('Unsupported value type: $T');
      }
    } catch (e) {
      debugPrint('Error occurred while getting value for key $key: $e');
      return defaultValue;
    }
  }

  Map<String, dynamic> getAllValues() {
    final keys = _preferences.getKeys();
    final map = <String, dynamic>{};
    for (var key in keys) {
      map[key] = _preferences.get(key);
    }
    return map;
  }
}
