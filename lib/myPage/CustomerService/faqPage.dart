import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // 확장된 FAQ 항목을 추적하기 위한 상태 변수
  List<bool> _expandedStates = [];

  // FAQ 카테고리
  List<String> _categories = ['이용 안내', '대여/결제', '반납/연장', '보증금/손상', '계정/앱 이용'];

  int _selectedCategoryIndex = 0;

  // FAQ 목록
  final List<Map<String, dynamic>> _faqs = [
    // 이용 안내
    {
      'category': '이용 안내',
      'question': '빌려봄 서비스는 어떤 서비스인가요?',
      'answer':
          '빌려봄은 개인간 물품 대여 플랫폼으로, 사용하지 않는 물건을 빌려주거나 필요한 물건을 '
          '저렴하게 빌려볼 수 있는 서비스입니다. 다양한 카테고리의 물품을 손쉽게 검색하고, '
          '안전한 결제 시스템을 통해 편리하게 이용할 수 있습니다.',
    },
    {
      'category': '이용 안내',
      'question': '대여 물품은 어떻게 찾을 수 있나요?',
      'answer':
          '홈 화면에서 카테고리별로 물품을 찾아보거나 검색 기능을 통해 원하는 물품을 검색할 수 있습니다. '
          '지역, 가격, 기간 등의 필터를 적용하여 더 정확한 검색 결과를 얻을 수도 있습니다.',
    },
    {
      'category': '이용 안내',
      'question': '직거래와 택배 거래 중 어떤 것이 더 안전한가요?',
      'answer':
          '두 방식 모두 안전하게 이용하실 수 있습니다. 직거래는 물품 상태를 직접 확인할 수 있다는 장점이 있고, '
          '택배 거래는 거리 제약 없이 이용할 수 있습니다. 택배 거래 시에는 물품 수령 후 24시간 이내에 '
          '상태 확인을 완료하셔야 합니다.',
    },

    // 대여/결제
    {
      'category': '대여/결제',
      'question': '결제는 어떻게 이루어지나요?',
      'answer':
          '빌려봄에서는 신용카드, 체크카드, 계좌이체 등 다양한 결제 수단을 지원합니다. '
          '대여 신청 시 대여료와 보증금을 함께 결제하며, 반납 완료 후 문제가 없을 경우 보증금은 '
          '자동으로 환불됩니다.',
    },
    {
      'category': '대여/결제',
      'question': '보증금은 얼마인가요?',
      'answer':
          '보증금은 물품마다 다르며, 물품 가치에 따라 대여자가 설정합니다. '
          '일반적으로 물품 가격의 20~50% 정도로 책정되며, 물품 설명에서 확인하실 수 있습니다.',
    },
    {
      'category': '대여/결제',
      'question': '할인 쿠폰은 어떻게 사용하나요?',
      'answer':
          '할인 쿠폰은 결제 단계에서 적용 가능합니다. 마이페이지의 쿠폰함에서 보유한 쿠폰을 확인하고, '
          '결제 시 적용할 쿠폰을 선택하면 됩니다. 쿠폰마다 적용 조건이 다를 수 있으니 유의해주세요.',
    },

    // 반납/연장
    {
      'category': '반납/연장',
      'question': '대여 기간을 연장하고 싶어요.',
      'answer':
          '대여 기간 연장은 마이페이지 > 대여중인 물품 > 해당 물품 선택 > 연장 신청으로 가능합니다. '
          '단, 연장은 물품 대여자의 승인이 필요하며, 다음 예약이 있는 경우 연장이 어려울 수 있습니다. '
          '연장 시 추가 대여료가 발생합니다.',
    },
    {
      'category': '반납/연장',
      'question': '반납은 어떻게 하나요?',
      'answer':
          '직거래의 경우 약속된 장소에서 대여자에게 물품을 직접 반납하고, '
          '택배 거래의 경우 안전하게 포장하여 반송해주세요. 물품 반납 후 앱에서 반납 완료 처리를 해주셔야 '
          '보증금 환불이 진행됩니다.',
    },
    {
      'category': '반납/연장',
      'question': '대여 기간을 초과했어요.',
      'answer':
          '대여 기간 초과 시 추가 요금이 발생합니다. 기본적으로 1일 초과마다 일일 대여료의 150%가 '
          '부과되며, 물품에 따라 다를 수 있습니다. 초과가 예상되는 경우 미리 연장 신청을 하시거나 '
          '대여자에게 연락해주세요.',
    },

    // 보증금/손상
    {
      'category': '보증금/손상',
      'question': '보증금은 언제 환불되나요?',
      'answer':
          '물품 반납 후 대여자가 물품 상태를 확인하고 반납 확인 처리를 하면 영업일 기준 1~3일 내에 '
          '결제했던 수단으로 자동 환불됩니다. 카드 결제의 경우 카드사에 따라 환불 완료까지 시간이 '
          '더 소요될 수 있습니다.',
    },
    {
      'category': '보증금/손상',
      'question': '물품을 파손했을 경우 어떻게 되나요?',
      'answer':
          '물품 파손 시 보증금에서 수리비 또는 피해액이 차감될 수 있습니다. 경미한 파손은 대여자와 합의하에 '
          '처리되며, 심각한 파손이나 분실의 경우 물품 가치에 따른 비용을 부담해야 할 수 있습니다. '
          '이용 전 물품 상태를 사진으로 기록해두시면 분쟁 예방에 도움이 됩니다.',
    },
    {
      'category': '보증금/손상',
      'question': '대여자가 보증금 환불을 해주지 않아요.',
      'answer':
          '반납 후 7일 이내에 대여자가 별도 이의 제기 없이 환불 처리를 하지 않으면, '
          '시스템에서 자동으로 환불 처리됩니다. 환불 관련 분쟁이 있을 경우 1:1 문의하기를 통해 '
          '고객센터로 연락주시면 신속히 도와드리겠습니다.',
    },

    // 계정/앱 이용
    {
      'category': '계정/앱 이용',
      'question': '회원 탈퇴는 어떻게 하나요?',
      'answer':
          '회원 탈퇴는 마이페이지 > 회원 정보 수정 > 화면 하단 회원 탈퇴 버튼을 통해 가능합니다. '
          '단, 진행 중인 대여나 미결제 금액이 있는 경우 모든 거래가 완료된 후에 탈퇴가 가능합니다.',
    },
    {
      'category': '계정/앱 이용',
      'question': '앱에서 오류가 발생했어요.',
      'answer':
          '앱 오류 발생 시 앱을 최신 버전으로 업데이트 해보시고, 그래도 해결되지 않으면 '
          '마이페이지 > 1:1 문의하기를 통해 오류 내용과 함께 스크린샷을 첨부해 보내주시면 '
          '신속히 해결해드리겠습니다.',
    },
    {
      'category': '계정/앱 이용',
      'question': '알림을 받고 싶지 않아요.',
      'answer':
          '알림 설정은 마이페이지 > 설정 > 알림 설정에서 변경 가능합니다. '
          '채팅, 거래, 마케팅 등 각 유형별로 알림 수신 여부를 설정할 수 있습니다. '
          '단, 중요 거래 알림은 서비스 이용을 위해 꺼질 수 없습니다.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _expandedStates = List.generate(_faqs.length, (_) => false);
  }

  // 현재 선택된 카테고리의 FAQ만 필터링
  List<Map<String, dynamic>> get _filteredFAQs {
    return _faqs
        .where((faq) => faq['category'] == _categories[_selectedCategoryIndex])
        .toList();
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
          '자주 묻는 질문 (FAQ)',
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
          // 카테고리 탭
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: List.generate(
                  _categories.length,
                  (index) => _buildCategoryTab(index),
                ),
              ),
            ),
          ),

          // 구분선
          Divider(height: 1, color: Colors.grey[300]),

          // FAQ 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: _filteredFAQs.length,
              itemBuilder: (context, index) {
                final faqIndex = _faqs.indexOf(_filteredFAQs[index]);
                return _buildFAQItem(faqIndex);
              },
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
        margin: const EdgeInsets.only(left: 8),
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

  // FAQ 항목 위젯
  Widget _buildFAQItem(int index) {
    final isExpanded = _expandedStates[index];
    final faq = _faqs[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStates[index] = expanded;
            });
            if (expanded) {
              HapticFeedback.lightImpact();
            }
          },
          title: Text(
            faq['question'],
            style: TextStyle(
              fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
              color: isExpanded ? const Color(0xFF3154FF) : Colors.black87,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          trailing: Icon(
            isExpanded ? Icons.remove : Icons.add,
            color: isExpanded ? const Color(0xFF3154FF) : Colors.grey,
          ),
          children: [
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 8),
            Text(
              faq['answer'],
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
