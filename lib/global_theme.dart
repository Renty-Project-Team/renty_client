import 'package:flutter/material.dart';

final Color primaryBrandColor = Colors.indigoAccent[700]!; // 또는 Colors.deepPurpleAccent;

ThemeData buildAppTheme() {
  // 기본 테마를 light로 설정하고 필요한 부분만 커스터마이징
  final ThemeData base = ThemeData.light();

  return base.copyWith(
    // 1. 색상 스키마 (ColorScheme - 최신 방식 권장)
    colorScheme: base.colorScheme.copyWith(
      primary: primaryBrandColor, // 주요 브랜드 색상 (로고, 활성 요소 등)
      secondary: primaryBrandColor, // 보조 색상 (FloatingActionButton 등, 여기서는 primary와 동일하게 설정)
      surface: Colors.white, // 카드, 다이얼로그 등 표면 색상
      background: Colors.white, // Scaffold 배경 색상
      onPrimary: Colors.white, // primary 색상 위에 표시될 콘텐츠 색상 (텍스트, 아이콘)
      onSecondary: Colors.white, // secondary 색상 위에 표시될 콘텐츠 색상
      onSurface: Colors.grey[850], // surface 색상 위에 표시될 콘텐츠 색상 (카드 위 텍스트 등) - 약간 진한 회색
      onBackground: Colors.grey[850], // background 색상 위에 표시될 콘텐츠 색상 (본문 텍스트 등)
      error: Colors.redAccent, // 오류 색상
      // brightness: Brightness.light, // 이미 light 테마 기반이므로 명시 안 해도 됨
    ),

    // 2. Scaffold 배경색 (ColorScheme.background와 일치시키는 것이 좋음)
    scaffoldBackgroundColor: Colors.white,

    // 3. AppBar 테마 (이미지 상단은 커스텀 위젯일 수 있지만, 표준 AppBar를 사용한다면)
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white, // 배경 흰색
      foregroundColor: Colors.grey[850], // 아이콘/텍스트 색상 (뒤로가기 버튼 등)
      elevation: 0, // 그림자 없음
      iconTheme: IconThemeData(color: Colors.grey[800]), // 앱바 아이콘 기본 색상
      titleTextStyle: TextStyle( // 앱바 제목 스타일
        color: Colors.grey[850],
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Noto Sans KR', // 사용할 폰트 패밀리 지정
      ),
    ),

    // 4. 텍스트 테마 (글꼴, 크기, 굵기 등)
    textTheme: base.textTheme.copyWith(
      // 상품 제목 등에 사용할 스타일 (예: titleLarge 또는 headlineSmall)
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: Colors.grey[850],
        fontWeight: FontWeight.bold,
        fontSize: 18,
        fontFamily: 'Noto Sans KR',
      ),
      // 가격 등에 사용할 스타일 (예: bodyLarge)
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: Colors.grey[850],
        fontWeight: FontWeight.bold,
        fontSize: 16,
        fontFamily: 'Noto Sans KR',
      ),
      // 보조 텍스트 등에 사용할 스타일 (예: bodyMedium)
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600], // 약간 연한 회색
        fontSize: 12,
        fontFamily: 'Noto Sans KR',
      ),
      // 하단 네비게이션 라벨 등에 사용할 스타일 (예: labelSmall)
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: Colors.grey[600],
        fontSize: 10,
        fontFamily: 'Noto Sans KR',
      ),
    ).apply( // 앱 전체 기본 텍스트/표시 색상 설정
      bodyColor: Colors.grey[850], // 대부분의 본문 텍스트 색상
      displayColor: Colors.grey[850], // Headline 등 큰 텍스트 색상
      fontFamily: 'Noto Sans KR', // 앱 전체 기본 폰트
    ),

    // 5. 카드 테마
    cardTheme: CardTheme(
      color: Colors.white, // 카드 배경색
      elevation: 2.0, // 약간의 그림자
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 카드 기본 마진
    ),

    // 6. 아이콘 테마 (전역)
    iconTheme: IconThemeData(
      color: Colors.grey[800], // 기본 아이콘 색상
      size: 24.0,
    ),

    // 7. 하단 네비게이션 바 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white, // 배경 흰색
      selectedItemColor: primaryBrandColor, // 선택된 아이템 색상 (주요 색상)
      unselectedItemColor: Colors.grey[600], // 선택되지 않은 아이템 색상 (연한 회색)
      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Noto Sans KR'),
      unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Noto Sans KR'),
      type: BottomNavigationBarType.fixed, // 아이템이 4개 이상일 때 고정 타입
      elevation: 0, // 그림자 없음
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // 8. 버튼 테마 등 추가 설정 가능
    // elevatedButtonTheme: ElevatedButtonThemeData(...)
    // textButtonTheme: TextButtonThemeData(...)

    // 9. 시각적 밀도 (플랫폼 적응형)
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // 10. 스플래시/하이라이트 효과 색상 (선택 사항)
    splashColor: primaryBrandColor.withAlpha(50),
    highlightColor: primaryBrandColor.withAlpha(30),
    dividerColor: Colors.grey[300],
  );
}