import 'package:get/instance_manager.dart';
import 'package:stategetx/modules/calendar/calendar_controller.dart';
import 'package:stategetx/modules/credit_cards/credit_cards_controller.dart';
import 'package:stategetx/modules/dashboard/dashboard_controller.dart';
import 'package:stategetx/modules/home/home_controller.dart';
import 'package:stategetx/modules/investments/investments_controller.dart';
import 'package:stategetx/modules/profile/progile_controller.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<CalendarController>(() => CalendarController());
    Get.lazyPut<CreditCardsController>(() => CreditCardsController());
    Get.lazyPut<InvestmentsController>(() => InvestmentsController());
  }
}
