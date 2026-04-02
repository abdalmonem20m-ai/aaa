import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'auth_service.dart';

class AdminManagementScreen extends StatefulWidget {
  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final List<String> permissions = [
    "سماع المكالمات (بين المعالج والمرضى)",
    "سماع المكالمات (بين المعالجين)",
    "سماع المكالمات (بين المعالج والمشرف)",
    "مراقبة الدردشات",
    "إدارة الحالات",
    "ترقية المعالجين",
    "إدارة المدرسة",
    "إنشاء أقسام إدارية"
    "مراقبة المعالجين التابعين فقط (للمشرفين)"
  ];

  final Map<String, bool> selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    for (var p in permissions) {
      selectedPermissions[p] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("إدارة الأقسام والصلاحيات"), backgroundColor: Colors.transparent),
              Expanded(
                child: ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white10,
                      child: CheckboxListTile(
                        title: Text(permissions[index], style: TextStyle(color: Colors.white)),
                        value: selectedPermissions[permissions[index]],
                        onChanged: (val) {
                          setState(() => selectedPermissions[permissions[index]] = val!);
                        },
                        activeColor: Colors.amber,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _createNewAdmin(context),
                  child: Text("إنشاء حساب مسؤول جديد"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _createNewAdmin(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text("إنشاء حساب مسؤول جديد"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "البريد الإلكتروني"),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "كلمة المرور"),
                obscureText: true,
              ),
              SizedBox(height: 10),
              Text("سيتم منح الصلاحيات المختارة في الشاشة الرئيسية", 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                // اختبار استدعاء خدمة الإنشاء
                await AuthService().createAdminAccount(
                  emailController.text,
                  passwordController.text,
                  selectedPermissions,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال دعوة المسؤول")));
              },
              child: Text("إنشاء"),
            ),
          ],
        ),
      ),
    );
  }
}