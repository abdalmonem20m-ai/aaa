import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'department_service.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminDepartmentsScreen extends StatelessWidget {
  final DepartmentService _deptService = DepartmentService();
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("إدارة الأقسام الإدارية"), backgroundColor: Colors.transparent),
              Expanded(
                child: StreamBuilder<List<Department>>(
                  stream: _deptService.getDepartments(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final depts = snapshot.data!;
                    return ListView.builder(
                      itemCount: depts.length,
                      itemBuilder: (context, index) => _buildDeptCard(context, depts[index]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showCreateDeptDialog(context),
                  child: Text("إنشاء قسم جديد"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeptCard(BuildContext context, Department dept) {
    return Card(
      color: Colors.white10,
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(dept.name, style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        subtitle: Text("عدد الإداريين: ${dept.assignedAdminIds.length}", style: TextStyle(color: Colors.white70)),
        children: [
          ListTile(
            title: Text("توزيع مسؤول على هذا القسم", style: TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Icon(Icons.add_circle, color: Colors.green),
            onTap: () => _showAssignAdminDialog(context, dept.id),
          ),
        ],
      ),
    );
  }

  void _showCreateDeptDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("اسم القسم الجديد"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              await _deptService.createDepartment(controller.text);
              Navigator.pop(context);
            },
            child: Text("حفظ"),
          )
        ],
      ),
    );
  }

  void _showAssignAdminDialog(BuildContext context, String deptId) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<AppUser>>(
        stream: _therapyService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final admins = snapshot.data!.where((u) => u.role == UserRole.adminStaff).toList();
          return AlertDialog(
            title: Text("اختر المسؤول لتوزيعه"),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: admins.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(admins[index].name),
                  onTap: () async {
                    await _deptService.assignAdminToDepartment(deptId, admins[index].uid);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}