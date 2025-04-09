import 'package:flutter/material.dart';
import 'package:renty_client/signUp/signUpData.dart';
import 'package:renty_client/login.dart';

class SignupConfirmPage extends StatefulWidget {
  final SignupData signupData;

  const SignupConfirmPage({super.key, required this.signupData});

  @override
  _SignupConfirmPageState createState() => _SignupConfirmPageState();
}

class _SignupConfirmPageState extends State<SignupConfirmPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.signupData.name);
    emailController = TextEditingController(text: widget.signupData.email);
    passwordController = TextEditingController(text: widget.signupData.pw);
    phoneController = TextEditingController(text: widget.signupData.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: '$label 입력',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3182F6), width: 2),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text('입력하신 정보를 확인해주세요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 32),

              _buildField('이름', nameController),
              _buildField('이메일', emailController),
              _buildField('비밀번호', passwordController, obscure: true),
              _buildField('전화번호', phoneController),

              Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final updatedData = widget.signupData.copyWith(
                      name: nameController.text,
                      email: emailController.text,
                      pw: passwordController.text,
                      phone: phoneController.text,
                    );

                    // TODO: 서버 전송
                    print(updatedData);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3182F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('회원가입 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

