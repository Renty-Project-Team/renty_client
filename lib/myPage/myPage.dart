import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/bottom_menu_bar.dart';
import 'package:renty_client/login/login.dart';
import 'package:renty_client/logo_app_ber.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/core/api_client.dart'; // API 클라이언트 추가
import 'package:renty_client/myPage/EditProfile/profileEdit.dart';
import 'package:renty_client/myPage/review/writeReview.dart';
import 'package:renty_client/myPage/EditProfile/userInfoEdit.dart'; // 회원 정보 수정 페이지 추가
import 'package:renty_client/myPage/CustomerService/appInfo.dart'; // 앱 정보 페이지 추가
import 'package:renty_client/myPage/CustomerService/noticeList.dart'; // 공지사항 페이지 추가가
import 'package:renty_client/myPage/CustomerService/faqPage.dart'; // FAQ 페이지 추가
import 'package:renty_client/myPage/CustomerService/inquiryChatbot.dart'; // 1:1 문의 챗봇 페이지 추가
import 'package:renty_client/myPage/incomePage.dart'; // 수익금 페이지 추가
import 'package:renty_client/myPage/MyPost/myPostBoard.dart';
import 'wish/wishList.dart';
import 'myRentPage/myRentOut.dart';
import 'myRentPageBuyer/myRentIn.dart';
import 'package:renty_client/myPage/review/receivedReviews.dart';
import 'package:renty_client/myPage/review/writtenReviews.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // API 클라이언트 인스턴스 추가
  final ApiClient _apiClient = ApiClient();

  // 프로필 데이터를 저장할 상태 변수 추가
  String _userName = '';
  String? _profileImageUrl;
  bool _isLoading = true; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // 프로필 데이터 로딩
  }

  // 프로필 데이터 로드 함수
  Future<void> _loadProfileData() async {
    try {
      final response = await _apiClient.client.get('/My/profile');

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _userName = data['userName'] ?? '';
          _profileImageUrl = data['profileImage'];
          _isLoading = false;
        });
      } else {
        // 에러 처리
        setState(() {
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      // DioException 처리
      if (e.response?.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
      print('프로필 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('프로필 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _currentIndex = 4; // 현재 선택된 인덱스

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
    {'title': '빌려준 제품목록', 'icon': Icons.arrow_forward_ios},
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

  // _handleItemClick 메서드 내에서 수정
  void _handleItemClick(String title) async {
    // 햅틱 피드백 추가
    HapticFeedback.lightImpact();

    if (title == '회원 정보 수정') {
      try {
        // 사용자 정보를 API에서 가져오기
        final response = await _apiClient.client.get('/My/profile');

        if (response.statusCode == 200) {
          final data = response.data;

          // UserInfoData 객체 생성
          final userInfo = UserInfoData(
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            phoneNumber: data['phoneNumber'] ?? '',
            userName: data['userName'] ?? '',
            accountNumber: data['accountNumber'],
          );

          // 회원 정보 수정 페이지로 이동
          final result = await Navigator.push<UserInfoData>(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoEditPage(initialInfo: userInfo),
            ),
          );

          // 정보가 업데이트되었으면 UI 갱신
          if (result != null) {
            // 필요한 경우 상태 업데이트
            setState(() {
              _userName = result.userName; // 닉네임이 변경된 경우 업데이트
            });

            // 프로필 페이지 새로고침
            _loadProfileData();
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원 정보를 불러오는데 실패했습니다.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
        print('회원 정보 로드 오류: $e');
      }
    } else if (title == '수익금') {
      // 수익금 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IncomePage()),
      );
    } else if (title == '내 대여 게시글') {
      // 내 대여 게시글 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyPostListPage()),
      );
    } else if (title == '앱 정보') {
      // 앱 정보 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AppInfoPage()),
      );
    } else if (title == '공지사항') {
      // 공지사항 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NoticeListPage()),
      );
    } else if (title == '자주 묻는 질문') {
      // FAQ 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FAQPage()),
      );
    } else if (title == '1:1 문의하기') {
      // 1:1 문의 챗봇 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InquiryChatBotPage()),
      );
      // 대여중인 제품목록 클릭 시 리뷰 작성 페이지로 이동
    } else if ((title == '찜 목록')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WishlistPage()),
      );
    } else if (title == '빌려준 제품목록') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyRentOutPage()),
      );
    } else if (title == '대여중인 제품목록') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyRentInPage()),
      );
    } else if (title == '받은 리뷰') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReceivedReviewsPage(currentUserName: _userName)),
      );
    } else if (title == '작성한 리뷰') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WrittenReviewsPage(currentUserName: _userName)),
      );
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
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == _currentIndex) return; // 이미 선택된 탭이면 아무것도 하지 않음
          await navigateBarAction(context, index);
        },
      ),
    );
  }

  // 프로필 섹션 - 업데이트
  Widget _buildProfileSection(ThemeData theme) {
    // 로딩 중일 때 표시할 위젯
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        // 프로필 이미지 - API에서 가져온 이미지가 있으면 표시
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey.withOpacity(0.2),
          child:
              _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      '${_apiClient.getDomain}${_profileImageUrl!}', // 서버 도메인 추가
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지 로드 실패 시 기본 아이콘 표시
                        print('프로필 이미지 로드 오류: $error');
                        return Icon(Icons.person, size: 32, color: Colors.grey);
                      },
                    ),
                  )
                  : Icon(Icons.person, size: 32, color: Colors.grey),
        ),
        const SizedBox(width: 16),

        // 사용자 닉네임 - API에서 가져온 이름 표시
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _userName,
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
              final initialProfile = {
                'nickname': _userName, // API에서 가져온 사용자 닉네임
                'imageUrl': _profileImageUrl, // API에서 가져온 이미지 URL
              };

              // 프로필 수정 페이지로 이동하면서 데이터 전달 (Map 타입으로 일관되게 유지)
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ProfileEditPage(initialProfile: initialProfile),
                ),
              );

              // 결과 데이터가 있으면 처리
              if (result != null) {
                setState(() {
                  _userName = result['userName'];
                  _profileImageUrl = result['profileImage'];
                });

                // 프로필 페이지 새로고침
                _loadProfileData();
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
                  color: Colors.grey[800],
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
