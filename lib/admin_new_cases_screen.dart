import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminNewCasesScreen extends StatelessWidget {
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: Text("الحالات الجديدة (توزيع المرضى)"),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: StreamBuilder<List<HealingCase>>(
                  stream: _therapyService.getNewCases(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final cases = snapshot.data!;
                    if (cases.isEmpty) return Center(child: Text("لا توجد حالات جديدة حالياً", style: TextStyle(color: Colors.white)));

                    return ListView.builder(
                      itemCount: cases.length,
                      itemBuilder: (context, index) => _buildNewCaseCard(context, cases[index]),
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

  Widget _buildNewCaseCard(BuildContext context, HealingCase c) {
    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white10,
      child: ListTile(
        title: Text("مريض جديد: ${c.patientId}", style: TextStyle(color: Colors.white)),
        subtitle: Text("تاريخ التسجيل: ${c.createdAt.toString().split(' ')[0]}", style: TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: () => _showAssignDialog(context, c),
          child: Text("إسناد للمجموعة"),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, HealingCase healingCase) {
    AppUser? selectedSupervisor;
    AppUser? selectedTherapist;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<List<AppUser>>(
            stream: _therapyService.getAllUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              
              final supervisors = snapshot.data!.where((u) => u.role == UserRole.supervisor).toList();
              final therapists = snapshot.data!.where((u) => 
                u.role == UserRole.therapist && 
                (selectedSupervisor == null || u.supervisorId == selectedSupervisor!.uid)
              ).toList();

              return AlertDialog(
                title: Text("إسناد المريض لمجموعة"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AppUser>(
                      decoration: InputDecoration(labelText: "اختر المشرف (المجموعة)"),
                      items: supervisors.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSupervisor = val;
                          selectedTherapist = null; // إعادة تعيين المعالج عند تغيير المشرف
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<AppUser>(
                      decoration: InputDecoration(labelText: "اختر المعالج"),
                      items: therapists.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (val) => setState(() => selectedTherapist = val),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
                  ElevatedButton(
                    onPressed: (selectedSupervisor != null && selectedTherapist != null)
                      ? () async {
                          await _therapyService.assignOrTransferCase(
                            healingCase.id, 
                            selectedTherapist!.uid, 
                            selectedSupervisor!.uid
                          );
                          Navigator.pop(context);
                        }
                      : null,
                    child: Text("تأكيد الإسناد"),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}