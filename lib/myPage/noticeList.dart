import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:intl/intl.dart';

class Notice {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final bool isImportant;
  final bool isNew;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isImportant = false,
    this.isNew = false,
  });
}

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({Key? key}) : super(key: key);

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  bool _isLoading = true;
  final ApiClient _apiClient = ApiClient();
  List<Notice> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  // 공지사항 로드 함수 (실제로는 API 연동 필요)
  Future<void> _loadNotices() async {
    // 실제 구현에서는 API 호출
    // try {
    //   final response = await _apiClient.client.get('/api/notices');
    //   if (response.statusCode == 200) {
    //     final List<dynamic> data = response.data;
    //     setState(() {
    //       _notices = data.map((item) => Notice(
    //         id: item['id'],
    //         title: item['title'],
    //         content: item['content'],
    //         date: DateTime.parse(item['date']),
    //         isImportant: item['isImportant'] ?? false,
    //         isNew: item['isNew'] ?? false,
    //       )).toList();
    //       _isLoading = false;
    //     });
    //   }
    // } catch (e) {
    //   print('공지사항 로드 오류: $e');
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }

    // 임시 데이터 생성 (API 연동 전까지 사용)
    await Future.delayed(const Duration(seconds: 1)); // 로딩 효과를 위한 지연

    setState(() {
      _notices = [
        Notice(
          id: 1,
          title: '[중요] 빌려봄 서비스 오픈 안내',
          content:
              '안녕하세요, 빌려봄 서비스가 정식 오픈되었습니다.\n\n'
              '빌려봄은 여러분의 물건을 편리하게 대여할 수 있는 서비스입니다. '
              '사용하지 않는 물건을 공유하고, 필요한 물건을 저렴하게 빌려보세요.\n\n'
              '앱에 대한 피드백이나 개선 사항은 언제든지 1:1 문의를 통해 알려주시면 '
              '더 나은 서비스로 찾아뵙겠습니다.\n\n'
              '감사합니다.',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isImportant: true,
          isNew: true,
        ),
        Notice(
          id: 2,
          title: '결제 시스템 업데이트 안내',
          content:
              '빌려봄 서비스의 결제 시스템이 업데이트되었습니다.\n\n'
              '• 간편 결제 기능 추가\n'
              '• 보증금 자동 환불 시스템 도입\n'
              '• 정산 내역 실시간 확인 가능\n\n'
              '더 편리하고 안전한 거래를 위해 지속적으로 노력하겠습니다.',
          date: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Notice(
          id: 3,
          title: '빌려봄 이용 가이드',
          content:
              '빌려봄 서비스를 처음 이용하시나요?\n\n'
              '1. 회원가입 및 본인인증\n'
              '2. 대여하고 싶은 물건 등록 (사진과 상세 설명 포함)\n'
              '3. 대여 가격과 보증금 설정\n'
              '4. 채팅을 통한 거래 약속\n'
              '5. 안전한 거래 완료\n\n'
              '자세한 내용은 FAQ를 참고해주세요.',
          date: DateTime.now().subtract(const Duration(days: 14)),
        ),
        Notice(
          id: 4,
          title: '빌려봄 커뮤니티 가이드라인',
          content:
              '빌려봄은 모두가 편안하게 이용할 수 있는 커뮤니티를 지향합니다.\n\n'
              '다음과 같은 행동은 삼가주세요:\n'
              '• 불법적인 물품의 대여\n'
              '• 타인에게 불쾌감을 주는 사진이나 콘텐츠 등록\n'
              '• 허위 정보 기재\n'
              '• 약속된 거래 시간 및 조건 불이행\n\n'
              '위 사항을 위반할 경우 서비스 이용이 제한될 수 있습니다.',
          date: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Notice(
          id: 5,
          title: '빌려봄 앱 업데이트 안내 (v1.2.0)',
          content:
              '빌려봄 앱이 v1.2.0으로 업데이트되었습니다.\n\n'
              '• 채팅 시스템 성능 개선\n'
              '• 이미지 업로드 속도 향상\n'
              '• UI/UX 개선 및 버그 수정\n'
              '• 검색 필터 기능 강화\n\n'
              '더 나은 서비스 제공을 위해 항상 최신 버전으로 업데이트해주세요.',
          date: DateTime.now().subtract(const Duration(days: 45)),
        ),
      ];
      _isLoading = false;
    });
  }

  void _showNoticeDetail(Notice notice) {
    // 공지사항 상세 내용 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 제목
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (notice.isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '중요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 날짜
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(notice.date),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const Divider(height: 24),

                  // 내용
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        notice.content,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ),

                  // 닫기 버튼
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B70FD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('닫기'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notices.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '등록된 공지사항이 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadNotices,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final notice = _notices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildNoticeItem(notice),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildNoticeItem(Notice notice) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // 햅틱 피드백
        _showNoticeDetail(notice);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 행
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notice.isImportant)
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '중요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (notice.isNew)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 날짜와 오른쪽 화살표
            Row(
              children: [
                Text(
                  DateFormat('yyyy.MM.dd').format(notice.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
