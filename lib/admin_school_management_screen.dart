import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'school_service.dart';
import 'therapy_service.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class AdminSchoolManagementScreen extends StatelessWidget {
  final SchoolService _schoolService = SchoolService();
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("إدارة المدرسة والاختبارات"), backgroundColor: Colors.transparent),
              Expanded(
                child: StreamBuilder<List<AppUser>>(
                  stream: _therapyService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final studentsWaiting = snapshot.data!.where((u) => u.waitingForTest).toList();

                    if (studentsWaiting.isEmpty) return Center(child: Text("لا توجد طلبات اختبار حالياً", style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: studentsWaiting.length,
                      itemBuilder: (context, index) {
                        final student = studentsWaiting[index];
                        return Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.white.withOpacity(0.05),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(student.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text("أنهى المستوى: ${student.studentLevel}", style: TextStyle(color: Colors.greenAccent)),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chat, color: Colors.blueAccent),
                                  onPressed: () => _joinChat(context, student),
                                  tooltip: "انضمام للدردشة",
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => _handleResult(context, student, true),
                                  child: Text("ناجح"),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => _handleResult(context, student, false),
                                  child: Text("راسب"),
                                ),
                              ],
                            ),
                          ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _joinChat(BuildContext context, AppUser student) async {
    if (student.currentTestGroupId != null) {
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      await _schoolService.joinTestGroup(student.currentTestGroupId!, adminUid);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم الانضمام لمجموعة الاختبار")));
      // يمكن هنا إضافة Navigator لفتح شاشة الدردشة مباشرة
    }
  }

  void _handleResult(BuildContext context, AppUser student, bool passed) async {
    await _schoolService.setTestResult(student.uid, passed, student.studentLevel);
    
    // إذا كان الطالب في آخر مستوى ونجح، يمكن للمدير تحويله لمعالج يدوياً من شاشة إدارة المستخدمين
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(passed ? "تم نقل الطالب للمستوى التالي" : "تم تسجيل رسوب الطالب في الاختبار"),
    ));
  }
}