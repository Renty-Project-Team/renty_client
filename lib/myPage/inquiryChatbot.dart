import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InquiryChatBotPage extends StatefulWidget {
  const InquiryChatBotPage({Key? key}) : super(key: key);

  @override
  State<InquiryChatBotPage> createState() => _InquiryChatBotPageState();
}

class _InquiryChatBotPageState extends State<InquiryChatBotPage> {
  // 채팅 메시지를 저장할 리스트
  final List<ChatMessage> _messages = [];

  // 스크롤 컨트롤러 (메시지 추가 시 스크롤 이동을 위함)
  final ScrollController _scrollController = ScrollController();

  // 질문 카테고리
  final List<String> _categories = ['대여/반납', '계정', '결제', '앱 이용', '기타'];

  int _selectedCategoryIndex = 0;

  // 카테고리별 질문 목록
  final Map<String, List<String>> _questions = {
    '대여/반납': [
      '반납이 지연된 경우 어떻게 해야 하나요?',
      '대여한 상품에 문제가 있을 때는 어떻게 해야 하나요?',
      '대여 기간을 연장하고 싶어요.',
    ],
    '계정': ['회원 탈퇴는 어떻게 하나요?', '아이디/비밀번호를 잊어버렸어요.', '개인정보 수정은 어떻게 하나요?'],
    '결제': ['결제했는데 대여 상태가 업데이트되지 않아요.', '보증금은 언제 환불되나요?', '잘못된 금액으로 결제되었어요.'],
    '앱 이용': ['앱 알림 설정을 변경하고 싶어요.', '앱에서 오류가 발생해요.', '검색 기능이 제대로 작동하지 않아요.'],
    '기타': ['물품 등록은 어떻게 하나요?', '서비스 이용 시간은 어떻게 되나요?', '실시간 상담원과 연결할 수 있나요?'],
  };

  // 질문에 대한 답변 매핑
  final Map<String, String> _answers = {
    '반납이 지연된 경우 어떻게 해야 하나요?':
        '반납 지연 시 대여 비용의 150%가 일별로 추가 부과될 수 있습니다. '
        '불가피한 사정이 있다면 반드시 대여자에게 미리 연락하여 상황을 설명하고 '
        '연장 가능 여부를 문의해주세요. 앱 내에서 연장 신청 기능도 이용 가능합니다.',

    '대여한 상품에 문제가 있을 때는 어떻게 해야 하나요?':
        '상품 수령 후 24시간 이내에 문제점을 발견하신 경우, 대여자에게 즉시 알려주시고 '
        '앱의 "문제 보고하기" 기능을 통해 사진과 함께 상세 내용을 제출해주세요. '
        '고객센터에서 확인 후 적절한 조치를 취해드립니다.',

    '대여 기간을 연장하고 싶어요.':
        '앱 마이페이지 > 대여중인 제품목록 > 해당 상품 선택 > "연장 신청" 버튼을 통해 '
        '연장 신청이 가능합니다. 대여자의 승인이 필요하며, 연장된 기간에 대한 추가 비용이 '
        '발생합니다. 다음 예약이 있는 경우 연장이 어려울 수 있으니 참고해주세요.',

    '회원 탈퇴는 어떻게 하나요?':
        '회원 탈퇴는 마이페이지 > 회원 정보 수정 > 페이지 하단의 "회원 탈퇴" 버튼을 통해 '
        '진행 가능합니다. 단, 진행 중인 대여 거래가 있거나 미결제 금액이 있는 경우 '
        '모든 거래가 완료된 후에 탈퇴가 가능합니다.',

    '아이디/비밀번호를 잊어버렸어요.':
        '로그인 화면에서 "아이디/비밀번호 찾기" 기능을 이용해주세요. '
        '가입 시 등록한 이메일 주소로 인증 링크가 발송되며, 본인 확인 후 '
        '비밀번호 재설정이 가능합니다.',

    '개인정보 수정은 어떻게 하나요?':
        '마이페이지 > 회원 정보 수정 메뉴에서 이름, 연락처, 이메일 등 '
        '개인정보를 수정하실 수 있습니다. 단, 일부 정보는 보안을 위해 '
        '추가 인증이 필요할 수 있습니다.',

    '결제했는데 대여 상태가 업데이트되지 않아요.':
        '결제 후 시스템 반영까지 최대 10분 정도 소요될 수 있습니다. '
        '10분 이상 경과 후에도 상태가 업데이트되지 않는다면, '
        '결제내역 화면을 캡처하여 고객센터로 문의해주시기 바랍니다.',

    '보증금은 언제 환불되나요?':
        '물품 반납 확인 후 영업일 기준 1~3일 내에 자동으로 환불됩니다. '
        '카드 결제의 경우 카드사 정책에 따라 환불 완료까지 추가 시간이 소요될 수 있습니다. '
        '7일 이상 환불이 지연될 경우 고객센터로 문의해주세요.',

    '잘못된 금액으로 결제되었어요.':
        '결제 내역 확인 후, 오류가 확인된 경우 고객센터로 결제 내역 캡처와 함께 '
        '문의해주시면 빠르게 처리해드리겠습니다. 영업일 기준 1~2일 내로 환불 처리됩니다.',

    '앱 알림 설정을 변경하고 싶어요.':
        '마이페이지 > 설정 > 알림 설정에서 채팅, 거래, 마케팅 등 각 유형별로 '
        '알림 수신 여부를 설정할 수 있습니다. 또한 기기 설정에서도 앱 알림 권한을 '
        '확인해주시기 바랍니다.',

    '앱에서 오류가 발생해요.':
        '앱을 최신 버전으로 업데이트하고, 기기를 재부팅해보세요. 문제가 지속된다면 '
        '오류 발생 화면을 캡처하여 고객센터로 보내주시면 신속히 해결해드리겠습니다.',

    '검색 기능이 제대로 작동하지 않아요.':
        '검색어를 간단하게 입력해보시고, 필터 설정을 초기화한 후 다시 시도해보세요. '
        '특수문자나 오타가 있는 경우 검색이 제대로 되지 않을 수 있습니다. '
        '문제가 지속되면 고객센터로 문의해주세요.',

    '물품 등록은 어떻게 하나요?':
        '하단 메뉴의 "+" 버튼을 눌러 물품 등록 페이지로 이동할 수 있습니다. '
        '물품 사진, 제목, 설명, 대여 가격, 보증금 등 필요한 정보를 입력하시면 됩니다. '
        '상세하고 정확한 정보를 입력할수록 대여 확률이 높아집니다.',

    '서비스 이용 시간은 어떻게 되나요?':
        '빌려봄 앱은 24시간 365일 이용 가능합니다. 다만, 고객센터는 평일 오전 9시부터 '
        '오후 6시까지 운영되며, 주말 및 공휴일은 휴무입니다. 긴급 문의는 앱 내 고객센터로 '
        '접수해주시면 영업일 기준으로 순차 답변드립니다.',

    '실시간 상담원과 연결할 수 있나요?':
        '현재 실시간 채팅 상담은 제공되지 않습니다. 시급한 문의사항은 고객센터 '
        '이메일(help@bilyeobom.com)이나 고객센터(02-1234-5678)로 연락주시면 '
        '우선적으로 답변드리도록 하겠습니다. 평일 오전 9시~오후 6시 운영합니다.',
  };

