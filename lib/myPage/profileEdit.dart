import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 피커 추가
import 'dart:io'; // File 클래스 사용
import 'dart:math'; // sin 함수 사용
import 'package:dio/dio.dart'; // Dio import 추가
import 'package:renty_client/core/api_client.dart'; // API 클라이언트 import 추가

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;

  const ProfileEditPage({Key? key, this.initialProfile}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage>
    with SingleTickerProviderStateMixin {
  // 프로필 정보 변수들
  late TextEditingController _nicknameController;
  final ApiClient apiClient = ApiClient(); // ApiClient 인스턴스 추가
  bool _hasChanges = false;
  bool _isSaving = false; // 저장 상태 추가

  // 입력란 에러 상태 관리 변수
  bool _isNicknameError = false;

  // 애니메이션 컨트롤러 추가
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // 이미지 관련 변수
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _originalImageUrl;
  bool _isProfileImageDeleted = false; // 이미지 삭제 플래그 추가

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();

    // 초기 데이터 설정
    if (widget.initialProfile != null) {
      _nicknameController.text = widget.initialProfile!['nickname'] ?? '';
      _originalImageUrl = widget.initialProfile!['imageUrl'];
    }

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
          _nicknameController.text != widget.initialProfile?['nickname'] ||
          _selectedImage != null ||
          _isProfileImageDeleted;

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

  // 이미지 삭제 함수 추가
  void _deleteProfileImage() {
    setState(() {
      _selectedImage = null;
      _isProfileImageDeleted = true;
    });
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

  // 프로필 저장 함수 수정
  void _saveProfile() async {
    // 닉네임 공백 검증 (기존 코드 유지)
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

    setState(() {
      _isSaving = true;
    });

    try {
      // API 클라이언트 인스턴스 생성
      final ApiClient apiClient = ApiClient();

      // 현재 사용자 정보 가져오기
      final userResponse = await apiClient.client.get('/My/profile');
      final userData = userResponse.data;

      // FormData 생성을 위한 맵 준비
      final Map<String, dynamic> formFields = {
        "Email": userData['email'] ?? '',
        "Name": userData['name'] ?? '',
        "UserName": _nicknameController.text.trim(),
        "PhoneNumber": userData['phoneNumber'] ?? '',
      };

      // 계좌번호가 있으면 추가
      if (userData['accountNumber'] != null) {
        formFields["AccountNumber"] = userData['accountNumber'];
      }

      // 이미지 처리 로직
      String imageAction = "None"; // 기본값

      if (_selectedImage != null) {
        // 새 이미지가 선택됨 -> Upload
        imageAction = "Upload";
        formFields["ProfileImage"] = await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: 'profile_image.jpg',
        );
      } else if (_isProfileImageDeleted) {
        // 이미지 삭제 처리 추가
        imageAction = "Delete";
      }

      // ImageAction 필드 추가
      formFields["ImageAction"] = imageAction;

      // FormData 생성
      final formData = FormData.fromMap(formFields);

      // PUT 요청 실행
      final response = await apiClient.client.put(
        '/My/profile',
        data: formData,
      );

      // setState 전에 mounted 체크 추가
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (response.statusCode == 200) {
        // JWT 토큰 저장 추가
        Map<String, dynamic> jsonData = response.data;
        final String accessToken = jsonData['token'];
        await TokenManager.saveToken(accessToken);

        // mounted 확인 후 UI 업데이트
        if (!mounted) return;

        // 성공 메시지 (컨텍스트 사용 전 mounted 확인)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 저장되었습니다')));

        // 안전한 Navigation
        if (mounted) {
          Navigator.of(context).pop({
            'userName': _nicknameController.text.trim(),
            'profileImage':
                _selectedImage?.path ??
                (_isProfileImageDeleted ? null : _originalImageUrl),
          });
        }
      } else {
        if (mounted) _handleApiError('프로필 저장에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
      _handleApiError(e);
    }
  }

  // 오류 처리 메서드 수정
  void _handleApiError(dynamic error) {
    String errorMessage = '프로필 저장 중 오류가 발생했습니다';

    print('에러 디버그: $error');

    // DioError 처리
    if (error is DioException && error.response?.statusCode == 400) {
      final errors = error.response?.data?[''];

      if (errors is List && errors.isNotEmpty) {
        for (var err in errors) {
          if (err is String) {
            if (err.contains("Username") && err.contains("already taken")) {
              errorMessage = '이미 사용 중인 닉네임입니다.';
              break;
            } else if (err.contains("Email") && err.contains("already taken")) {
              errorMessage = '이미 사용 중인 이메일입니다.';
              break;
            }
          }
        }
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));

    // 자세한 에러 로그 출력
    print('프로필 저장 오류: $error');
    if (error is DioException && error.response != null) {
      print('에러 상태 코드: ${error.response?.statusCode}');
      print('에러 응답 데이터: ${error.response?.data}');
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

              // 프로필 이미지 섹션 (UI build 메서드 내)
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              _isProfileImageDeleted
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                  : _selectedImage != null
                                  ? Image.file(
                                    File(_selectedImage!.path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                  : _originalImageUrl != null
                                  ? Image.network(
                                    // 서버 도메인과 이미지 경로를 결합
                                    '${ApiClient().getDomain}${_originalImageUrl!}',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                        '프로필 이미지 로드 오류: $error (URL: ${ApiClient().getDomain}${_originalImageUrl!})',
                                      );
                                      return const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                  : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 이미지 관리 버튼 영역
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 이미지 변경 버튼
                        GestureDetector(
                          onTap: _pickImage,
                          child: const Text(
                            '이미지 변경',
                            style: TextStyle(
                              color: Color(0xFF3154FF),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        // 프로필 이미지가 있을 때만 삭제 버튼 표시
                        if (!_isProfileImageDeleted &&
                            (_originalImageUrl != null ||
                                _selectedImage != null))
                          Row(
                            children: [
                              const Text(' | '),
                              GestureDetector(
                                onTap: _deleteProfileImage,
                                child: Text(
                                  '이미지 삭제',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
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
}

// 흔들림 커브 정의
class ShakeCurve extends Curve {
  @override
  double transform(double t) {
    return sin(t * 4 * 3.14) * 0.3;
  }
}
