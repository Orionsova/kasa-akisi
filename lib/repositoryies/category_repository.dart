import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/app_category.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/storage_service.dart';

class CategoryRepository extends GetxService {
  late final ApiService _apiService;
  late final StorageService _storageService;

  static const String _categoriesKey = 'local_categories';

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
  }

  Future<List<AppCategory>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final remoteCategories = _parseCategories(response.data);
        final mergedCategories = _mergeCategories(
          _defaultCategories(),
          remoteCategories,
        );
        await _saveLocalCategories(mergedCategories);
        return mergedCategories;
      }
    } catch (_) {
      final localCategories = await _getLocalCategories();
      return _mergeCategories(_defaultCategories(), localCategories);
    }

    final localCategories = await _getLocalCategories();
    return _mergeCategories(_defaultCategories(), localCategories);
  }

  Future<AppCategory> createCategory(AppCategory category) async {
    try {
      final response = await _apiService.post(
        ApiConstants.categories,
        data: category.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdCategory = AppCategory.fromJson(
          Map<String, dynamic>.from(response.data['category'] ?? response.data),
        );
        await _storeCategoryLocally(createdCategory);
        return createdCategory;
      }
    } catch (_) {
      final localCategory = category.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );
      await _storeCategoryLocally(localCategory);
      return localCategory;
    }

    throw Exception('Failed to create category');
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.categories}/$id',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete category');
      }
    } catch (_) {
      // Keep local state consistent even when API is unavailable.
    }

    final localCategories = await _getLocalCategories();
    localCategories.removeWhere((category) => category.id == id);
    await _saveLocalCategories(localCategories);
  }

  List<AppCategory> _parseCategories(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((json) => AppCategory.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final categoryList = data['categories'] ?? data['data'];
      if (categoryList is List) {
        return categoryList
            .whereType<Map>()
            .map(
              (json) => AppCategory.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }
    }

    return [];
  }

  List<AppCategory> _defaultCategories() {
    final now = DateTime.now();
    return [
      AppCategory(
        id: 'system-expense-food',
        name: 'Yiyecek',
        type: 'expense',
        isSystem: true,
        createdAt: now,
      ),
      AppCategory(
        id: 'system-expense-transport',
        name: 'Ulaşım',
        type: 'expense',
        isSystem: true,
        createdAt: now,
      ),
      AppCategory(
        id: 'system-expense-bills',
        name: 'Faturalar',
        type: 'expense',
        isSystem: true,
        createdAt: now,
      ),
      AppCategory(
        id: 'system-income-salary',
        name: 'Maaş',
        type: 'income',
        isSystem: true,
        createdAt: now,
      ),
      AppCategory(
        id: 'system-income-freelance',
        name: 'Freelance',
        type: 'income',
        isSystem: true,
        createdAt: now,
      ),
    ];
  }

  Future<List<AppCategory>> _getLocalCategories() async {
    final rawCategories = _storageService.getValue<String>(_categoriesKey);
    if (rawCategories == null || rawCategories.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawCategories);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((json) => AppCategory.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _saveLocalCategories(List<AppCategory> categories) async {
    final encoded = jsonEncode(
      categories.map((category) => category.toJson()).toList(),
    );
    await _storageService.setValue<String>(_categoriesKey, encoded);
  }

  Future<void> _storeCategoryLocally(AppCategory category) async {
    final localCategories = await _getLocalCategories();
    final mergedCategories = _mergeCategories(localCategories, [category]);
    await _saveLocalCategories(mergedCategories);
  }

  List<AppCategory> _mergeCategories(
    List<AppCategory> base,
    List<AppCategory> incoming,
  ) {
    final merged = <String, AppCategory>{};

    for (final category in [...base, ...incoming]) {
      final key =
          '${category.type ?? ''}-${(category.name ?? '').trim().toLowerCase()}';
      if (key == '-') {
        continue;
      }
      merged[key] = category;
    }

    final categories = merged.values.toList()
      ..sort((a, b) {
        final typeCompare = (a.type ?? '').compareTo(b.type ?? '');
        if (typeCompare != 0) {
          return typeCompare;
        }
        return (a.name ?? '').compareTo(b.name ?? '');
      });

    return categories;
  }
}
