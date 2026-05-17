import 'package:stategetx/modules/home/home_bindings.dart';
import 'package:stategetx/modules/home/home_pages.dart';
import 'package:stategetx/modules/login/login_bindings.dart';
import 'package:stategetx/modules/login/login_page.dart';
import 'package:stategetx/modules/pin/pin_bindings.dart';
import 'package:stategetx/modules/pin/pin_page.dart';
import 'package:stategetx/modules/splash/splash_bindings.dart';
import 'package:stategetx/modules/splash/splash_page.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/transaction/transaction_bindings.dart';
import 'package:stategetx/modules/transaction/transaction_page.dart';

abstract class AppRoutes {
  static const initial = splash;
  static const splash = '/splash';
  static const login = '/login';
  static const pin = '/pin';
  static const home = '/home';
  static const profile = '/profil';
  static const transaction = '/transaction';
}

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashPage(),
      binding: SplashBindings(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: LoginBindings(),
    ),
    GetPage(
      name: AppRoutes.pin,
      page: () => const PinPage(),
      binding: PinBindings(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBindings(),
    ),
    GetPage(
      name: AppRoutes.transaction,
      page: () => TransactionPage(),
      binding: TransactionBindings(),
    ),
  ];
}
