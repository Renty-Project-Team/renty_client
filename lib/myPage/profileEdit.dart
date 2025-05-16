import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 피커 추가
import 'dart:io'; // File 클래스 사용
import 'dart:math'; // sin 함수 사용
import 'package:dio/dio.dart'; // Dio import 추가
import 'package:renty_client/core/api_client.dart'; // API 클라이언트 import 추가

// 프로필 데이터 모델 클래스
class ProfileData {
  final String nickname;
  final String? imageUrl; // 서버에 저장된 이미지 URL

  ProfileData({required this.nickname, this.imageUrl});
}

class ProfileEditPage extends StatefulWidget {
  // 생성자에서 사용자 프로필 데이터 받기
  final ProfileData initialProfile;

  const ProfileEditPage({Key? key, required this.initialProfile})
    : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage>
    with SingleTickerProviderStateMixin {
  // 프로필 정보 변수들
  late String _originalNickname;
  late TextEditingController _nicknameController;
  bool _hasChanges = false;

  // 입력란 에러 상태 관리 변수
  bool _isNicknameError = false;

  // 애니메이션 컨트롤러 추가
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // 이미지 관련 변수
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _originalImageUrl;

  @override
  void initState() {
    super.initState();
    // 초기 프로필 데이터 설정
    _originalNickname = widget.initialProfile.nickname;
    _originalImageUrl = widget.initialProfile.imageUrl;
    _nicknameController = TextEditingController(text: _originalNickname);

    // 텍스트 변경 감지 리스너 추가
    _nicknameController.addListener(_checkChanges);

    // 애니메이션 컨트롤러 초기화
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 좌우 흔들림 애니메이션 설정
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
      .chain(CurveTween(curve: ShakeCurve()))
      .animate(_shakeController)..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_checkChanges);
    _nicknameController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // 변경 사항이 있는지 확인하는 함수
  void _checkChanges() {
    setState(() {
      _hasChanges =
          _nicknameController.text != _originalNickname ||
          _selectedImage != null;

      // 텍스트가 입력되면 에러 상태 제거
      if (_nicknameController.text.isNotEmpty) {
        _isNicknameError = false;
      }
    });
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e')));
    }
  }

  // 뒤로가기 처리 함수
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    // 채팅방 삭제 스타일과 일치하는 다이얼로그
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '저장되지 않은 변경사항',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '변경사항이 저장되지 않았습니다. 그래도 나가시겠습니까?',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B70FD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            '나가기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  // 프로필 저장 함수 (API 호출 부분 구현)
  void _saveProfile() async {
    // 닉네임 공백 검증
    if (_nicknameController.text.trim().isEmpty) {
      setState(() {
        _isNicknameError = true;
      });

      // 흔들림 애니메이션 실행
      _shakeController.forward();

      // 햅틱 피드백 추가
      HapticFeedback.mediumImpact();

      return;
    }

    // 햅틱 피드백 추가
    HapticFeedback.lightImpact();

    try {
      // 저장 중임을 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 정보를 저장 중입니다...')));

      // API 요청을 위한 데이터 준비
      String nickname = _nicknameController.text.trim();

      // API 클라이언트 인스턴스 생성
      final ApiClient apiClient = ApiClient();
      Map<String, dynamic> requestData = {"userName": nickname};

      // 이미지 업로드와 함께 프로필 정보 업데이트
      if (_selectedImage != null) {
        final imageFile = File(_selectedImage!.path);

        // FormData 생성
        final formData = FormData.fromMap({
          "userName": nickname,
          "profileImage": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        // PUT 또는 PATCH 요청 (API 명세에 따라 선택)
        final response = await apiClient.client.put(
          '/my/profile',
          data: formData,
        );

        print('API 응답: ${response.statusCode} - ${response.data}');
      }
      // 이미지 없이 닉네임만 업데이트
      else {
        final response = await apiClient.client.put(
          '/my/profile',
          data: {"userName": nickname},
        );

        print('API 응답: ${response.statusCode} - ${response.data}');
      }

      // 성공 메시지
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 저장되었습니다')));

      // 수정된 데이터를 이전 화면으로 반환
      final updatedProfile = ProfileData(
        nickname: nickname,
        imageUrl: _selectedImage?.path ?? _originalImageUrl,
      );

      // 이전 화면으로 결과 데이터와 함께 돌아가기
      Navigator.pop(context, updatedProfile);
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 저장 중 오류가 발생했습니다: $e')));
      print('프로필 저장 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope로 뒤로가기 동작 감지
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        // 커스텀 앱바 구현
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // 기본 뒤로가기 버튼 제거
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87, size: 22),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          centerTitle: false,
          title: Text(
            '프로필 수정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                '저장',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // 프로필 이미지 및 카메라 아이콘
              Center(
                child: Stack(
                  children: [
                    // 프로필 이미지
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: _profileImageWidget(),
                    ),

                    // 카메라 아이콘 (우측 하단에 배치)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickImage, // 이미지 선택 함수 연결
                            customBorder: const CircleBorder(),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // 닉네임 라벨
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '닉네임',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 닉네임 입력 필드 - 애니메이션 적용
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 입력 필드
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _isNicknameError
                                  ? Colors.red
                                  : Colors.grey.withOpacity(0.3),
                          width: _isNicknameError ? 1.5 : 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          hintText: '닉네임을 입력하세요',
                          hintStyle: TextStyle(
                            color: Colors.grey.withOpacity(0.4),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    // 에러 메시지
                    if (_isNicknameError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                        child: Text(
                          '닉네임을 입력해주세요',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 프로필 이미지 위젯 생성 함수
  Widget _profileImageWidget() {
    // 선택된 새 이미지가 있는 경우
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.file(
          File(_selectedImage!.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    // 기존 이미지 URL이 있는 경우
    else if (_originalImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          _originalImageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          // 로딩 중 표시
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          // 에러 발생 시 기본 아이콘
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.person, size: 64, color: Colors.white),
            );
          },
        ),
      );
    }
    // 이미지 없는 경우 기본 아이콘
    else {
      return const Center(
        child: Icon(Icons.person, size: 64, color: Colors.white),
      );
    }
  }
}

// 흔들림 커브 정의
class ShakeCurve extends Curve {
  @override
  double transform(double t) {
    return sin(t * 4 * 3.14) * 0.3;
  }
}
