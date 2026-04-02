import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum LibraryItemType { audio, text }

class LibraryItem {
  final String id;
  final String title;
  final String content; // رابط الصوت أو النص البرمجي
  final LibraryItemType type;

  LibraryItem({required this.id, required this.title, required this.content, required this.type});

  factory LibraryItem.fromMap(Map<String, dynamic> map, String id) {
    return LibraryItem(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] == 'audio' ? LibraryItemType.audio : LibraryItemType.text,
    );
  }
}

class LibraryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب محتويات المكتبة
  Stream<List<LibraryItem>> getLibraryItems(LibraryItemType type) {
    return _db.collection('library')
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LibraryItem.fromMap(doc.data(), doc.id)).toList());
  }

  // رفع مادة جديدة للمكتبة (للمديرين)
  Future<void> addToLibrary(String title, String content, LibraryItemType type) async {
    await _db.collection('library').add({
      'title': title,
      'content': content,
      'type': type.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}