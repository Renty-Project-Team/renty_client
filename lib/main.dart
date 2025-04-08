import 'package:flutter/material.dart';
import 'package:renty_client/api_client.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';


final ApiClient apiClient = ApiClient();

void main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 실행 전 ApiClient 초기화 (비동기 작업 완료 기다림)
  await apiClient.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Renty',
      theme: buildAppTheme(), // 글로벌 테마 적용
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(),
      body: Center(
        child: Text("홈 화면"),
      ),
      bottomNavigationBar: BottomMenuBar(currentIndex: 1),
    );
  }
}

