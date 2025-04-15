import 'package:flutter/material.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'login.dart';
import 'mainBoard.dart';
import 'api_client.dart';
// import 'package:http/http.dart' as http;

final ApiClient apiClient = ApiClient();

void main() async{
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
        '/': (context) => const LoginPage(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(showBackButton: false),
      body: Center(
        child: ProductListPage(),
      ),
      bottomNavigationBar: BottomMenuBar(currentIndex: 1),
    );
  }
}


