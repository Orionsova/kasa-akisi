import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stategetx/main.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/storage_service.dart';
import 'package:stategetx/services/theme_service.dart';

class FakeAuthService extends AuthService {
  @override
  Future<bool> isAuthenticated() async => false;
}

void main() {
  testWidgets('MyApp renders splash screen shell', (WidgetTester tester) async {
    Get.testMode = true;
    Get.put(ThemeService());
    Get.put(StorageService());
    Get.put(ApiService());
    Get.put<AuthService>(FakeAuthService());

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
