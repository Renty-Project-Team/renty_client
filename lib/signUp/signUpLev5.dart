import 'package:flutter/material.dart';
import 'package:renty_client/signUp/signUpData.dart';
import 'package:renty_client/login/login.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/main.dart';

class SignupConfirmPage extends StatefulWidget {
  final SignupData signupData;

  const SignupConfirmPage({super.key, required this.signupData});

  @override
  _SignupConfirmPageState createState() => _SignupConfirmPageState();
}

class _SignupConfirmPageState extends State<SignupConfirmPage> {
  late TextEditingController nameController;
  late TextEditingController nickNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController phoneController;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _statusMessage = '';

  String? _emailErrorMessage;     // ✅ 이메일 에러 메시지 상태 변수
  String? _nickNameErrorMessage;  // ✅ 닉네임 에러 메시지 상태 변수

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.signupData.name);
    nickNameController = TextEditingController(text: widget.signupData.userName);
    emailController = TextEditingController(text: widget.signupData.email);
    passwordController = TextEditingController(text: widget.signupData.pw);
    phoneController = TextEditingController(text: widget.signupData.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    nickNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// ✅ 이메일 validator
  String? emailCheaker(String? value) {
    if (_emailErrorMessage != null) {
      final message = _emailErrorMessage;
      _emailErrorMessage = null; // 한 번만 표시하고 초기화
      return message;
    }
    if (value == null || value.isEmpty) return '이메일을 입력해주세요';
    if (!value.contains('@')) return '올바른 이메일 형식을 입력해주세요';
    return null;
  }

  /// ✅ 닉네임 validator
  String? nickNameCheaker(String? value) {
    if (_nickNameErrorMessage != null) {
      final message = _nickNameErrorMessage;
      _nickNameErrorMessage = null; // 한 번만 표시하고 초기화
      return message;
    }
    if (value == null || value.isEmpty) return '닉네임을 입력해주세요';
    return null;
  }

  /// 회원가입 시도 함수
  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _statusMessage = '회원가입 시도 중...';
      });

      try {
        final response = await apiClient.client.post(
          '/Auth/register',
          data: {
            'name': nameController.text,
            'username': nickNameController.text,
            'email': emailController.text,
            'password': passwordController.text,
            'phoneNumber': phoneController.text,
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _statusMessage = '회원가입 성공!';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          });
        } else {
          setState(() {
            _statusMessage = '회원가입 실패: 서버 응답 코드 ${response.statusCode}';
          });
        }
      } on DioException catch (e) {
        String errorMessage = '회원가입 오류 발생';
        if (e.response != null) {
          print('서버 오류 응답: ${e.response?.data}');
          print('서버 오류 상태 코드: ${e.response?.statusCode}');
          if (e.response?.statusCode == 400) {
            final data = e.response?.data;
            if (data is Map && data[''] is List) {
              final List errors = data[''];
              for (var error in errors) {
                final errorStr = error.toString();
                if (errorStr.contains('Username')) {
                  _nickNameErrorMessage = '중복된 닉네임입니다';
                }
                if (errorStr.contains('Email')) {
                  _emailErrorMessage = '중복된 이메일입니다';
                }
              }
            }
            setState(() {
              _statusMessage = '입력값 오류가 있습니다.';
            });
            _formKey.currentState!.validate(); // ✅ validator 재실행 → 상태 변수 표시
            return; // 에러 처리 완료 → 아래 진행 안 함
          } else {
            errorMessage = '서버 오류 (${e.response?.statusCode})';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = '네트워크 타임아웃 발생';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = '네트워크 연결 오류 발생';
        } else {
          errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
        }
        setState(() {
          _statusMessage = errorMessage;
        });
      } catch (e) {
        setState(() {
          _statusMessage = '알 수 없는 오류 발생: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800])),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(fontSize: 18),
          validator: validator,
          decoration: InputDecoration(
            hintText: '$label 입력',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3182F6), width: 2),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text('입력하신 정보를 확인해주세요',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 32),
                _buildField('이름', nameController, validator: (value) {
                  if (value == null || value.isEmpty) return '이름을 입력해주세요';
                  return null;
                }),
                _buildField('닉네임', nickNameController, validator: nickNameCheaker),
                _buildField('이메일', emailController, validator: emailCheaker),
                _buildField('비밀번호', passwordController, obscure: true,
                    validator: (value) {
                      if (value == null || value.length < 6)
                        return '비밀번호는 최소 6자 이상이어야 해요';
                      return null;
                    }),
                _buildField('전화번호', phoneController, validator: (value) {
                  if (value == null || value.isEmpty) return '전화번호를 입력해주세요';
                  return null;
                }),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _register();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3182F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('회원가입 완료',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


