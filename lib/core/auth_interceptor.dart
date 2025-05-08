import 'package:dio/dio.dart';
import 'package:renty_client/core/token_manager.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. 저장된 토큰 가져오기
    final String? token = await TokenManager.getToken();

    // 2. 토큰이 존재하면 Authorization 헤더에 추가
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('AuthInterceptor: Token added to headers.');
    } else {
      print('AuthInterceptor: No token found or token is empty.');
      // 토큰이 없는 경우, 특정 API는 토큰 없이도 호출 가능할 수 있으므로
      // 여기서 요청을 막지 않고 그대로 진행합니다.
      // 만약 모든 요청에 토큰이 필수라면, 여기서 에러를 발생시키거나
      // 로그인 페이지로 리디렉션하는 로직을 추가할 수 있습니다.
    }

    // 3. 다음 인터셉터 또는 실제 요청으로 진행
    return super.onRequest(options, handler);
    // 또는 handler.next(options); // 동일한 역할
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 응답 처리 (선택 사항)
    print('AuthInterceptor: Received response: ${response.statusCode}');
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // 에러 처리 (예: 401 Unauthorized 에러 시 토큰 갱신 로직)
    print('AuthInterceptor: Error: ${err.response?.statusCode} - ${err.message}');

    if (err.response?.statusCode == 401) {
      // 401 에러 발생 (토큰 만료 또는 유효하지 않음)
      TokenManager.deleteToken(); // 토큰 삭제
      print('AuthInterceptor: 401 Unauthorized error detected.');

      // TODO: 여기에 토큰 갱신 로직을 구현할 수 있습니다.
      // 1. 토큰 갱신 API 호출
      // 2. 새로운 토큰을 받아서 TokenManager.saveToken()으로 저장
      // 3. 원래 실패했던 요청을 새로운 토큰으로 재시도 (아래 예시 참고)

      // 예시: 토큰 갱신 후 재시도 (실제 구현은 더 복잡할 수 있음)
      // String? newAccessToken = await refreshToken(); // 실제 토큰 갱신 함수 호출
      // if (newAccessToken != null) {
      //   await TokenManager.saveToken(newAccessToken);
      //   // 원래 요청의 헤더를 새 토큰으로 업데이트
      //   err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      //   try {
      //     // Dio 인스턴스를 직접 사용하여 요청 재시도
      //     // 주의: 이 ApiClient 클래스 내의 Dio 인스턴스를 사용해야 함
      //     // 또는 별도의 Dio 인스턴스를 토큰 갱신 전용으로 만들 수도 있음
      //     final Dio dioForRetry = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
      //     dioForRetry.interceptors.add(LogInterceptor(requestBody: true, responseBody: true)); // 필요시 로깅
      //     final response = await dioForRetry.request(
      //       err.requestOptions.path,
      //       options: Options( // options를 Options.fromRequestOptions로 변환
      //         method: err.requestOptions.method,
      //         headers: err.requestOptions.headers,
      //         data: err.requestOptions.data,
      //         queryParameters: err.requestOptions.queryParameters,
      //         // ... 기타 필요한 RequestOptions 필드들
      //       ),
      //     );
      //     return handler.resolve(response); // 성공한 응답으로 해결
      //   } on DioException catch (e) {
      //     // 재시도도 실패하면 최종 에러 처리
      //     print('AuthInterceptor: Request retry failed: ${e.message}');
      //     // handler.next(e); 또는 handler.reject(e);
      //   }
      // } else {
      //   print('AuthInterceptor: Token refresh failed.');
      //   // 토큰 갱신 실패 시, 로그인 화면으로 보내거나 다른 에러 처리
      // }
    }

    super.onError(err, handler);
    // 또는 handler.next(err); // 에러를 다음 핸들러로 전달
  }
}
