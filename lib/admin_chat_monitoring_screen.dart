import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'animated_background.dart';
import 'therapy_service.dart';

class AdminChatMonitoringScreen extends StatelessWidget {
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    final currentAdmin = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("مراقبة المحادثات الجارية"), backgroundColor: Colors.transparent),
              
              // جزء عرض دعوات الاستدعاء اللحظية للمحادثات
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _therapyService.getMonitoringInvitations(currentAdmin?.uid ?? ""),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: snapshot.data!.map((inv) => ListTile(
                          leading: Icon(Icons.emergency_share, color: Colors.black),
                          title: Text("استدعاء من ${inv['fromName']}", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("لمراقبة دردشة: ${inv['channelTitle']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.amber),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('monitoring_invitations').doc(inv['id']).update({'status': 'accepted'});
                                  _navigateToChat(context, inv['channelId']);
                                },
                                child: Text("دخول"),
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
                  stream: _therapyService.getAllActiveChats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final chats = snapshot.data!;
                    
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ListTile(
                          leading: Icon(Icons.chat_bubble_outline, color: Colors.amber),
                          title: Text(chat['title'] ?? "محادثة", style: TextStyle(color: Colors.white)),
                          subtitle: Text("آخر رسالة: ${chat['lastMessage']}", 
                                    style: TextStyle(color: Colors.white54), maxLines: 1),
                          trailing: ElevatedButton(
                            child: Text("دخول ومراقبة"),
                            onPressed: () {
                              _navigateToChat(context, chat['id']);
                            },
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

  void _navigateToChat(BuildContext context, String chatId) {
    // الانتقال لصفحة الدردشة بوضع "المراقب" (Read Only)
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chatId, isReadOnly: true)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("جاري الدخول لمراقبة الدردشة: $chatId")));
  }
}