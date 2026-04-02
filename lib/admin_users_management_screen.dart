import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  @override
  _AdminUsersManagementScreenState createState() => _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState extends State<AdminUsersManagementScreen> {
  final TherapyService _therapyService = TherapyService();
  UserRole? _filterRole;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "بحث بالاسم أو الإيميل...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                backgroundColor: Colors.transparent,
                actions: [
                  if (_searchQuery.isNotEmpty) IconButton(icon: Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }),
                  PopupMenuButton<UserRole?>(
                    icon: Icon(Icons.filter_alt),
                    onSelected: (role) => setState(() => _filterRole = role),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: null, child: Text("الكل")),
                      ...UserRole.values.map((role) => PopupMenuItem(
                        value: role,
                        child: Text(_getRoleName(role)),
                      )),
                    ],
                  )
                ],
              ),
              Expanded(
                child: StreamBuilder<List<AppUser>>(
                  stream: _therapyService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    
                    var users = snapshot.data!;
                    if (_filterRole != null) {
                      users = users.where((u) => u.role == _filterRole).toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      users = users.where((u) => 
                        u.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                        u.email.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) => _buildUserTile(context, users[index]),
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

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return "مدير عام";
      case UserRole.adminStaff: return "إداري";
      case UserRole.supervisor: return "مشرف";
      case UserRole.assistantSupervisor: return "نائب مشرف";
      case UserRole.therapist: return "معالج";
      case UserRole.student: return "طالب";
      case UserRole.patient: return "مريض";
    }
  }

  Widget _buildUserTile(BuildContext context, AppUser user) {
    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white10,
      child: ListTile(
        title: Text(user.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("${_getRoleName(user.role)} | ${user.email}", style: TextStyle(color: Colors.white70)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.settings_suggest, color: Colors.amber),
              onPressed: () => _showPromotionDialog(context, user),
              tooltip: "ترقية أو تعديل الرتبة",
            ),
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, user),
              tooltip: "حذف المستخدم",
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ترقية / تعديل: ${user.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.role == UserRole.student) ...[
              ListTile(
                title: Text("رفع المستوى الدراسي (المستوى الحالي: ${user.studentLevel})"),
                onTap: () {
                  _therapyService.updateStudentLevel(user.uid, user.studentLevel + 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("ترقية إلى معالج"),
                onTap: () {
                  _therapyService.updateUserRole(user.uid, UserRole.therapist);
                  Navigator.pop(context);
                },
              ),
            ],
            if (user.role == UserRole.therapist) ...[
              ListTile(
                title: Text("ترقية إلى نائب مشرف"),
                onTap: () {
                  _therapyService.updateUserRole(user.uid, UserRole.assistantSupervisor);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("ترقية إلى مشرف مجموعة"),
                onTap: () {
                  _therapyService.updateUserRole(user.uid, UserRole.supervisor);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppUser user) {
    // منطق الحذف النهائي بعد التأكيد
  }
}