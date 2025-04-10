import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';


// 앱 전체에서 공유할 수 있도록 Dio 인스턴스를 설정 (예: 싱글톤 또는 DI 사용)
class ApiClient {
  late Dio dio;
  late PersistCookieJar persistentCookieJar;

  // 싱글톤 패턴을 위한 인스턴스
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  bool _isInitialized = false;

  // 내부 생성자
  ApiClient._internal();

  // 비동기 초기화 메서드
  Future<void> initialize() async {
    if (_isInitialized) return; // 이미 초기화되었다면 반환

    // Dio 인스턴스 생성 및 기본 옵션 설정
    final options = BaseOptions(
      baseUrl: "https://deciding-silkworm-set.ngrok-free.app/api", // 예: http://localhost:5000/api
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

    _isInitialized = true;
  }

  // 다른 곳에서 Dio 인스턴스에 접근하기 위한 getter
  Dio get client {
    if (!_isInitialized) {
      throw Exception("ApiClient not initialized. Call initialize() first.");
    }
    return dio;
  }
}

