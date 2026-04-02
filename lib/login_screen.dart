import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard_screen.dart';
import 'therapist_dashboard_screen.dart';
import 'supervisor_dashboard_screen.dart';
import 'school_screen.dart';
import 'healing_stories_screen.dart';
import 'animated_background.dart';
import 'user_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleUserRedirection(AppUser userData) {
    Widget targetScreen;
    switch (userData.role) {
      case UserRole.superAdmin:
      case UserRole.adminStaff:
        targetScreen = AdminDashboardScreen();
        break;
      case UserRole.supervisor:
      case UserRole.assistantSupervisor:
        targetScreen = SupervisorDashboardScreen();
        break;
      case UserRole.therapist:
        targetScreen = TherapistDashboardScreen();
        break;
      case UserRole.student:
        targetScreen = SchoolScreen(student: userData);
        break;
      default:
        targetScreen = HealingStoriesScreen(); // للمرضى والزوار
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        final userData = await _authService.getUserData(credential.user!.uid);
        if (userData != null) {
          _handleUserRedirection(userData);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تسجيل الدخول عبر جوجل: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى إدخال البريد الإلكتروني وكلمة المرور")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (credential != null) {
        final userData = await _authService.getUserData(credential.user!.uid);
        if (userData != null) {
          _handleUserRedirection(userData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تسجيل الدخول، ولكن لم يتم العثور على بيانات الصلاحيات")));
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "فشل تسجيل الدخول";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = "لا يوجد مستخدم بهذا البريد الإلكتروني";
      } else if (e.code == 'wrong-password') {
        errorMessage = "كلمة المرور غير صحيحة";
      } else if (e.code == 'invalid-email') {
        errorMessage = "تنسيق البريد الإلكتروني غير صحيح";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ غير متوقع: $e")));
    } finally {
      setState(() => _isLoading = false);
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/g.jpeg', height: 180),
                  SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "البريد الإلكتروني",
                      labelStyle: TextStyle(color: Colors.amber),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      labelStyle: TextStyle(color: Colors.amber),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    validator: (v) => v!.length < 6 ? "كلمة المرور قصيرة" : null,
                  ),
                  SizedBox(height: 40),
                  _isLoading 
                    ? CircularProgressIndicator(color: Colors.amber)
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) _login();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("تسجيل الدخول", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  SizedBox(height: 10),
                  _isLoading 
                    ? SizedBox.shrink()
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          side: BorderSide(color: Colors.white30),
                        ),
                        icon: Icon(Icons.login, color: Colors.white),
                        label: Text("تسجيل الدخول بواسطة Google", style: TextStyle(color: Colors.white)),
                      ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    ),
                    child: Text("ليس لديك حساب؟ سجل الآن", style: TextStyle(color: Colors.white70)),
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