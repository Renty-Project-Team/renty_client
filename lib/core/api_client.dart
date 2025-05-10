import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:renty_client/core/auth_interceptor.dart';



// 앱 전체에서 공유할 수 있도록 Dio 인스턴스를 설정 (예: 싱글톤 또는 DI 사용)
class ApiClient {
  late Dio dio;

  // 싱글톤 패턴을 위한 인스턴스
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  bool _isInitialized = false;

  // 도메인
  static const String domain = "https://deciding-silkworm-set.ngrok-free.app"; 
  // static const String domain = "http://localhost:8088"; 

  String get getDomain {
    return domain; // 도메인 반환
  }

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

    dio.interceptors.add(AuthInterceptor());
   
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
