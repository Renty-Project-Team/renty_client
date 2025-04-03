import 'package:flutter/material.dart';

class BottomMenuBar extends StatelessWidget {
  final int currentIndex; // 현재 선택된 인덱스
  // final ValueChanged<int> onTap; // 탭했을 때 호출될 콜백 함수

  const BottomMenuBar({
    super.key,
    required this.currentIndex,
    // required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 
    const iconSize = 28.0; // 아이콘 크기 설정

    return Container(
          // Container로 BottomNavigationBar를 감쌉니다.
          decoration: BoxDecoration(
            // BoxDecoration을 사용하여 위쪽 테두리를 정의합니다.
            border: Border(
              top: BorderSide(
                color: theme.dividerColor, // null 체크 추가
                width: 1.5,
              ),
            ),
            // 필요하다면 Container의 배경색을 지정할 수 있지만,
            // 보통 BottomNavigationBar 자체의 배경색을 사용하므로 지정하지 않거나 투명하게 둡니다.
            // color: Colors.white,
          ),
          child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: iconSize),
              label: "홈", 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: iconSize),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: iconSize),
              label: '등록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined, size: iconSize),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined, size: iconSize),
              label: 'My',
            ),
          ],
          currentIndex: 0,
          onTap: (index) {} // Handle tap here if needed
        ),
      );
  }

  
}