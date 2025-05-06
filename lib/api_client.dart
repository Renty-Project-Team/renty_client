import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/io.dart';


// 앱 전체에서 공유할 수 있도록 Dio 인스턴스를 설정 (예: 싱글톤 또는 DI 사용)
class ApiClient {
  late Dio dio;
  late PersistCookieJar persistentCookieJar;

  // 싱글톤 패턴을 위한 인스턴스
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  bool _isInitialized = false;

  // 도메인
  static const String domain = "https://deciding-silkworm-set.ngrok-free.app"; 
  // static const String domain = "http://localhost:8088"; 

  // 내부 생성자
  ApiClient._internal();

  // 비동기 초기화 메서드
  Future<void> initialize() async {
    if (_isInitialized) return; // 이미 초기화되었다면 반환

    // Dio 인스턴스 생성 및 기본 옵션 설정
    final options = BaseOptions(
      baseUrl: '$domain/api', // 기본 URL 설정
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    );

    dio = Dio(options);

    if (!kIsWeb) {
      // 영구 쿠키 저장 경로 설정
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      final cookiePath = '$appDocPath/.cookies/'; // 숨김 폴더 사용 권장

      // PersistCookieJar 생성 (파일 저장소 사용)
      persistentCookieJar = PersistCookieJar(
        ignoreExpires: false, // 만료된 쿠키는 저장/전송하지 않음 (중요!)
        storage: FileStorage(cookiePath),
      );

      // CookieManager 인터셉터 추가
      dio.interceptors.add(CookieManager(persistentCookieJar));
    }

    // 로깅 인터셉터 추가 (개발 시 유용)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[DioLog] $o'), // 로그 출력 방식 정의
    ));

    // 인증되지 않은 SSL 인증서 허용 (개발 환경에서만 사용)
    if (dio.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        // HttpClient 인스턴스 생성
        final client = HttpClient();

        // 중요: 이 코드는 보안 검증을 비활성화하므로 매우 신중하게 사용해야 합니다.
        // 운영 환경에서는 절대 사용하지 마세요.
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('⚠️ WARNING: Accepting invalid certificate for $host (Using createHttpClient)');
          return true; // 모든 인증서 오류 무시하고 연결 허용 (매우 위험!)
        };
        return client;
      };
    }


    _isInitialized = true;
  }

  Future<bool> hasTokenCookieLocally() async {
    String tokenCookieName = '.Renty.AuthCookie'; // 쿠키 이름 정의

    try {
      // 서버 URI에 대한 쿠키 목록 로드
      List<Cookie> cookies = await persistentCookieJar.loadForRequest(Uri.parse(domain));

      // 목록에서 원하는 이름의 쿠키가 있는지 확인
      bool hasToken = cookies.any((cookie) => cookie.name == tokenCookieName);

      print("Local cookie check for '$tokenCookieName': $hasToken");
      return hasToken;
    } catch (e) {
      print("Error checking local cookies: $e");
      return false; // 오류 발생 시 없다고 간주
    }
  }

  Future<void> clearCookie() async {
    await persistentCookieJar.delete(Uri.parse(domain)); // 특정 도메인에 대한 쿠키 삭제
  }

  // 다른 곳에서 Dio 인스턴스에 접근하기 위한 getter
  Dio get client {
    if (!_isInitialized) {
      throw Exception("ApiClient not initialized. Call initialize() first.");
    }
    return dio;
  }
}

