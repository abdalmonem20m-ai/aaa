import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'admin_management_screen.dart';
import 'admin_approve_stories_screen.dart';
import 'admin_new_cases_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_create_group_screen.dart';
import 'admin_live_calls_screen.dart';
import 'admin_recorded_calls_screen.dart';
import 'admin_chat_monitoring_screen.dart';
import 'admin_users_management_screen.dart';
import 'admin_school_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: Text("لوحة الإدارة العليا"),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(icon: Icon(Icons.notifications_active, color: Colors.amber), onPressed: () {}),
                ],
              ),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.all(20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  children: [
                    _buildMenuCard(context, "توزيع الحالات", Icons.assignment_ind, AdminNewCasesScreen()),
                    _buildMenuCard(context, "قصص الشفاء", Icons.auto_awesome, AdminApproveStoriesScreen()),
                    _buildMenuCard(context, "إدارة الطاقم", Icons.people_alt, AdminManagementScreen()),
                    _buildMenuCard(context, "الحضور والاتصال", Icons.fact_check, AdminAttendanceScreen()),
                    _buildMenuCard(context, "الإحصائيات", Icons.analytics, AdminStatisticsScreen()),
                    _buildMenuCard(context, "الأقسام الإدارية", Icons.business_center, AdminDepartmentsScreen()),
                    _buildMenuCard(context, "إنشاء مجموعة", Icons.group_add, AdminCreateGroupScreen()),
                    _buildMenuCard(context, "مراقبة المكالمات", Icons.graphic_eq, AdminLiveCallsScreen()),
                    _buildMenuCard(context, "المكالمات المسجلة", Icons.history, AdminRecordedCallsScreen()),
                    _buildMenuCard(context, "مراقبة الدردشات", Icons.visibility, AdminChatMonitoringScreen()),
                    _buildMenuCard(context, "إدارة المستخدمين", Icons.manage_accounts, AdminUsersManagementScreen()),
                    _buildMenuCard(context, "إدارة المدرسة", Icons.school, AdminSchoolManagementScreen()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget? target) {
    return InkWell(
      onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.amber),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}