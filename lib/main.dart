import 'package:flutter/material.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'mainBoard.dart';
// import 'package:http/http.dart' as http;

void main() {
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
        child: ProductListPage()
      ),
      bottomNavigationBar: BottomMenuBar(currentIndex: 1),
    );
  }
}


