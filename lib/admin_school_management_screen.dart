import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'school_service.dart';
import 'therapy_service.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                        return Card(
                          color: Colors.white10,
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(student.name, style: TextStyle(color: Colors.white)),
                            subtitle: Text("أنهى المستوى: ${student.studentLevel}", style: TextStyle(color: Colors.amber)),
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