import 'package:flutter/material.dart';
import '../main.dart'; // MainPage (로그인 화면 또는 홈 화면으로 이동용)

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool _isLoggingOut = false;
  String _statusMessage = '';

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
      _statusMessage = '로그아웃 중...';
    });

    try {
      // 👉 클라이언트 측 쿠키 제거
      await apiClient.clearCookie();

      setState(() {
        _statusMessage = '로그아웃 성공!';
      });

      // 👉 MainPage (로그인 화면 등)으로 이동 + 이전 기록 모두 제거
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        _statusMessage = '로그아웃 실패: $e';
      });
    } finally {
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('로그아웃')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 100, color: theme.colorScheme.primary),
              SizedBox(height: 20),
              Text(
                '로그아웃하시겠습니까?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingOut
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('로그아웃'),
                ),
              ),
              SizedBox(height: 12),

              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('성공') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
