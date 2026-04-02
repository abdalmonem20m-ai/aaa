import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';
import 'attendance_service.dart';
import 'submit_healing_story_screen.dart';

class TherapistDashboardScreen extends StatelessWidget {
  final TherapyService _therapyService = TherapyService();
  final AttendanceService _attService = AttendanceService();
  final String currentTherapistId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: Text("لوحة تحكم المعالج"),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(Icons.how_to_reg, color: Colors.amber),
                    onPressed: () => _handleAttendance(context),
                    tooltip: "تسجيل الحضور",
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<HealingCase>>(
                  stream: _therapyService.getTherapistCases(currentTherapistId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("لا توجد حالات مسندة إليك حالياً", style: TextStyle(color: Colors.white)));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final healingCase = snapshot.data![index];
                        return _buildCaseItem(context, healingCase);
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

  Widget _buildCaseItem(BuildContext context, HealingCase healingCase) {
    bool isDone = healingCase.status == CaseStatus.completed;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        title: Text("معرف المريض: ${healingCase.patientId}", style: TextStyle(color: Colors.white)),
        subtitle: Text(
          isDone ? "الحالة: تمت المعالجة" : "الحالة: جاري العمل",
          style: TextStyle(color: isDone ? Colors.greenAccent : Colors.amberAccent),
        ),
        trailing: !isDone
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitHealingStoryScreen(caseId: healingCase.id),
                  ),
                ),
                child: Text("إتمام"),
              )
            : Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  void _handleAttendance(BuildContext context) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentTherapistId).get();
    if (userDoc.exists) {
      final name = userDoc.data()?['name'] ?? "معالج";
      await _attService.markAttendance(currentTherapistId, name, "معالج", true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تسجيل الحضور بنجاح")));
    }
  }
}