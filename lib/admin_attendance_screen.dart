import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'attendance_service.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminAttendanceScreen extends StatelessWidget {
  final AttendanceService _attService = AttendanceService();
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                AppBar(
                  title: Text("الحضور وحالة الاتصال"),
                  backgroundColor: Colors.transparent,
                  bottom: TabBar(tabs: [Tab(text: "حضور اليوم"), Tab(text: "المتصلون الآن")]),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTodayAttendance(),
                      _buildOnlineStatus(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAttendance() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _attService.getTodayAttendance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final record = list[index];
            return ListTile(
              title: Text(record['name'], style: TextStyle(color: Colors.white)),
              subtitle: Text("الدور: ${record['role']}", style: TextStyle(color: Colors.white70)),
              trailing: Text(record['checkIn'] != null ? "حضر" : "غائب", 
                style: TextStyle(color: record['checkIn'] != null ? Colors.greenAccent : Colors.redAccent)),
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineStatus() {
    return StreamBuilder<List<AppUser>>(
      stream: _therapyService.getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final onlineUsers = snapshot.data!.where((u) => u.status == 'online').toList();
        final offlineUsers = snapshot.data!.where((u) => u.status != 'online').toList();

        return ListView(
          children: [
            _buildStatusSection("متصل الآن", onlineUsers, Colors.green),
            _buildStatusSection("غير متصل", offlineUsers, Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildStatusSection(String title, List<AppUser> users, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.all(16), child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ...users.map((u) => ListTile(
          leading: CircleAvatar(backgroundColor: color, radius: 5),
          title: Text(u.name, style: TextStyle(color: Colors.white)),
          subtitle: Text(u.role.toString().split('.').last, style: TextStyle(color: Colors.white54)),
        )).toList(),
      ],
    );
  }
}