import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'animated_background.dart';
import 'therapy_service.dart';

class AdminRecordedCallsScreen extends StatefulWidget {
  @override
  _AdminRecordedCallsScreenState createState() => _AdminRecordedCallsScreenState();
}

class _AdminRecordedCallsScreenState extends State<AdminRecordedCallsScreen> {
  final TherapyService _therapyService = TherapyService();
  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playRecording(String url, String id) async {
    try {
      if (_currentPlayingId == id && _player.playing) {
        await _player.pause();
      } else {
        await _player.setUrl(url);
        _player.play();
        setState(() => _currentPlayingId = id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في تشغيل الملف")));
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
              AppBar(title: Text("سجل المكالمات المسجلة"), backgroundColor: Colors.transparent),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _therapyService.getRecordedCalls(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final recordings = snapshot.data!;
                    if (recordings.isEmpty) return Center(child: Text("لا توجد تسجيلات", style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final rec = recordings[index];
                        final bool isPlaying = _currentPlayingId == rec['id'] && _player.playing;

                        return Card(
                          color: Colors.white10,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: IconButton(
                                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                                onPressed: () => _playRecording(rec['fileUrl'], rec['id']),
                              ),
                            ),
                            title: Text(rec['title'] ?? "مكالمة مسجلة", style: TextStyle(color: Colors.white)),
                            subtitle: Text("التاريخ: ${rec['createdAt'].toString().split(' ')[0]}", 
                                style: TextStyle(color: Colors.white70)),
                            trailing: Icon(Icons.audio_file, color: Colors.amberAccent),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_currentPlayingId != null)
                Container(
                  color: Colors.black54,
                  padding: EdgeInsets.all(8),
                  child: StreamBuilder<Duration?>(
                    stream: _player.positionStream,
                    builder: (context, snap) => LinearProgressIndicator(
                      value: (snap.data?.inMilliseconds ?? 0) / (_player.duration?.inMilliseconds ?? 1),
                      color: Colors.amber,
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}