import 'package:flutter/material.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({Key? key}) : super(key: key);

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  // 앱 정보 불러오기 (실제로는 package_info_plus 패키지로 구현하는 것이 좋음)
  Future<void> _loadAppInfo() async {
    try {
      // 임시 데이터
      _version = '0.0.1v';
      _buildNumber = '10';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // LogoAppBar 대신 일반 AppBar 사용
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          '앱 정보',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black), // 뒤로가기 아이콘 색상
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

                      // 앱 로고
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B70FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.home_work,
                                  size: 60,
                                  color: Color(0xFF4B70FD),
                                ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 앱 이름
                      const Text(
                        'Renty',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 앱 버전
                      Text(
                        'Version $_version ($_buildNumber)',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 48),

                      // 정보 컨테이너
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem('개발사', '빌려봄 주식회사'),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildInfoItem('이메일', 'support@bilyeobom.com'),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildInfoItem('웹사이트', 'www.bilyeobom.com'),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildInfoItem('오픈소스 라이선스', '', hasArrow: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 저작권 정보
                      Text(
                        '© ${DateTime.now().year} Silla UniverSity. All rights reserved.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // 정보 아이템 위젯
  Widget _buildInfoItem(String title, String value, {bool hasArrow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (hasArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
