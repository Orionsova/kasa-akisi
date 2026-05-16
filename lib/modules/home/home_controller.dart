import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';

class HomeController extends BaseController {
  final currentIndex = 0.obs;
  final titles = const [
    'Kasa Akışı',
    'Takvim',
    'Kredi Kartları',
    'Yatırımlar',
    'Profil',
  ];
  final subtitles = const [
    'Gelir ve giderlerini tek yerden yönet',
    'Gelecek para akışını önceden gör',
    'Kart borçlarını, limitlerini ve taksitlerini izle',
    'Portföyünü ve yatırım performansını takip et',
    'Hesap ve görünüm ayarları',
  ];

  void changePage(int index) {
    currentIndex.value = index;
  }

  Future<void> cikisYap() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> goToTransaction() async {
    await Get.toNamed(AppRoutes.transaction);
  }
}
