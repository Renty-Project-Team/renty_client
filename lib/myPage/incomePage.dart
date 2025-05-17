import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/core/api_client.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({Key? key}) : super(key: key);

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage>
    with SingleTickerProviderStateMixin {
  int _income = 0;
  String _userName = '';
  bool _isLoading = true;
  bool _showError = false;
  String _errorMessage = '';

  // 애니메이션을 위한 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 표시할 현재 금액
  int _currentDisplayedIncome = 0;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();

    // 애니메이션 컨트롤러 초기화 - 더 긴 시간으로 설정
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 부드러운 이징 커브 사용
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // 부드러운 가속 후 감속 효과
    );

    // 애니메이션 상태 리스너 추가
    _animation.addListener(_updateIncomeValue);

    // 애니메이션 완료 리스너
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationComplete = true;
          _currentDisplayedIncome = _income; // 최종 값으로 설정
        });
        HapticFeedback.mediumImpact(); // 완료 시 진동 (약하게 설정)
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 부드러운 카운터 애니메이션 구현
  void _updateIncomeValue() {
    setState(() {
      // 애니메이션 진행도에 따라 부드럽게 증가
      _currentDisplayedIncome = (_income * _animation.value).round();
    });
  }

  // 수익금 데이터 로드
  Future<void> _loadIncomeData() async {
    try {
      final ApiClient apiClient = ApiClient();
      final response = await apiClient.client.get('/My/profile'); // API 경로 수정

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _income = data['totalIncome'] ?? 0;
          _userName = data['userName'] ?? '';
          _isLoading = false;
        });

        // 데이터 로드 후 약간의 지연 후 애니메이션 시작
        Future.delayed(Duration(milliseconds: 400), () {
          _animationController.forward();
        });
      } else {
        setState(() {
          _showError = true;
          _errorMessage = '데이터를 불러오는 데 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
      print('수익금 데이터 로드 실패: $e');
    }
  }

  // 숫자 포맷팅 (1,000 단위 콤마 추가)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '수익금',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _showError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _showError = false;
                        });
                        _loadIncomeData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3154FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 닉네임 + 수익금 문구
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 16.0),
                      child: Text(
                        '$_userName님의 총 수익금은?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuad,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 24.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3154FF).withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 숫자 표시 영역
                              TweenAnimationBuilder(
                                tween: Tween<double>(
                                  begin: 0.95,
                                  end: _animationComplete ? 1.0 : 0.98,
                                ),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuad,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    // 숫자 부분
                                    Text(
                                      _formatNumber(_currentDisplayedIncome),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF3154FF),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    // 단위 부분
                                    Text(
                                      ' 원',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
