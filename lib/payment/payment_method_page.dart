import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat/chat.dart';
import '../chat/trade_button_service.dart';

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
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final int deposit;

  const PaymentMethodPage({
    Key? key,
    required this.product,
    required this.itemId,
    required this.buyerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deposit,
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
    '신한카드', '삼성카드', '현대카드', '국민카드', 'NH농협카드', '롯데카드',
    'BC카드', '하나카드', '우리카드', '씨티카드', '기타'
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
        icon: '💳',
        isPopular: true,
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
                            child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
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
                        fontWeight: FontWeight.bold
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
                  onPressed: _isAgreementChecked && !_isProcessing
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
                  child: _isProcessing
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
                child: Text(
                  method.icon,
                  style: const TextStyle(fontSize: 18),
                ),
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
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.bold
          ),
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
              items: _cardCompanies.map((String company) {
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _installmentOptions.map((int months) {
                final isSelected = _selectedInstallment == months;
                String label = months == 0 ? '일시불' : '$months개월';
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInstallment = months;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3154FF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3154FF) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.bold
          ),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
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
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3154FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 약관 상세 내용 다이얼로그
  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            '이것은 $title 내용입니다. 실제 약관 내용이 여기에 표시됩니다.\n\n'
            '1. 본 약관은 렌티 서비스 이용에 관한 약관입니다.\n'
            '2. 회사는 본 약관에 동의한 회원에게 서비스를 제공합니다.\n'
            '3. 회원은 본 약관을 준수해야 합니다.\n'
            '4. 대여 물품 훼손 시 보증금에서 차감될 수 있습니다.\n'
            '5. 상품 수령 후 취소는 불가능합니다.\n'
            '...\n'
            '20. 본 약관은 대한민국 법률에 따라 규정됩니다.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  // 결제 처리 함수
  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    
    // 결제 처리 시뮬레이션 (실제로는 결제 API 호출)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // 결제 완료 후 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결제가 성공적으로 완료되었습니다!')),
    );
    
    // 결과 페이지로 이동 또는 채팅방으로 돌아가기
    // 여기서는 채팅방으로 돌아가는 것으로 구현
    Navigator.popUntil(context, (route) {
      // 채팅방까지 모든 페이지를 팝
      return route.isFirst || route.settings.name == '/chat_screen';
    });
    
    setState(() {
      _isProcessing = false;
    });
  }
}