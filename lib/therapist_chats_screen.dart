import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'animated_background.dart';
import 'therapy_service.dart';
import 'library_service.dart';
import '../models/user_model.dart';

class TherapistChatsScreen extends StatelessWidget {
  final LibraryItem? libraryItemToSend; // إذا تم فتحه من المكتبة لإرسال مادة
  final TherapyService _therapyService = TherapyService();
  final String currentTherapistId = FirebaseAuth.instance.currentUser?.uid ?? "";

  TherapistChatsScreen({this.libraryItemToSend});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AppBackground(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                AppBar(
                  title: Text(libraryItemToSend != null ? "إرسال مادة المكتبة" : "المحادثات"),
                  backgroundColor: Colors.transparent,
                  bottom: TabBar(
                    tabs: [
                      Tab(text: "المرضى"),
                      Tab(text: "المجموعات العلاجية"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPatientsList(),
                      _buildGroupsList(),
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

  Widget _buildPatientsList() {
    return StreamBuilder<List<AppUser>>(
      stream: _therapyService.getPatientsForTherapist(currentTherapistId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final patients = snapshot.data!;
        if (patients.isEmpty) return Center(child: Text("لا يوجد مرضى حالياً", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              leading: CircleAvatar(child: Text(patient.name[0])),
              title: Text(patient.name, style: TextStyle(color: Colors.white)),
              trailing: libraryItemToSend != null
                  ? ElevatedButton(onPressed: () => _sendToPatient(context, patient), child: Text("إرسال"))
                  : Icon(Icons.chat, color: Colors.amber),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _therapyService.getTherapistGroups(currentTherapistId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final groups = snapshot.data!;
        if (groups.isEmpty) return Center(child: Text("لا توجد مجموعات علاجية", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              leading: CircleAvatar(child: Icon(Icons.group), backgroundColor: Colors.amber),
              title: Text(group['name'] ?? "مجموعة علاجة", style: TextStyle(color: Colors.white)),
              trailing: libraryItemToSend != null
                  ? ElevatedButton(onPressed: () => _sendToGroup(context, group['id']), child: Text("إرسال للكل"))
                  : Icon(Icons.group_work, color: Colors.amber),
            );
          },
        );
      },
    );
  }

  void _sendToPatient(BuildContext context, AppUser patient) async {
    await _therapyService.sendLibraryContentToChat(
      chatId: "${currentTherapistId}_${patient.uid}", // معرف بسيط للدردشة
      content: "مادة من المكتبة: ${libraryItemToSend!.title}\n\n${libraryItemToSend!.content}",
      senderId: currentTherapistId,
      mentionUserId: patient.uid,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم إرسال المادة إلى ${patient.name}"))
    );
  }

  void _sendToGroup(BuildContext context, String groupId) async {
    await _therapyService.sendLibraryContentToGroup(
      groupId: groupId,
      content: "مادة من المكتبة للمجموعة: ${libraryItemToSend!.title}\n\n${libraryItemToSend!.content}",
      senderId: currentTherapistId,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم إرسال المادة لجميع أعضاء المجموعة"))
    );
  }
}