  @override
  void initState() {
    super.initState();
    // 초기 웰컴 메시지 추가
    Future.delayed(Duration(milliseconds: 500), () {
      _addBotMessage('안녕하세요! 빌려봄 고객센터입니다. 어떤 도움이 필요하신가요?');
      Future.delayed(Duration(milliseconds: 1000), () {
        _addBotMessage('아래 카테고리에서 질문 유형을 선택해주세요.');
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 챗봇 메시지 추가
  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  // 사용자 메시지 추가
  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();

    // 봇 응답 생성
    String answer =
        _answers[text] ??
        '죄송합니다. 해당 질문에 대한 답변을 준비 중입니다. 고객센터(02-1234-5678)로 문의해주시면 상세히 안내해드리겠습니다.';

    Future.delayed(Duration(milliseconds: 1000), () {
      _addBotMessage(answer);
    });
  }

  // 스크롤을 맨 아래로 이동
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '1:1 문의하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 카테고리 선택 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(
                  _categories.length,
                  (index) => _buildCategoryTab(index),
                ),
              ),
            ),
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // 채팅 메시지 표시 영역 수정
          Expanded(
            child: Container(
              // 배경 이미지 제거 및 단색 배경으로 변경
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),

          // 질문 버튼 표시 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '자주 묻는 질문',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),

                // 현재 선택된 카테고리의 질문 버튼들
                ..._questions[_categories[_selectedCategoryIndex]]!
                    .map(
                      (question) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _addUserMessage(question);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            width: double.infinity,
                            child: Text(
                              question,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),

                // 추가 문의 안내
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '다른 문의사항은 고객센터(02-1234-5678)로 연락주세요',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 탭 위젯
  Widget _buildCategoryTab(int index) {
    final isSelected = index == _selectedCategoryIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF3154FF).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF3154FF)
                    : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          _categories[index],
          style: TextStyle(
            color: isSelected ? const Color(0xFF3154FF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 채팅 메시지 버블 위젯 수정
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 챗봇 아이콘 (사용자 메시지일 경우 표시 안 함)
          if (!message.isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(0xFF3154FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),

          // 메시지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: message.isUser ? Color(0xFF3154FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: message.isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 채팅 메시지 클래스
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
