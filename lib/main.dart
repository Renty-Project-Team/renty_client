import 'package:flutter/material.dart';
import 'package:renty_client/Example/dummy_my_page.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/login/login.dart';
import 'package:renty_client/product_upload.dart';
import 'package:renty_client/core/api_client.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'myPage/myPageUI.dart';
import 'post/mainBoard.dart';
import 'search/search.dart';
import 'chat/chat_list.dart';

final ApiClient apiClient = ApiClient();

void main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 실행 전 ApiClient 초기화 (비동기 작업 완료 기다림)
  await apiClient.initialize();
  runApp(const MyApp());
}

Future<void> navigateBarAction(BuildContext context, int index) async {
  if (index == 0) {
    // 홈 탭 클릭 시
    Navigator.pushNamed(context, '/');
  } else if (index == 1) {
    Navigator.pushNamed(context, '/search');
  } else if (index == 2) {
    // 등록 탭 클릭 시
    if (await TokenManager.getToken() != null) {
      // 로컬에 토큰 쿠키가 있는지 확인
      Navigator.pushNamed(context, '/product_upload'); // 등록 화면으로 이동
    } else {
      Navigator.pushNamed(context, '/login'); // 로그인 화면으로 이동
    }
  } else if (index == 3) {
    // 채팅 탭 클릭 시
    if (await TokenManager.getToken() != null) {
      // 로컬에 토큰이 있는지 확인
      Navigator.pushNamed(context, '/chat_list'); // 채팅 화면으로 이동
    } else {
      Navigator.pushNamed(context, '/login'); // 로그인 화면으로 이동
    }
  } else if (index == 4) {
    // my 탭 클릭 시
    // Navigator.pushNamed(context, '/mypage'); // 등록 화면으로 이동
    if (await TokenManager.getToken() != null) {
      // 로컬에 토큰 쿠키가 있는지 확인
      Navigator.pushNamed(context, '/mypage'); // 등록 화면으로 이동
    } else {
      Navigator.pushNamed(context, '/login'); // 로그인 화면으로 이동
    }
  }
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
        '/chat_list': (context) => const ChatListPage(), // 채팅 목록 페이지
        '/login': (context) => const LoginPage(),
        '/mypage': (context) => const ProfilePage(), // 더미 마이페이지
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
    if (index == _currentIndex) return; // 이미 선택된 탭이면 아무것도 하지 않음
    await navigateBarAction(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(),
      body: Center(child: ProductListPage()),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
