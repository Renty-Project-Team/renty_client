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
  bool _rememberMe = true; // "로그인 상태 유지" 기본값
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _login() async {
    print(_formKey.currentState?.validate());
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _statusMessage = '로그인 시도 중...';
      });

      try {
        // ApiClient를 통해 Dio 인스턴스 접근
        // !!! 중요: 실제 로그인 API 엔드포인트로 변경하세요 !!!
        // 예: /auth/login, /account/login 등
        final response = await apiClient.client.post(
          '/Auth/register', // 예시 엔드포인트
          data: {
            // !!! 중요: 서버가 요구하는 필드명으로 정확히 변경하세요 !!!
            'name': nameController.text,
            'nickname': nickNameController.text,
            'email': emailController.text,
            'password': passwordController.text,
            'phoneNumber': phoneController.text,
          },
        );
        print("test");
        // 성공 (예: 상태 코드 200)
        if (response.statusCode == 200) {
          setState(() {
            _statusMessage = '로그인 성공!';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
            print('로그인 성공 데이터: ${response.data}'); // 서버 응답 데이터 확인
          });
          // 로그인 성공 후 쿠키가 잘 저장되었는지 확인 (디버깅용)
          // _checkCookies();
        } else {
          // 서버에서 예상치 못한 성공 상태 코드 반환
          setState(() {
            _statusMessage = '로그인 실패: 서버 응답 코드 ${response.statusCode}';
          });
        }
      } on DioException catch (e) {
        // Dio 관련 오류 처리
        String errorMessage = '로그인 오류 발생';
        if (e.response != null) {
          // 서버가 오류 응답을 반환한 경우
          print('서버 오류 응답: ${e.response?.data}');
          print('서버 오류 상태 코드: ${e.response?.statusCode}');
          if(e.response?.statusCode == 400){
             final String? errorMessage = e.response?.statusCode.toString();
             emailCheaker(errorMessage);
          } else {
            errorMessage = '서버 오류 (${e.response?.statusCode})';
          }

        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = '네트워크 타임아웃 발생';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = '네트워크 연결 오류 발생';
        }
        else {
          // 기타 Dio 오류 (요청 설정 오류 등)
          errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
        }
        setState(() {
          _statusMessage = errorMessage;
        });
      } catch (e) {
        // Dio 외의 예기치 않은 오류
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

  String? emailCheaker(String? value) {
    print('emailCheaker에서 받는 값${value}');
    if (value == null || value.isEmpty) return '이메일을 입력해주세요';
    if (!value.contains('@')) return '올바른 이메일 형식을 입력해주세요';
    if (value=='400') return '중복된 이메일 입나다';
    return null;
  }

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

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(fontSize: 18),
          validator: validator, // 추가
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
          child: Form( // ✅ Form으로 감싸줌
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text('입력하신 정보를 확인해주세요',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 32),

                _buildField('이름', nameController, validator: (value) {
                  if (value == null || value.isEmpty) return '이름을 입력해주세요';
                  return null;
                }),
                _buildField('닉네임', nickNameController, validator: (value) {
                  if (value == null || value.isEmpty) return '닉네임을 입력해주세요';
                  return null;
                }),
                _buildField('이메일', emailController, validator: emailCheaker ),
                _buildField('비밀번호', passwordController, obscure: true, validator: (value) {
                  if (value == null || value.length < 6) return '비밀번호는 최소 6자 이상이어야 해요';
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
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final updatedData = widget.signupData.copyWith(
                          name: nameController.text,
                          userName: nickNameController.text,
                          email: emailController.text,
                          pw: passwordController.text,
                          phone: phoneController.text,
                        );

                        await _login(); // 로딩 중 비활성화
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3182F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('회원가입 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

