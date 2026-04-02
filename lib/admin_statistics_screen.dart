import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminStatisticsScreen extends StatelessWidget {
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
                title: Text("الإحصائيات العامة للمدير"),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: StreamBuilder<List<AppUser>>(
                  stream: _therapyService.getAllUsers(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                      return Center(child: Text("لا يوجد مستخدمون", style: TextStyle(color: Colors.white)));
                    }

                    final allUsers = userSnapshot.data!;
                    final supervisors = allUsers.where((u) => u.role == UserRole.supervisor).toList();
                    final therapists = allUsers.where((u) => u.role == UserRole.therapist).toList();

                    return StreamBuilder<List<HealingCase>>(
                      stream: _therapyService.getAllCases(),
                      builder: (context, caseSnapshot) {
                        if (caseSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!caseSnapshot.hasData || caseSnapshot.data!.isEmpty) {
                          return Center(child: Text("لا توجد حالات", style: TextStyle(color: Colors.white)));
                        }

                        final allCases = caseSnapshot.data!;
                        return ListView(
                          children: [
                            _buildGeneralStatsCard(allCases),
                            ...supervisors.map((supervisor) => _buildSupervisorStats(supervisor, therapists, allCases)).toList(),
                          ],
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

  Widget _buildGeneralStatsCard(List<HealingCase> allCases) {
    final totalCases = allCases.length;
    final completedCases = allCases.where((c) => c.status == CaseStatus.completed).length;
    final inProgressCases = allCases.where((c) => c.status == CaseStatus.inProgress).length;
    final newCases = allCases.where((c) => c.status == CaseStatus.newCase).length;

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("إحصائيات عامة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Text("إجمالي الحالات: $totalCases", style: TextStyle(color: Colors.white70)),
            Text("حالات مكتملة: $completedCases", style: TextStyle(color: Colors.greenAccent)),
            Text("حالات قيد المعالجة: $inProgressCases", style: TextStyle(color: Colors.amberAccent)),
            Text("حالات جديدة: $newCases", style: TextStyle(color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorStats(AppUser supervisor, List<AppUser> allTherapists, List<HealingCase> allCases) {
    final supervisedTherapists = allTherapists.where((t) => t.supervisorId == supervisor.uid).toList();
    final supervisorCases = allCases.where((c) => c.supervisorId == supervisor.uid).toList();
    final completedSupervisorCases = supervisorCases.where((c) => c.status == CaseStatus.completed).length;

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.1),
      child: ExpansionTile(
        title: Text("المشرف: ${supervisor.name}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("عدد المعالجين: ${supervisedTherapists.length} | حالات مكتملة: $completedSupervisorCases", style: TextStyle(color: Colors.white70)),
        children: [
          ...supervisedTherapists.map((therapist) => _buildTherapistStats(therapist, allCases)).toList(),
        ],
      ),
    );
  }

  Widget _buildTherapistStats(AppUser therapist, List<HealingCase> allCases) {
    final therapistCases = allCases.where((c) => c.assignedHealerId == therapist.uid).toList();
    final completedTherapistCases = therapistCases.where((c) => c.status == CaseStatus.completed).length;
    final inProgressTherapistCases = therapistCases.where((c) => c.status == CaseStatus.inProgress).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        color: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("المعالج: ${therapist.name}", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("إجمالي الحالات: ${therapistCases.length}", style: TextStyle(color: Colors.white70)),
              Text("حالات مكتملة: $completedTherapistCases", style: TextStyle(color: Colors.greenAccent)),
              Text("حالات قيد المعالجة: $inProgressTherapistCases", style: TextStyle(color: Colors.amberAccent)),
            ],
          ),
        ),
      ),
    );
  }
}