import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'animated_background.dart';
import 'school_service.dart';

class StudentOathScreen extends StatefulWidget {
  @override
  _StudentOathScreenState createState() => _StudentOathScreenState();
}

class _StudentOathScreenState extends State<StudentOathScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final SchoolService _schoolService = SchoolService();
  
  List<String?> _recordedPaths = [null, null, null];
  int _currentStep = 0;
  bool _isRecording = false;

  final List<String> _oathTexts = [
    "القسم الأول: أقسم بالله العظيم أن أحفظ أسرار المرضى...",
    "القسم الثاني: أقسم بالله العظيم أن أخلص في عملي وعلاجي...",
    "القسم الثالث: أقسم بالله العظيم أن ألتزم بتعاليم المدرسة..."
  ];

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/oath_${_currentStep}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedPaths[_currentStep] = path;
    });
  }

  Future<void> _uploadAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<File> files = _recordedPaths.map((path) => File(path!)).toList();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    await _schoolService.uploadOathRecordings(uid, files);
    
    Navigator.pop(context); // إغلاق التحميل
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم رفع القسم بنجاح، أنت الآن في مرحلة الانتظار")));
    Navigator.pop(context); // العودة للشاشة السابقة
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool allFinished = _recordedPaths.every((path) => path != null);

    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                AppBar(title: Text("أداء القسم الصوتي"), backgroundColor: Colors.transparent, elevation: 0),
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: Colors.white24,
                  color: Colors.amber,
                ),
                SizedBox(height: 40),
                Text("المرحلة ${_currentStep + 1} من 3", style: TextStyle(color: Colors.amber, fontSize: 18)),
                SizedBox(height: 20),
                Card(
                  color: Colors.white10,
                  padding: EdgeInsets.all(20),
                  child: Text(
                    _oathTexts[_currentStep],
                    style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                Spacer(),
                if (_recordedPaths[_currentStep] == null)
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: _isRecording ? Colors.red : Colors.amber,
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40, color: Colors.black),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _recordedPaths[_currentStep] = null),
                      ),
                      Text("تم تسجيل المقطع", style: TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                Text(_isRecording ? "جارِ التسجيل... ارفع يدك عند الانتهاء" : "اضغط مطولاً للتسجيل", 
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      ElevatedButton(onPressed: () => setState(() => _currentStep--), child: Text("السابق")),
                    if (_currentStep < 2)
                      ElevatedButton(onPressed: _recordedPaths[_currentStep] != null ? () => setState(() => _currentStep++) : null, child: Text("التالي")),
                    if (_currentStep == 2 && allFinished)
                      ElevatedButton(onPressed: _uploadAll, child: Text("إرسال القسم النهائي"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}