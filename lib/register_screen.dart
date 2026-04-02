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
  bool _isLoading = false;

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
                  Text("إنشاء حساب جديد", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: "الاسم الكامل", labelStyle: TextStyle(color: Colors.white70)),
                    validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: "البريد الإلكتروني", labelStyle: TextStyle(color: Colors.white70)),
                    validator: (v) => v!.contains('@') ? null : "بريد إلكتروني غير صحيح",
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: "كلمة المرور", labelStyle: TextStyle(color: Colors.white70)),
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
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text("إنشاء الحساب"),
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
}
