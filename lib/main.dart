import 'package:flutter/material.dart';
import 'package:renty_client/login/login.dart';
import 'package:renty_client/product_upload.dart';
import 'package:renty_client/api_client.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'post/mainBoard.dart';
import 'search/search.dart';
import 'mypage/logoutTest.dart';


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
        '/search': (context) => const SearchPage(),
        '/my': (context) => const LogoutScreen(),
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

  void _onItemTapped(int index) async {
    if (index == 1){
      Navigator.pushNamed(context, '/search'); // 돌아올 때까지 대기
    }
    else if (index == 2) { // 등록 탭 클릭 시
      if (await apiClient.hasTokenCookieLocally()) { // 로컬에 토큰 쿠키가 있는지 확인
        Navigator.pushNamed(context, '/product_upload'); // 등록 화면으로 이동
      }
      else {
        // TODO: 진짜 로그인 화면으로 변경할 것.
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    }else if(index == 4){
      Navigator.pushNamed(context, '/my');
    }else {
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
        child: ProductListPage(),
      ),
      bottomNavigationBar: BottomMenuBar(currentIndex: _currentIndex, onTap: _onItemTapped),
    );
  }
}

