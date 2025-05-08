import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb을 가져오기 위함
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import 'package:web/web.dart' if (dart.library.io) 'web_stubs.dart' as web; // 웹 환경에서 실제 web.dart의 내용을 가짐

class TokenManager {
  static const String _tokenKey = 'jwt_auth_token';
  static FlutterSecureStorage? _secureStorage;

  // _secureStorage 인스턴스를 한 번만 생성하기 위한 getter
  static FlutterSecureStorage get secureStorage {
    _secureStorage ??= const FlutterSecureStorage(
      // Android 옵션 (선택 사항)
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true, // API 23+ 에서 SharedPreferences를 암호화
      ),
    );
    return _secureStorage!;
  }

  /// JWT 토큰을 저장합니다.
  /// 웹에서는 localStorage에, 모바일/데스크톱에서는 flutter_secure_storage에 저장합니다.
  static Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) {
        // 웹 환경
        web.window.localStorage?.setItem(_tokenKey, token);
        print('Token saved to localStorage (Web)');
      } else {
        // 모바일 또는 데스크톱 환경
        await secureStorage.write(key: _tokenKey, value: token);
        print('Token saved to secure storage (Mobile/Desktop)');
      }
    } catch (e) {
      print('Error saving token: $e');
      // 여기에 에러 처리 로직을 추가할 수 있습니다 (예: 사용자에게 알림)
    }
  }

  /// 저장된 JWT 토큰을 가져옵니다.
  /// 토큰이 없으면 null을 반환합니다.
  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        // 웹 환경
        final String? token = web.window.localStorage?.getItem(_tokenKey);
        print('Token retrieved from localStorage (Web): ${token != null ? "Found" : "Not Found"}');
        return token;
      } else {
        // 모바일 또는 데스크톱 환경
        final token = await secureStorage.read(key: _tokenKey);
        print('Token retrieved from secure storage (Mobile/Desktop): ${token != null ? "Found" : "Not Found"}');
        return token;
      }
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  /// 저장된 JWT 토큰을 삭제합니다.
  static Future<void> deleteToken() async {
    try {
      if (kIsWeb) {
        // 웹 환경
        web.window.localStorage?.removeItem(_tokenKey);
        print('Token deleted from localStorage (Web)');
      } else {
        // 모바일 또는 데스크톱 환경
        await secureStorage.delete(key: _tokenKey);
        print('Token deleted from secure storage (Mobile/Desktop)');
      }
    } catch (e) {
      print('Error deleting token: $e');
    }
  }
}