import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'therapy_service.dart';
import 'voice_room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLiveCallsScreen extends StatefulWidget {
  @override
  _AdminLiveCallsScreenState createState() => _AdminLiveCallsScreenState();
}

class _AdminLiveCallsScreenState extends State<AdminLiveCallsScreen> {
  final TherapyService _therapyService = TherapyService();
  final VoiceTherapyRoom _voiceRoom = VoiceTherapyRoom();
  String? _monitoringChannelId; // لتتبع القناة التي يراقبها المدير حالياً

  @override
  Widget build(BuildContext context) {
    final currentAdmin = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("المكالمات الجارية الآن"), backgroundColor: Colors.transparent),
              // جزء عرض الدعوات الواردة
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _therapyService.getMonitoringInvitations(currentAdmin?.uid ?? ""),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Container(
                      color: Colors.amber.withOpacity(0.9),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: snapshot.data!.map((inv) => ListTile(
                          title: Text("دعوة من ${inv['fromName']} لمراقبة ${inv['channelTitle']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('monitoring_invitations').doc(inv['id']).update({'status': 'accepted'});
                                  _joinAsMonitor(context, inv['channelId']);
                                },
                                child: Text("انضمام"),
                              ),
                              IconButton(icon: Icon(Icons.close), onPressed: () {
                                FirebaseFirestore.instance.collection('monitoring_invitations').doc(inv['id']).update({'status': 'rejected'});
                              }),
                            ],
                          ),
                        )).toList(),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _therapyService.getActiveCalls(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final calls = snapshot.data!;
                    if (calls.isEmpty) return Center(child: Text("لا توجد مكالمات نشطة حالياً", style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: calls.length,
                      itemBuilder: (context, index) {
                        final call = calls[index];
                        return Card(
                          color: Colors.white10,
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            leading: Icon(Icons.record_voice_over, color: Colors.redAccent),
                            title: Text(call['title'] ?? "غرفة علاجية", style: TextStyle(color: Colors.white)),
                            subtitle: Text("المضيف: ${call['hostName']}", style: TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    call['isRecording'] == true ? Icons.stop_circle : Icons.fiber_manual_record,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _toggleRecording(call['channelId'], call['isRecording'] ?? false),
                                ),
                                if (_monitoringChannelId == call['channelId'])
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => _leaveMonitor(context),
                                    child: Text("خروج"),
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _monitoringChannelId != null ? Colors.grey : Colors.blueGrey,
                                    ),
                                    onPressed: _monitoringChannelId != null ? null : () => _joinAsMonitor(context, call['channelId']),
                                    child: Text("دخول صامت"),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.person_add, color: Colors.amber),
                                  onPressed: () => _showSummonDialog(context, call['channelId'], call['title'] ?? "مكالمة"),
                                  tooltip: "استدعاء مسؤول",
                                ),
                              ],
                            ),
                          ),
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

  void _toggleRecording(String channelId, bool isCurrentlyRecording) async {
    // ملاحظة: هنا يجب استدعاء Firebase Cloud Function للتحكم بـ Agora Cloud Recording
    // كمثال للواجهة، سنقوم فقط بتحديث الحالة في Firestore
    await _therapyService.updateRecordingStatus(channelId, !isCurrentlyRecording);
    
    // في الحقيقة، سنقوم بشيء مثل:
    // HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('toggleAgoraRecording');
    // await callable.call({'channelName': channelId, 'action': isCurrentlyRecording ? 'stop' : 'start'});
  }

  void _joinAsMonitor(BuildContext context, String channelId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.hashCode ?? 0;
    // تم تفعيل isSilent: true في وظيفة joinRoom سابقاً لمنع تشغيل الميكروفون للمدير
    await _voiceRoom.initAgora(FirebaseAuth.instance.currentUser!.uid);
    await _voiceRoom.joinRoom(channelId, uid, UserRole.superAdmin, isSilent: true);
    setState(() {
      _monitoringChannelId = channelId;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("أنت الآن في وضع السماع الصامت")));
  }

  void _leaveMonitor(BuildContext context) async {
    await _voiceRoom.leaveRoom();
    setState(() {
      _monitoringChannelId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم الخروج من وضع المراقبة")));
  }

  void _showSummonDialog(BuildContext context, String channelId, String title) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<AppUser>>(
        stream: _therapyService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          final admins = snapshot.data!.where((u) => 
            (u.role == UserRole.adminStaff || u.role == UserRole.superAdmin) && 
            u.uid != FirebaseAuth.instance.currentUser?.uid
          ).toList();

          return AlertDialog(
            backgroundColor: Color(0xFF003311),
            title: Text("استدعاء مسؤول للمراقبة", style: TextStyle(color: Colors.amber)),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: admins.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(admins[index].name, style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await _therapyService.sendMonitoringInvitation(
                      fromName: "المدير", // يمكن جلب الاسم الفعلي من Auth
                      toAdminUid: admins[index].uid,
                      channelId: channelId,
                      channelTitle: title,
                    );
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