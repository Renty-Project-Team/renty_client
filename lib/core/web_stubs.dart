class _MockStorage {
  void setItem(String key, String value) {
    // 네이티브에서는 호출되지 않아야 함
    throw UnimplementedError('localStorage.setItem is not available on this platform');
  }
  String? getItem(String key) {
    // 네이티브에서는 호출되지 않아야 함
    throw UnimplementedError('localStorage.getItem is not available on this platform');
    // return null; // 또는 null 반환
  }
  void removeItem(String key) {
    // 네이티브에서는 호출되지 않아야 함
    throw UnimplementedError('localStorage.removeItem is not available on this platform');
  }
}

class _MockWindow {
  final _MockStorage localStorage = _MockStorage();
}

// web_js.window 형태로 접근 가능하도록
// TokenManager.dart 에서 web_js.window.localStorage.setItem(...) 형태로 사용 예정
final _MockWindow window = _MockWindow();