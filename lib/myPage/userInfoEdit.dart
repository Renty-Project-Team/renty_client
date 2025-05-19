import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/core/api_client.dart';
import 'dart:math'; // sin 함수 사용
import 'package:renty_client/core/token_manager.dart';
import 'package:dio/dio.dart';

// 회원 정보 데이터 모델 수정
class UserInfoData {
  final String name; // 실제 이름
  final String email; // 이메일
  final String phoneNumber; // 전화번호
  final String userName; // 닉네임 (수정 불가)
  final String? accountNumber; // 계좌번호

  UserInfoData({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.userName,
    this.accountNumber,
  });
}

class UserInfoEditPage extends StatefulWidget {
  final UserInfoData initialInfo;

  const UserInfoEditPage({Key? key, required this.initialInfo})
    : super(key: key);

  @override
  State<UserInfoEditPage> createState() => _UserInfoEditPageState();
}

class _UserInfoEditPageState extends State<UserInfoEditPage>
    with SingleTickerProviderStateMixin {
  // 회원 정보 변수들
  late String _originalName;
  late String _originalEmail;
  late String _originalPhone;
  late String _originalUserName; // 닉네임 (수정 불가)
  late String? _originalAccountNumber; // 계좌번호

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _userNameController; // 닉네임 (수정 불가)
  late TextEditingController _accountController; // 계좌번호

  bool _hasChanges = false;
  bool _isSaving = false; // 저장 중 상태 표시

  // 에러 상태 관리 변수
  bool _isNameError = false;
  bool _isEmailError = false;
  bool _isPhoneError = false;
  bool _isAccountError = false;

  // 애니메이션 컨트롤러
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // API 클라이언트 인스턴스
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();

    // 초기 데이터 설정
    _originalName = widget.initialInfo.name;
    _originalEmail = widget.initialInfo.email;
    _originalPhone = widget.initialInfo.phoneNumber;
    _originalUserName = widget.initialInfo.userName;
    _originalAccountNumber = widget.initialInfo.accountNumber;

    _nameController = TextEditingController(text: _originalName);
    _emailController = TextEditingController(text: _originalEmail);

    // 전화번호 포맷팅 적용
    _phoneController = TextEditingController(
      text: _formatPhoneNumber(_originalPhone),
    );

    _userNameController = TextEditingController(text: _originalUserName);
    _accountController = TextEditingController(
      text: _originalAccountNumber ?? '',
    );

    // 텍스트 변경 감지 리스너 추가
    _nameController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _accountController.addListener(_checkChanges);

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
    _nameController.removeListener(_checkChanges);
    _emailController.removeListener(_checkChanges);
    _phoneController.removeListener(_checkChanges);
    _accountController.removeListener(_checkChanges);

    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userNameController.dispose();
    _accountController.dispose();

    _shakeController.dispose();
    super.dispose();
  }

  // 전화번호 포맷팅 함수
  String _formatPhoneNumber(String phone) {
    // 숫자만 추출
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // ###-####-#### 포맷으로 변환
    if (digits.length <= 3) {
      return digits;
    } else if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, min(digits.length, 11))}';
    }
  }

  // 전화번호 입력 처리 함수
  void _onPhoneChanged(String value) {
    // 현재 커서 위치 저장
    int cursorPos = _phoneController.selection.start;

    // 이전 텍스트 길이 저장
    int oldTextLength = _phoneController.text.length;

    // 포맷팅된 번호 생성
    String formattedNumber = _formatPhoneNumber(value);

    // 텍스트 업데이트
    _phoneController.text = formattedNumber;

    // 커서 위치 조정
    int newLength = formattedNumber.length;
    int newCursorPos = cursorPos - (oldTextLength - newLength);

    // 커서 위치가 유효하도록 보정
    if (newCursorPos < 0) newCursorPos = 0;
    if (newCursorPos > formattedNumber.length)
      newCursorPos = formattedNumber.length;

    // 커서 위치 설정
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPos),
    );
  }

  // 변경 사항 확인 함수
  void _checkChanges() {
    setState(() {
      _hasChanges =
          _nameController.text != _originalName ||
          _emailController.text != _originalEmail ||
          _phoneController.text != _formatPhoneNumber(_originalPhone) ||
          _accountController.text != (_originalAccountNumber ?? '');

      // 텍스트가 입력되면 에러 상태 제거
      if (_nameController.text.isNotEmpty) {
        _isNameError = false;
      }
      if (_emailController.text.isNotEmpty) {
        _isEmailError = false;
      }
      if (_phoneController.text.isNotEmpty) {
        _isPhoneError = false;
      }
    });
  }

  // 뒤로가기 처리 함수
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    // 변경사항이 있을 경우 다이얼로그 표시
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

  // 회원 정보 저장하기 함수 수정
  Future<void> _saveUserInfo() async {
    // 기본 유효성 검사
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 이메일, 전화번호는 필수 입력 항목입니다')),
      );
      return;
    }

    setState(() {
      _isSaving = true; // 저장 중 상태 표시
    });

    try {
      // FormData 생성을 위한 맵 준비
      final Map<String, dynamic> formFields = {
        "Email": _emailController.text.trim(),
        "Name": _nameController.text.trim(),
        "UserName": _userNameController.text.trim(),
        "PhoneNumber": _phoneController.text.replaceAll('-', ''),
        "ImageAction": "None", // ImageAction 필드 추가
      };

      // 계좌번호가 있으면 추가
      if (_accountController.text.trim().isNotEmpty) {
        formFields["AccountNumber"] = _accountController.text.trim();
      }

      // FormData 객체 생성 (multipart/form-data 형식)
      final formData = FormData.fromMap(formFields);

      // 디버깅용 요청 데이터 출력
      print('서버로 보내는 데이터: $formFields');

      // PUT 요청 실행 (수정)
      final response = await _apiClient.client.put(
        '/My/profile',
        data: formData, // FormData 객체 사용
      );

      setState(() {
        _isSaving = false;
      });

      // 응답 처리
      if (response.statusCode == 200) {
        // JWT 토큰 저장 (반드시 필요)
        Map<String, dynamic> jsonData = response.data;
        final String accessToken = jsonData['token'];
        await TokenManager.saveToken(accessToken);

        // 성공 메시지 및 이전 화면 이동
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원 정보가 성공적으로 저장되었습니다')));

        // 수정된 데이터 반환
        final updatedInfo = UserInfoData(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.replaceAll('-', ''),
          userName: _userNameController.text,
          accountNumber:
              _accountController.text.trim().isEmpty
                  ? null
                  : _accountController.text.trim(),
        );

        // 이전 화면으로 결과 데이터와 함께 돌아가기
        Navigator.pop(context, updatedInfo);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // 디버깅용 상세 오류 정보 출력
      print('회원 정보 저장 실패: $e');
      if (e is DioException && e.response != null) {
        print('오류 상태 코드: ${e.response?.statusCode}');
        print('오류 응답 데이터: ${e.response?.data}');
      }

      // 오류 처리
      ScaffoldMessenger.of(context).clearSnackBars();

      String errorMessage = '회원 정보 저장 중 오류가 발생했습니다';

      // DioError 처리
      if (e is DioException && e.response?.statusCode == 400) {
        final errors = e.response?.data?[''];
        if (errors is List && errors.isNotEmpty) {
          for (var err in errors) {
            if (err is String) {
              if (err.contains("Email") && err.contains("already taken")) {
                errorMessage = '이미 사용 중인 이메일입니다.';
                break;
              }
              // 다른 오류 메시지 처리 가능
            }
          }
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));

      print('회원 정보 저장 실패: $e');
    }
  }

  // 입력 필드 생성 함수
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isError = false,
    bool readOnly = false,
    String? errorText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // 입력 필드
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: isError ? Offset(_shakeAnimation.value, 0) : Offset.zero,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isError ? Colors.red : Colors.grey.withOpacity(0.3),
                width: isError ? 1.5 : 1.0,
              ),
              color: readOnly ? Colors.grey.withOpacity(0.1) : Colors.white,
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              readOnly: readOnly,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: readOnly ? null : '${label}을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16,
                color: readOnly ? Colors.grey.shade700 : Colors.black,
              ),
            ),
          ),
        ),

        // 에러 메시지
        if (isError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
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
            '회원 정보 수정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveUserInfo,
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닉네임 입력 필드 (수정 불가)
                _buildInputField(
                  label: '닉네임',
                  controller: _userNameController,
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                // 이름 입력 필드
                _buildInputField(
                  label: '이름',
                  controller: _nameController,
                  isError: _isNameError,
                  errorText: '이름을 입력해주세요',
                ),
                const SizedBox(height: 24),

                // 이메일 입력 필드
                _buildInputField(
                  label: '이메일',
                  controller: _emailController,
                  isError: _isEmailError,
                  errorText: '유효한 이메일을 입력해주세요',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // 전화번호 입력 필드 (포맷팅 적용)
                _buildInputField(
                  label: '전화번호',
                  controller: _phoneController,
                  isError: _isPhoneError,
                  errorText: '전화번호를 입력해주세요',
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                ),
                const SizedBox(height: 24),

                // 계좌번호 입력 필드
                _buildInputField(
                  label: '계좌번호',
                  controller: _accountController,
                  isError: _isAccountError,
                  errorText: '계좌번호를 올바르게 입력해주세요',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
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
