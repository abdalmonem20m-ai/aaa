import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'animated_background.dart';
import 'therapy_service.dart';

class SubmitHealingStoryScreen extends StatefulWidget {
  final String caseId;
  SubmitHealingStoryScreen({required this.caseId});

  @override
  _SubmitHealingStoryScreenState createState() => _SubmitHealingStoryScreenState();
}

class _SubmitHealingStoryScreenState extends State<SubmitHealingStoryScreen> {
  final TherapyService _therapyService = TherapyService();
  final TextEditingController _reportController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _mediaFiles = [];
  bool _isUploading = false;

  Future<void> _pickMedia() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _mediaFiles.add(File(file.path));
      });
    }
  }

  Future<void> _submit() async {
    if (_reportController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("يرجى كتابة التقرير أولاً")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> evidenceUrls = [];
      for (var file in _mediaFiles) {
        String fileName = 'evidence/${widget.caseId}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        evidenceUrls.add(await ref.getDownloadURL());
      }

      await _therapyService.completeCase(widget.caseId, _reportController.text, evidenceUrls: evidenceUrls);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال قصة الشفاء بنجاح للمراجعة")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الرفع: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppBar(title: Text("إرسال قصة شفاء"), backgroundColor: Colors.transparent, elevation: 0),
                TextField(
                  controller: _reportController,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "تفاصيل حالة الشفاء",
                    labelStyle: TextStyle(color: Colors.amber),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickMedia,
                  icon: Icon(Icons.add_a_photo),
                  label: Text("إضافة صور/فيديو للإثبات"),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.all(8),
                            width: 100,
                            height: 100,
                            child: Image.file(_mediaFiles[index], fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => setState(() => _mediaFiles.removeAt(index)),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                if (_isUploading)
                  CircularProgressIndicator(color: Colors.amber)
                else
                  ElevatedButton(onPressed: _submit, child: Text("حفظ وإتمام الحالة")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}