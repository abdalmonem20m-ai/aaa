import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class SupervisorDashboardScreen extends StatelessWidget {
  final TherapyService _therapyService = TherapyService();
  final String currentSupervisorId = FirebaseAuth.instance.currentUser?.uid ?? "";

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
                  title: Text("لوحة تحكم المشرف"),
                  backgroundColor: Colors.transparent,
                  bottom: TabBar(
                    tabs: [
                      Tab(text: "المعالجين التابعين"),
                      Tab(text: "متابعة التقارير"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTherapistsList(),
                      _buildCasesReportsList(),
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

  Widget _buildTherapistsList() {
    return StreamBuilder<List<AppUser>>(
      stream: _therapyService.getTherapistsUnderSupervisor(currentSupervisorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final therapists = snapshot.data!;
        return ListView.builder(
          itemCount: therapists.length,
          itemBuilder: (context, index) {
            final therapist = therapists[index];
            return Card(
              margin: EdgeInsets.all(8),
              color: Colors.white10,
              child: ListTile(
                leading: CircleAvatar(child: Text(therapist.name[0])),
                title: Text(therapist.name, style: TextStyle(color: Colors.white)),
                subtitle: Text(therapist.email, style: TextStyle(color: Colors.white70)),
                trailing: Icon(therapist.status == 'online' ? Icons.circle : Icons.circle_outlined, 
                          color: therapist.status == 'online' ? Colors.green : Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCaseActions(BuildContext context, HealingCase healingCase, List<AppUser> supervisedTherapists) {
    if (healingCase.status == CaseStatus.completed) {
      return Icon(Icons.check_circle, color: Colors.green);
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 'transfer') {
          _showTransferDialog(context, healingCase, supervisedTherapists);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'transfer',
          child: Text('نقل المريض لمعالج آخر'),
        ),
      ],
    );
  }

  Widget _buildCasesReportsList() {
    return StreamBuilder<List<AppUser>>(
      stream: _therapyService.getTherapistsUnderSupervisor(currentSupervisorId),
      builder: (context, therapistSnapshot) {
        final supervisedTherapists = therapistSnapshot.data ?? [];

        return StreamBuilder<List<HealingCase>>(
          stream: _therapyService.getSupervisorCases(currentSupervisorId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final cases = snapshot.data!;
            return ListView.builder(
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final c = cases[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  color: Colors.white10,
                  child: ExpansionTile(
                    title: Text("مريض: ${c.patientId}", style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      "الحالة: ${c.status == CaseStatus.completed ? 'تمت' : 'جاري'} ",
                      style: TextStyle(color: c.status == CaseStatus.completed ? Colors.greenAccent : Colors.amber),
                    ),
                    trailing: _buildCaseActions(context, c, supervisedTherapists),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("تقرير المعالج:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            SizedBox(height: 8),
                            Text(c.report.isEmpty ? "لا يوجد تقرير بعد" : c.report, style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context, HealingCase healingCase, List<AppUser> supervisedTherapists) {
    AppUser? selectedTherapist;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text("نقل المريض: ${healingCase.patientId}"),
          content: DropdownButtonFormField<AppUser>(
            decoration: InputDecoration(labelText: "اختر المعالج الجديد"),
            items: supervisedTherapists.map((therapist) {
              return DropdownMenuItem(
                value: therapist,
                child: Text(therapist.name),
              );
            }).toList(),
            onChanged: (AppUser? newValue) {
              selectedTherapist = newValue;
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (selectedTherapist != null) {
                  await _therapyService.assignOrTransferCase(healingCase.id, selectedTherapist!.uid, currentSupervisorId);
                  Navigator.pop(context);
                }
              },
              child: Text("نقل"),
            ),
          ],
        ),
      ),
    );
  }
}