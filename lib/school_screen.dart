import 'dart:ui';
import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'school_service.dart';
import 'attendance_service.dart';
import 'user_model.dart';

class SchoolScreen extends StatelessWidget {
  final AppUser student; // نمرر بيانات الطالب لمعرفة مستواه الحالي
  final SchoolService _schoolService = SchoolService();
  final AttendanceService _attService = AttendanceService();

  SchoolScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: Text("مدرسة التعليم والتدريب"),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(Icons.how_to_reg, color: Colors.greenAccent),
                    onPressed: () => _handleAttendance(context),
                    tooltip: "تسجيل الحضور",
                  ),
                ],
              ),
              _buildStudentHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: student.studentLevel + 1, // إظهار المستويات المتاحة له فقط
                  itemBuilder: (context, index) => _buildLevelTile(context, index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.greenAccent, child: Icon(Icons.school, color: Colors.black, size: 30)),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("المستوى الحالي: ${student.studentLevel}", style: TextStyle(color: Colors.greenAccent)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLevelTile(BuildContext context, int levelIndex) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ExpansionTile(
            iconColor: Colors.greenAccent,
            collapsedIconColor: Colors.white54,
            title: Text("المستوى $levelIndex", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: Icon(Icons.auto_stories, color: Colors.greenAccent),
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _schoolService.getLessons(levelIndex),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                  final lessons = snapshot.data!;
                  if (lessons.isEmpty) return ListTile(title: Text("لا توجد دروس في هذا المستوى بعد", style: TextStyle(color: Colors.white54)));

                  final now = DateTime.now();
                  final unlockedCount = student.levelStartedAt == null 
                      ? 1 
                      : now.difference(student.levelStartedAt!).inDays + 1;

                  return Column(
                    children: lessons.asMap().entries.map((entry) {
                      int index = entry.key;
                      var lesson = entry.value;
                      final bool isLocked = index >= unlockedCount;

                      return ListTile(
                        enabled: !isLocked,
                        title: Text(lesson['title'] ?? 'درس بدون عنوان', style: TextStyle(color: isLocked ? Colors.white24 : Colors.white)),
                        leading: Icon(_getLessonIcon(lesson['type']), color: isLocked ? Colors.white24 : Colors.greenAccent.withOpacity(0.7)),
                        trailing: Icon(isLocked ? Icons.lock : Icons.play_circle_fill, color: isLocked ? Colors.grey : Colors.greenAccent),
                        onTap: isLocked ? null : () { /* منطق فتح الدرس */ },
                      );
                    }).toList(),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLessonIcon(String? type) {
    switch (type) {
      case 'video': return Icons.videocam;
      case 'audio': return Icons.audiotrack;
      case 'pdf': return Icons.picture_as_pdf;
      default: return Icons.description;
    }
  }

  void _handleAttendance(BuildContext context) async {
    await _attService.markAttendance(student.uid, student.name, "طالب", true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تسجيل حضورك في المدرسة بنجاح")));
  }
}