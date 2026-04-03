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
import 'forgot_password_screen.dart';

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
  bool _isButtonPressed = false;
  bool _isGoogleButtonPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      // تأكد من أن credential و credential.user ليسا null
      if (credential != null && credential.user != null) {
        final userData = await _authService.getUserData(credential.user!.uid);
        if (userData != null) {
          _handleUserRedirection(userData);
        } else {
          // هذا السيناريو يعني أن تسجيل الدخول عبر جوجل نجح، لكن بيانات المستخدم غير موجودة في Firestore
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تسجيل الدخول عبر جوجل، ولكن لم يتم العثور على بيانات الصلاحيات")));
        }
      }
      // إذا كان credential أو credential.user null، فهذا يعني أن عملية تسجيل الدخول عبر جوجل لم تكتمل بنجاح أو تم إلغاؤها
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تسجيل الدخول عبر جوجل أو تم إلغاؤه.")));
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
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "تسجيل الدخول بالبريد معطل في Firebase Console";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ غير متوقع: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
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
                  // شعار بتوهج نيون
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                    ),
                    child: Image.asset('assets/images/g.jpeg', height: 160),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: _buildNeonInput("البريد الإلكتروني"),
                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: _buildNeonInput("كلمة المرور"),
                    validator: (v) => v!.length < 6 ? "كلمة المرور قصيرة" : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                      ),
                      child: Text("نسيت كلمة المرور؟", style: TextStyle(color: Colors.amber, fontSize: 14)),
                    ),
                  ),
                  SizedBox(height: 40),
                  _isLoading 
                    ? CircularProgressIndicator(color: Colors.amber)
                    : GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        child: AnimatedScale(
                          scale: _isButtonPressed ? 0.95 : 1.0,
                          duration: Duration(milliseconds: 100),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.4),
                                  offset: Offset(0, 4),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) _login();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                minimumSize: Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              child: Text("تسجيل الدخول", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                  SizedBox(height: 10),
                  _isLoading 
                    ? SizedBox.shrink()
                    : GestureDetector(
                        onTapDown: (_) => setState(() => _isGoogleButtonPressed = true),
                        onTapUp: (_) => setState(() => _isGoogleButtonPressed = false),
                        onTapCancel: () => setState(() => _isGoogleButtonPressed = false),
                        child: AnimatedScale(
                          scale: _isGoogleButtonPressed ? 0.95 : 1.0,
                          duration: Duration(milliseconds: 100),
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            icon: Icon(Icons.login, color: Colors.greenAccent),
                            label: Text("تسجيل الدخول بواسطة Google", style: TextStyle(color: Colors.white)),
                          ),
                        ),
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