import 'package:flutter/material.dart';


class LogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  const LogoAppBar({super.key, this.showBackButton = true}); // 기본값 true

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color logoColor = theme.colorScheme.primary; // 로고 색상 (브랜드 색상)

    Widget logoWidget = Text(
      'ㅂㄹㅂ', // 앱 이름 또는 로고 텍스트
      style: TextStyle(
        color: logoColor,
        fontFamily: 'Hakgyoansim',
        fontSize: 32, // 적절한 크기로 조절
        fontWeight: FontWeight.bold, // 굵게
        letterSpacing: -5.0, // 글자 간격 조절
        // fontFamily: 'YourBrandFont', // 전용 폰트가 있다면 지정
      ),
    );

    return AppBar(
      // --- 레이아웃 및 요소 배치 ---
      automaticallyImplyLeading: showBackButton,
      title: logoWidget, // 로고를 title 영역에 배치
      centerTitle: false, // title을 왼쪽 정렬 (기본값은 플랫폼 따라 다름)
      titleSpacing: NavigationToolbar.kMiddleSpacing, // 제목과 좌우 요소 간 간격 (기본값 사용 또는 조절)

      actions: [ // 오른쪽에 배치될 위젯들
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: 30), // 설정 아이콘 (외곽선)
          onPressed: () {}, // 콜백 함수 (지금은 비워둠)
          tooltip: '설정', // 접근성을 위한 툴팁
        ),
        const SizedBox(width: 8), // 오른쪽 끝과의 간격 조절 (선택 사항)
      ],

      // --- 스타일링 ---
      backgroundColor: Colors.transparent, // 배경색 (투명)
      elevation: 0, // 그림자 제거
      // foregroundColor: ... // AppBar 내 아이콘/텍스트 기본 색상 (필요시 설정)
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50.0);
}