import 'package:flutter/material.dart';
import 'package:renty_client/product_upload.dart';
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
        '/product_upload': (context) => const ProductUpload(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 현재 선택된 인덱스

  void _onItemTapped(int index) {
    if (index == 2) { // 등록 탭 클릭 시
      Navigator.pushNamed(context, '/product_upload'); // 등록 화면으로 이동
      // 등록 탭은 선택 상태를 바꾸지 않음 (선택적)
    } else {
      setState(() { // 상태 변경 및 UI 갱신 요청
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(),
      body: Center(
        child: Text("홈 화면"),
      ),
      bottomNavigationBar: BottomMenuBar(currentIndex: _currentIndex, onTap: _onItemTapped),
    );
  }
}

