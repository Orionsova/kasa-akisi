import 'package:get/instance_manager.dart';
import 'package:stategetx/repositoryies/category_repository.dart';
import 'package:stategetx/repositoryies/credit_card_repository.dart';
import 'package:stategetx/repositoryies/investment_repository.dart';
import 'package:stategetx/repositoryies/recurring_transaction_repository.dart';
import 'package:stategetx/repositoryies/transaction_repository.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/privacy_service.dart';
import 'package:stategetx/services/storage_service.dart';
import 'package:stategetx/services/theme_service.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    await Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.init();
      return service;
    });

    await Get.putAsync<ThemeService>(() async {
      final service = ThemeService();
      await service.init();
      return service;
    });

    await Get.putAsync<ApiService>(() async {
      final service = ApiService();
      await service.init();
      return service;
    });

    await Get.putAsync<AuthService>(() async {
      final service = AuthService();
      await service.init();
      return service;
    });

    await Get.putAsync<PrivacyService>(() async {
      final service = PrivacyService();
      await service.init();
      return service;
    });

    Get.put(CreditCardRepository());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    Get.put(RecurringTransactionRepository());
    Get.put(InvestmentRepository());
  }

  static Future<void> initServices() async {
    await AppBindings().dependencies();
  }
}
