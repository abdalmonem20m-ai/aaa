import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';

class AdminApproveStoriesScreen extends StatelessWidget {
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
                title: Text("إدارة قصص الشفاء"),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: StreamBuilder<List<HealingCase>>(
                  stream: _therapyService.getCompletedCases(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final cases = snapshot.data!;
                    if (cases.isEmpty) return Center(child: Text("لا توجد حالات مكتملة حالياً", style: TextStyle(color: Colors.white)));

                    return ListView.builder(
                      itemCount: cases.length,
                      itemBuilder: (context, index) => _buildApprovalCard(context, cases[index]),
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

  Widget _buildApprovalCard(BuildContext context, HealingCase c) {
    return Card(
      margin: EdgeInsets.all(10),
      color: Colors.white10,
      child: ExpansionTile(
        title: Text("مريض: ${c.patientId}", style: TextStyle(color: Colors.white)),
        subtitle: Text(
          c.isApprovedForPublic ? "الحالة: منشورة للعامة" : "الحالة: بانتظار الموافقة",
          style: TextStyle(color: c.isApprovedForPublic ? Colors.greenAccent : Colors.amberAccent),
        ),
        trailing: Switch(
          value: c.isApprovedForPublic,
          onChanged: (val) async {
            await _therapyService.toggleStoryApproval(c.id, val);
          },
          activeColor: Colors.amber,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("التقرير الطبي:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text(c.report, style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                Text("عدد الأدلة المرفقة: ${c.evidenceUrls.length}", style: TextStyle(color: Colors.white54)),
              ],
            ),
          )
        ],
      ),
    );
  }
}