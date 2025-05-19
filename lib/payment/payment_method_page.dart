import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat/chat.dart';
import '../chat/trade_button_service.dart';
import 'payment_service.dart';
import 'payment_completion_page.dart';

enum PaymentMethodType {
  card,
  virtualAccount,
  bankTransfer,
  kakaoPay,
  naverPay,
  tossPay,
  phonePay,
}

class PaymentMethod {
  final PaymentMethodType type;
  final String name;
  final String icon;
  final bool isPopular;

  PaymentMethod({
    required this.type,
    required this.name,
    required this.icon,
    this.isPopular = false,
  });
}

class PaymentMethodPage extends StatefulWidget {
  final Product product;
  final int itemId;
  final String buyerName;
  final String? sellerName; // sellerName 추가
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final int deposit;
  final int tradeOfferVersion; // tradeOfferVersion 추가

  const PaymentMethodPage({
    Key? key,
    required this.product,
    required this.itemId,
    required this.buyerName,
    this.sellerName, // optional로 설정
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deposit,
    required this.tradeOfferVersion, // 필수 파라미터로 추가
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  PaymentMethodType? _selectedPaymentMethod;
  String? _selectedCardCompany;
  int _selectedInstallment = 0;
  bool _isAgreementChecked = false;
  bool _isProcessing = false;

  // 카드사 목록
  final List<String> _cardCompanies = [
    '신한카드',
    '삼성카드',
    '현대카드',
    '국민카드',
    'NH농협카드',
    '롯데카드',
    'BC카드',
    '하나카드',
    '우리카드',
    '씨티카드',
    '기타',
  ];

  // 할부 개월 수 옵션
  final List<int> _installmentOptions = [0, 2, 3, 4, 5, 6, 9, 12];

  // 결제 수단 목록
  late List<PaymentMethod> _paymentMethods;

  @override
  void initState() {
    super.initState();

    // 결제 수단 초기화
    _paymentMethods = [
      PaymentMethod(
        type: PaymentMethodType.card,
        name: '신용/체크카드',
        icon: '💳'
      ),
      PaymentMethod(
        type: PaymentMethodType.virtualAccount,
        name: '가상계좌',
        icon: '🏦',
      ),
      PaymentMethod(
        type: PaymentMethodType.bankTransfer,
        name: '계좌이체',
        icon: '💸',
      ),
      PaymentMethod(
        type: PaymentMethodType.kakaoPay,
        name: '카카오페이',
        icon: '🟨',
        isPopular: true,
      ),
      PaymentMethod(
        type: PaymentMethodType.naverPay,
        name: '네이버페이',
        icon: '🟩',
      ),
      PaymentMethod(
        type: PaymentMethodType.tossPay,
        name: '토스페이',
        icon: '🔵',
        isPopular: true,
      ),
      PaymentMethod(
        type: PaymentMethodType.phonePay,
        name: '휴대폰 결제',
        icon: '📱',
      ),
    ];

    // 기본 결제 수단 선택
    _selectedPaymentMethod = PaymentMethodType.card;
    _selectedCardCompany = _cardCompanies.first;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final totalAmount = widget.totalPrice + widget.deposit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '결제하기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품 요약 정보
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상품 이미지
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                widget.product.imageUrl != null &&
                                        widget.product.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        widget.product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[500],
                                            ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                          ),
                          const SizedBox(width: 12),
                          // 상품 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '총 결제 금액: ${numberFormat.format(totalAmount)}원',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3154FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 결제 수단 섹션
                    const Text(
                      '결제 수단',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 결제 수단 목록
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _buildPaymentMethodItem(method);
                      },
                    ),

                    const SizedBox(height: 24),

                    // 선택된 결제 수단에 따른 추가 정보
                    if (_selectedPaymentMethod == PaymentMethodType.card)
                      _buildCardPaymentDetails(),

                    const SizedBox(height: 24),

                    // 이용약관 동의
                    _buildAgreementSection(),
                  ],
                ),
              ),
            ),

            // 결제하기 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed:
                      _isAgreementChecked && !_isProcessing
                          ? _processPayment
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3154FF),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isProcessing
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${numberFormat.format(totalAmount)}원 결제하기',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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

  // 결제 수단 아이템 위젯
  Widget _buildPaymentMethodItem(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method.type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3154FF) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 결제 수단 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(method.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            // 결제 수단 이름
            Expanded(
              child: Text(
                method.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // 인기 배지 또는 선택 표시
            if (method.isPopular && !isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '인기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3154FF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // 카드 결제 상세 정보 위젯
  Widget _buildCardPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카드 정보',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 카드사 선택
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCardCompany,
              isExpanded: true,
              hint: const Text('카드사 선택'),
              items:
                  _cardCompanies.map((String company) {
                    return DropdownMenuItem<String>(
                      value: company,
                      child: Text(company),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCardCompany = newValue;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 할부 개월 수 선택
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '할부 개월 수',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children:
                  _installmentOptions.map((int months) {
                    final isSelected = _selectedInstallment == months;
                    String label = months == 0 ? '일시불' : '$months개월';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedInstallment = months;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF3154FF)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF3154FF)
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  // 이용약관 동의 섹션
  Widget _buildAgreementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이용약관',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // 전체 동의
              Row(
                children: [
                  Checkbox(
                    value: _isAgreementChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgreementChecked = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF3154FF),
                  ),
                  const Text(
                    '주문 내용 및 결제 진행에 동의합니다',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgreementItem('대여 약관 동의 (필수)', true),
                    _buildAgreementItem('개인정보 수집 및 이용 동의 (필수)', true),
                    _buildAgreementItem('개인정보 제3자 제공 동의 (필수)', true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 개별 약관 동의 아이템
  Widget _buildAgreementItem(String title, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          TextButton(
            onPressed: () {
              // 약관 상세 내용 보기
              _showTermsDialog(title);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '보기',
              style: TextStyle(fontSize: 14, color: Color(0xFF3154FF)),
            ),
          ),
        ],
      ),
    );
  }

  // 약관 상세 내용 다이얼로그
  void _showTermsDialog(String title) {
    // 약관 내용 매핑
    final Map<String, String> termsContent = {
      '대여 약관 동의 (필수)': '''
제1조 (목적)
본 약관은 빌려봄(이하 "회사")이이 제공하는 대여여 서비스(이하 "서비스")를 이용함에 있어 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "대여 물품"이란 회사를 통해 제공되는 모든 대여 가능한 물건을 의미합니다.
2. "대여자"란 대여 물품을 등록하여 대여해주는 회원을 의미합니다.
3. "대여인"이란 대여 물품을 대여받는 회원을 의미합니다.

제3조 (대여 계약의 성립)
1. 대여 계약은 대여인의 대여 신청과 회사의 승낙으로 성립합니다.
2. 회사는 다음과 같은 경우에 대여 신청을 승낙하지 않을 수 있습니다:
   - 신청 내용에 허위, 기재 누락, 오기가 있는 경우
   - 대여 물품이 이미 다른 사용자에게 대여 중인 경우
   - 기타 회사가 대여 승낙이 어렵다고 판단하는 경우

제4조 (대여 물품의 관리 및 반환)
1. 대여인은 대여 물품을 계약에서 정한 용도로만 사용하여야 합니다.
2. 대여인은 대여 기간 중 대여 물품을 선량한 관리자의 주의의무로 관리해야 합니다.
3. 대여인은 계약에서 정한 반환일까지 대여 물품을 원래 상태로 반환해야 합니다.
4. 대여 물품 반환 시 파손, 손실 등의 문제가 있을 경우, 대여인은 이에 대한 배상 책임을 집니다.

제5조 (보증금)
1. 회사는 대여 물품의 안전한 반환을 위해 대여인에게 보증금을 요구할 수 있습니다.
2. 보증금은 대여 물품 반환 시 이상이 없을 경우 전액 환불됩니다.
3. 대여 물품의 파손, 분실 등의 문제가 있을 경우 수리비 또는 보상비가 보증금에서 차감될 수 있습니다.

제6조 (취소 및 환불)
1. 대여인은 대여 시작일 전에 계약을 취소할 수 있으며, 취소 시점에 따라 다음과 같이 환불됩니다:
   - 대여 시작 7일 전 취소: 100% 환불
   - 대여 시작 3일 전 취소: 70% 환불
   - 대여 시작 1일 전 취소: 50% 환불
   - 대여 시작 당일 취소: 환불 불가
2. 대여 시작 후에는 원칙적으로 취소 및 환불이 불가능합니다.

제7조 (금지행위)
대여인은 다음 각 호의 행위를 하여서는 안 됩니다:
1. 대여 물품을 제3자에게 재대여하는 행위
2. 대여 물품을 변형, 개조하는 행위
3. 대여 물품을 담보로 제공하는 행위
4. 기타 계약상 권리와 의무를 벗어나는 행위

제8조 (손해배상)
대여인이 본 약관을 위반하여 회사나 대여자에게 손해를 입힌 경우, 그 손해를 배상할 책임이 있습니다.

제9조 (면책조항)
회사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적 사유로 서비스를 제공할 수 없는 경우에는 서비스 제공에 대한 책임을 지지 않습니다.

제10조 (준거법 및 관할)
본 약관과 관련된 분쟁은 대한민국 법률을 준거법으로 하며, 소송 발생 시 관할법원은 회사 소재지를 관할하는 법원으로 합니다.
''',

      '개인정보 수집 및 이용 동의 (필수)': '''
제1조 (개인정보의 수집·이용 목적)
회사는 다음의 목적을 위하여 개인정보를 수집·이용합니다:
1. 서비스 제공 및 계약 이행
2. 회원 관리 및 서비스 이용 편의 제공
3. 결제 및 환불 처리
4. 물품 대여 관련 배송 및 반환 처리
5. 서비스 개선 및 신규 서비스 개발
6. 안전한 서비스 제공 및 부정 이용 방지

제2조 (수집하는 개인정보의 항목)
회사는 서비스 제공을 위해 다음과 같은 개인정보를 수집합니다:
1. 필수항목
   - 회원가입: 이름, 이메일 주소, 비밀번호, 휴대폰 번호
   - 결제 정보: 결제 수단 정보(신용카드 정보, 계좌번호 등)
   - 서비스 이용 기록: 접속 로그, IP 주소, 쿠키, 서비스 이용 기록
2. 선택항목
   - 프로필 사진, 주소, 생년월일

제3조 (개인정보의 보유 및 이용 기간)
1. 회사는 원칙적으로 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.
2. 다만, 관계법령에 의한 정보보호 사유에 따라 일정 기간 보존이 필요한 경우에는 해당 기간 동안 보존합니다:
   - 계약 또는 청약철회 등에 관한 기록: 5년 (전자상거래법)
   - 대금결제 및 재화 등의 공급에 관한 기록: 5년 (전자상거래법)
   - 소비자 불만 또는 분쟁처리에 관한 기록: 3년 (전자상거래법)
   - 표시/광고에 관한 기록: 6개월 (전자상거래법)
   - 로그인 기록: 3개월 (통신비밀보호법)

제4조 (개인정보의 파기 절차 및 방법)
회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.
1. 파기 절차: 불필요한 개인정보는 별도의 데이터베이스로 옮겨져 일정 기간 저장 후 파기됩니다.
2. 파기 방법: 전자적 파일 형태로 저장된 개인정보는 기록을 재생할 수 없도록 삭제하며, 종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각합니다.

제5조 (정보주체의 권리·의무 및 행사방법)
1. 정보주체는 회사에 대해 언제든지 다음의 권리를 행사할 수 있습니다:
   - 개인정보 열람 요구
   - 오류 등이 있을 경우 정정 요구
   - 삭제 요구
   - 처리정지 요구
2. 제1항에 따른 권리 행사는 회사에 대해 서면, 전화, 전자우편 등을 통하여 할 수 있으며 회사는 이에 대해 지체없이 조치하겠습니다.

제6조 (개인정보의 안전성 확보 조치)
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:
1. 관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육
2. 기술적 조치: 개인정보처리시스템 접근 제한, 암호화 기술 적용, 접속기록 보관
3. 물리적 조치: 전산실, 자료보관실 등의 접근통제

제7조 (개인정보 보호책임자)
회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 개인정보 보호책임자를 지정하고 있습니다.
''',

      '개인정보 제3자 제공 동의 (필수)': '''
제1조 (개인정보 제3자 제공)
회사는 이용자의 개인정보를 원칙적으로 외부에 제공하지 않습니다. 다만, 아래의 경우에는 예외로 합니다.
1. 이용자가 사전에 동의한 경우
2. 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우

제2조 (개인정보를 제공받는 자)
1. 거래 당사자(대여자/대여인)
2. 결제 서비스 제공 업체
3. 배송 서비스 제공 업체

제3조 (제공하는 개인정보 항목)
1. 거래 당사자에게 제공되는 정보:
   - 이름, 연락처, 거래 관련 필요 정보
2. 결제 서비스 제공 업체에 제공되는 정보:
   - 결제에 필요한 정보(결제 수단 정보, 결제 금액 등)
3. 배송 서비스 제공 업체에 제공되는 정보:
   - 배송에 필요한 정보(수령인 이름, 주소, 연락처)

제4조 (개인정보를 제공받는 자의 이용 목적)
1. 거래 당사자: 물품 대여 계약의 이행 및 분쟁 해결
2. 결제 서비스 제공 업체: 결제 처리 및 결제 도용 방지
3. 배송 서비스 제공 업체: 물품 배송 및 회수

제5조 (제공받는 자의 보유·이용기간)
제3자에게 제공된 개인정보는 제공된 목적이 달성된 후에는 지체 없이 파기합니다. 다만, 관련 법령에 따라 보존이 필요한 경우에는 해당 기간 동안 보관합니다.

제6조 (동의 거부 권리 및 동의 거부에 따른 불이익)
이용자는 개인정보 제3자 제공에 대한 동의를 거부할 권리가 있습니다. 다만, 동의 거부 시 서비스 이용이 제한될 수 있습니다.

제7조 (제3자 제공 내역 통지)
회사는 개인정보를 제3자에게 제공한 경우, 제공한 날로부터 30일 이내에 이용자에게 다음 사항을 알립니다:
1. 제공받는 자
2. 제공받는 자의 이용 목적
3. 제공하는 개인정보의 항목

제8조 (이용자의 권리)
이용자는 언제든지 제3자 제공 동의를 철회할 수 있으며, 동의 철회는 앱 내 설정 메뉴나 고객센터를 통해 가능합니다.

제9조 (제3자 제공 동의의 효력)
본 동의는 서비스 이용계약 체결 시부터 이용자의 계정 삭제 또는 제3자 제공 동의 철회 시까지 효력이 있습니다.
''',
    };

    // 선택한 약관 제목에 해당하는 내용 가져오기
    final content = termsContent[title] ?? '약관 내용이 준비되지 않았습니다.';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더 부분
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3154FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // 본문 내용
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 하단 버튼
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3154FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 결제 처리 함수
  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentService = PaymentService();
      await paymentService.completePayment(
        itemId: widget.itemId,
        tradeOfferVersion: widget.tradeOfferVersion,
        product: widget.product, // 추가
        buyerName: widget.buyerName,
        sellerName: widget.sellerName ?? "판매자",
        startDate: widget.startDate,
        endDate: widget.endDate,
        totalPrice: widget.totalPrice,
        deposit: widget.deposit,
        context: context, // 컨텍스트 전달
        onSuccess: (message) async {
          if (!mounted) return;

          // 성공 메시지 표시
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          // 결제 완료 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentCompletionPage(
                    product: widget.product,
                    itemId: widget.itemId,
                    buyerName: widget.buyerName,
                    sellerName: widget.sellerName ?? "판매자",
                    startDate: widget.startDate,
                    endDate: widget.endDate,
                    totalPrice: widget.totalPrice,
                    deposit: widget.deposit,
                  ),
            ),
          );
        },
        onError: (errorMessage) {
          if (!mounted) return;

          // 오류 메시지 표시
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));

          setState(() {
            _isProcessing = false;
          });
        },
      );
    } catch (e) {
      // HTTP 400 에러는 payment_service.dart에서 처리됨
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
