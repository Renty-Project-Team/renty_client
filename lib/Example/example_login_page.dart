import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/api_client.dart';

class ExampleLoginPage extends StatefulWidget {
  const ExampleLoginPage({super.key});

  @override
  State<ExampleLoginPage> createState() => _ExampleLoginPageState();
}

class _ExampleLoginPageState extends State<ExampleLoginPage> {
  final _formKey = GlobalKey<FormState>(); // 폼 유효성 검사를 위한 키
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true; // "로그인 상태 유지" 기본값
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
          '/auth/login', // 예시 엔드포인트
          data: {
            // !!! 중요: 서버가 요구하는 필드명으로 정확히 변경하세요 !!!
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );

        // 성공 (예: 상태 코드 200)
        if (response.statusCode == 200) {
          setState(() {
            _statusMessage = '로그인 성공!';
            // 로그인 성공 후 다음 화면으로 이동하거나 상태 업데이트
            // 예: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
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
          if (e.response?.statusCode == 401) {
            errorMessage = '이메일 또는 비밀번호가 잘못되었습니다.';
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

  // (데모용) 인증이 필요한 리소스 요청 함수
  Future<void> _fetchProtectedData() async {
     setState(() {
        _isLoading = true;
        _statusMessage = '보호된 데이터 요청 중...';
      });
       try {
        // !!! 중요: 실제 보호된 API 엔드포인트로 변경하세요 !!!
        final response = await apiClient.client.get('/WeatherForecast/getprofile'); // 예시 엔드포인트

        if (response.statusCode == 200) {
          setState(() {
             _statusMessage = '보호된 데이터 로드 성공!\n데이터: ${response.data}';
          });
        } else {
           setState(() {
            _statusMessage = '보호된 데이터 로드 실패: ${response.statusCode}';
          });
        }
      } on DioException catch (e) {
         String errorMessage = '보호된 데이터 요청 오류';
        if (e.response?.statusCode == 401) {
          errorMessage = '인증 실패! (쿠키 만료 또는 없음)';
        } else {
           errorMessage = '오류: ${e.message}';
        }
         setState(() {
           _statusMessage = errorMessage;
        });
      } catch(e) {
         setState(() {
           _statusMessage = '알 수 없는 오류: $e';
         });
      }
      finally {
        setState(() {
          _isLoading = false;
        });
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dio Cookie Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return '유효한 이메일을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력하세요.';
                  }
                  return null;
                },
              ),
              CheckboxListTile(
                title: const Text("로그인 상태 유지"),
                value: _rememberMe,
                onChanged: (newValue) {
                  setState(() {
                    _rememberMe = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // 체크박스를 왼쪽에
                 contentPadding: EdgeInsets.zero, // 기본 패딩 제거
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login, // 로딩 중 비활성화
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('로그인'),
              ),
              const SizedBox(height: 20),
              if (_statusMessage.isNotEmpty) // 상태 메시지가 있을 때만 표시
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage.contains('성공') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              // 데모용 버튼: 로그인 후 쿠키가 잘 사용되는지 테스트
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchProtectedData,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('보호된 데이터 요청 (로그인 후)'),
              ),
               const SizedBox(height: 10),
               // 데모용 버튼: 현재 저장된 쿠키 확인
              // ElevatedButton(
              //   onPressed: _isLoading ? null : _checkCookies,
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              //   child: const Text('현재 쿠키 확인 (콘솔 출력)'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}