import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/bottom_menu_bar.dart';
import 'package:renty_client/logo_app_ber.dart'; // 로고 앱바 추가
import 'package:renty_client/main.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/myPage/profileEdit.dart';
import 'package:renty_client/myPage/writeReview.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 회원 기능 항목들
  final List<Map<String, dynamic>> memberFunctions = [
    {'title': '회원 정보 수정', 'icon': Icons.arrow_forward_ios},
    {'title': '수익금', 'icon': Icons.arrow_forward_ios},
    {'title': '내 대여 게시글', 'icon': Icons.arrow_forward_ios},
    {'title': '결제완료 물품', 'icon': Icons.arrow_forward_ios},
  ];

  // 내 활동 항목들
  final List<Map<String, dynamic>> myActivities = [
    {'title': '찜 목록', 'icon': Icons.arrow_forward_ios},
    {'title': '대여중인 제품목록', 'icon': Icons.arrow_forward_ios},
    {'title': '받은 리뷰', 'icon': Icons.arrow_forward_ios},
    {'title': '작성한 리뷰', 'icon': Icons.arrow_forward_ios},
  ];

  // 고객지원 항목
  final List<Map<String, dynamic>> customerSupport = [
    {'title': '자주 묻는 질문', 'icon': Icons.arrow_forward_ios},
    {'title': '1:1 문의하기', 'icon': Icons.arrow_forward_ios},
    {'title': '공지사항', 'icon': Icons.arrow_forward_ios},
    {'title': '앱 정보', 'icon': Icons.arrow_forward_ios},
  ];

  // 항목 클릭 처리 함수
  void _handleItemClick(String title) {
    // 햅틱 피드백 추가
    HapticFeedback.lightImpact();

    // 대여중인 제품목록 클릭 시 리뷰 작성 페이지로 이동
    if (title == '대여중인 제품목록') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReviewWritePage(
                productTitle: '예제 상품 입니다',
                productImageUrl: null, // 이미지 URL이 아직 없음
                rentalDate: DateTime.now().subtract(
                  const Duration(days: 7),
                ), // 일주일 전 대여 종료
                lessorName: '테스트계정_2',
              ),
        ),
      ).then((value) {
        // 리뷰 작성 후 돌아왔을 때 처리 (선택사항)
        if (value == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('리뷰가 성공적으로 등록되었습니다')));
        }
      });
    } else {
      // 다른 항목들은 기존과 같이 처리
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('디버깅: $title 페이지로 이동')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      // LogoAppBar 사용하여 로고와 뒤로가기 버튼 표시
      appBar: LogoAppBar(showBackButton: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 영역 (박스)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: _buildProfileSection(theme),
              ),

              const SizedBox(height: 16),

              // 회원 기능 섹션 (박스)
              _buildSectionBox('회원 기능', memberFunctions, theme),

              const SizedBox(height: 16),

              // 내 활동 섹션 (박스)
              _buildSectionBox('내 활동', myActivities, theme),

              const SizedBox(height: 16),

              // 고객지원 섹션 (박스)
              _buildSectionBox('고객지원', customerSupport, theme),

              const SizedBox(height: 16),

              // 로그아웃 버튼 (박스)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // 햅틱 피드백 추가
                      HapticFeedback.mediumImpact();
                      await TokenManager.deleteToken();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    // 클릭 효과 색상을 연한 회색으로 변경 (로그아웃은 약간 빨간색 유지)
                    splashColor: Colors.grey.withOpacity(0.25),
                    highlightColor: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '로그아웃',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 하단 여백
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: 4,
        onTap: (index) async {
          await navigateBarAction(context, index);
        },
      ),
    );
  }

  // 프로필 섹션
  Widget _buildProfileSection(ThemeData theme) {
    return Row(
      children: [
        // 프로필 이미지
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey.withOpacity(0.2),
          child: Icon(Icons.person, size: 32, color: Colors.grey),
        ),
        const SizedBox(width: 16),

        // 사용자 닉네임
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '테스트계정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // 프로필 수정 버튼 (클릭 피드백 개선)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // 현재 사용자 프로필 데이터
              ProfileData userProfile = ProfileData(
                nickname: "테스트계정", // 실제로는 서버에서 가져온 사용자 닉네임
                imageUrl: null, // 실제로는 서버에서 가져온 이미지 URL
              );

              // 프로필 수정 페이지로 이동하면서 데이터 전달
              final ProfileData? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfileEditPage(initialProfile: userProfile),
                ),
              );

              // 결과 데이터가 있으면 처리 (화면 갱신 등)
              if (result != null) {
                // TODO: 화면 갱신 또는 상태 업데이트
                setState(() {
                  // 상태 업데이트 코드
                });

                // 업데이트 성공 메시지
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('프로필이 업데이트되었습니다')));
              }
            },
            // 클릭 효과 색상을 연한 회색으로 변경
            splashColor: Colors.grey.withOpacity(0.3),
            highlightColor: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '프로필 수정',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800], // 테마 색상에서 진한 회색으로 변경
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 섹션 박스 위젯
  Widget _buildSectionBox(
    String title,
    List<Map<String, dynamic>> items,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),

          // 항목 리스트
          ...items
              .map((item) => _buildListItem(item['title'], item['icon'], theme))
              .toList(),

          // 마지막 항목에 padding 추가
          SizedBox(height: 8),
        ],
      ),
    );
  }

  // 리스트 아이템 위젯 (클릭 피드백 개선)
  Widget _buildListItem(String title, IconData icon, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemClick(title),
        // 클릭 효과 색상을 연한 회색으로 변경하고 효과를 더 강하게
        splashColor: Colors.grey.withOpacity(0.25),
        highlightColor: Colors.grey.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              // 화살표 아이콘
              Icon(icon, size: 18, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
