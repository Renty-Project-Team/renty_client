import 'package:flutter/material.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/main.dart';

class DummyMyPage extends StatelessWidget {
  const DummyMyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is the My Page'),
            ElevatedButton(
              onPressed: () {
                TokenManager.deleteToken(); // 토큰 삭제
              },
              child: const Text('log out'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Home Page'),
            ),
          ],
        ),
      ),
    );
  }
}