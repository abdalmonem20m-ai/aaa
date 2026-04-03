import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'library_service.dart';
import 'therapy_service.dart';
import 'voice_room.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'therapist_chats_screen.dart';
import 'dart:ui';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  final TherapyService _therapyService = TherapyService();
  final VoiceTherapyRoom _voiceRoom = VoiceTherapyRoom(); // يجب تمرير النسخة المفعلة فعلياً
  
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
                  title: _isSearching ? _buildSearchField() : Text("المكتبة العلاجية"),
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) _searchController.clear();
                          _searchQuery = "";
                        });
                      },
                    ),
                  ],
                  bottom: TabBar(
                    indicatorColor: Colors.greenAccent,
                    labelColor: Colors.greenAccent,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(icon: Icon(Icons.audiotrack), text: "صوتيات"),
                      Tab(icon: Icon(Icons.description), text: "رقية مكتوبة"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLibraryList(LibraryItemType.audio),
                      _buildLibraryList(LibraryItemType.text),
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

  bool _isSearching = false;

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "ابحث عن عنوان أو محتوى...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => setState(() => _searchQuery = query),
    );
  }

  Widget _buildLibraryList(LibraryItemType type) {
    return StreamBuilder<List<LibraryItem>>(
      stream: _libraryService.getLibraryItems(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        // تصفية العناصر بناءً على البحث
        final items = snapshot.data!.where((item) {
          final title = item.title.toLowerCase();
          final query = _searchQuery.toLowerCase();
          return title.contains(query);
        }).toList();

        if (items.isEmpty) return Center(child: Text("لا توجد نتائج مطابقة", style: TextStyle(color: Colors.white54)));
        
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.05),
                    child: ListTile(
                      title: Text(item.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(type == LibraryItemType.audio ? "مقطع صوتي" : "نص رقية", 
                                style: TextStyle(color: Colors.greenAccent.withOpacity(0.7))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.greenAccent),
                            onPressed: () => _showChatSelection(context, item),
                            tooltip: "إرسال لمريض",
                          ),
                          if (type == LibraryItemType.audio)
                            IconButton(
                              icon: Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                              onPressed: () => _voiceRoom.playHealingAudio(item.content),
                              tooltip: "تشغيل في الغرفة",
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChatSelection(BuildContext context, LibraryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TherapistChatsScreen(
          libraryItemToSend: item,
        ),
      ),
    );
  }
}