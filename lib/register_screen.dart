import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'user_model.dart';
import 'animated_background.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  UserRole _selectedRole = UserRole.student;
  bool _isButtonPressed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _selectedRole,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إنشاء الحساب بنجاح، يمكنك تسجيل الدخول الآن")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الإنشاء: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "إنشاء حساب جديد",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)], // توهج نيون
                    ),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: _buildNeonInput("الاسم الكامل"),
                    validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: _buildNeonInput("البريد الإلكتروني"),
                    validator: (v) => v!.contains('@') ? null : "بريد إلكتروني غير صحيح",
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: _buildNeonInput("كلمة المرور"),
                    validator: (v) => v!.length < 6 ? "كلمة المرور ضعيفة" : null,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    dropdownColor: Color(0xFF003311),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: "نوع الحساب", labelStyle: TextStyle(color: Colors.white70)),
                    items: [
                      DropdownMenuItem(value: UserRole.student, child: Text("طالب")),
                      DropdownMenuItem(value: UserRole.patient, child: Text("مريض/زائر")),
                      DropdownMenuItem(value: UserRole.therapist, child: Text("معالج")),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  SizedBox(height: 40),
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.amber)
                      : Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 5))
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text("إنشاء الحساب", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("لديك حساب بالفعل؟ سجل دخولك", style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildNeonInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.greenAccent.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.greenAccent, width: 2),
      ),
    );
  }
}
