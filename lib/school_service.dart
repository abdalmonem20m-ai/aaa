import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SchoolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // جلب الأسئلة المحددة من قبل الإدارة
  Future<List<Map<String, dynamic>>> getApplicationQuestions() async {
    var snapshot = await _db.collection('settings').doc('school_form').get();
    return List<Map<String, dynamic>>.from(snapshot.data()?['questions'] ?? []);
  }

  // تقديم الطلب
  Future<void> submitApplication(String uid, Map<String, String> answers) async {
    await _db.collection('school_applications').doc(uid).set({
      'answers': answers,
      'status': 'reviewing',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  // رفع مقاطع القسم الصوتي (3 مقاطع)
  Future<void> uploadOathRecordings(String uid, List<File> audioFiles) async {
    List<String> urls = [];
    for (int i = 0; i < audioFiles.length; i++) {
      var ref = _storage.ref().child('oaths/$uid/oath_$i.m4a');
      await ref.putFile(audioFiles[i]);
      urls.add(await ref.getDownloadURL());
    }
    
    await _db.collection('users').doc(uid).update({
      'oathUrls': urls,
      'studentStatus': 'waiting_for_study', // ينتقل لمرحلة الانتظار
    });
  }

  // جلب الدروس لمستوى معين
  Stream<List<Map<String, dynamic>>> getLessons(int level) {
    return _db
        .collection('lessons')
        .where('level', isEqualTo: level)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // إرسال إشعار للإدارة بانتهاء المستوى وطلب الاختبار
  Future<void> requestLevelTest(String uid, String name, int level) async {
    // 1. إنشاء مجموعة الدردشة الخاصة بالاختبار
    DocumentReference groupRef = await _db.collection('groups').add({
      'name': 'غرفة اختبار: $name - مستوى $level',
      'type': 'test_group',
      'studentUid': uid,
      'healersIds': [uid], // إضافة الطالب ليظهر له الجروب تلقائياً في واجهته
      'createdAt': FieldValue.serverTimestamp(),
    });

    // إضافة رسالة ترحيبية تلقائية توضح التعليمات للطالب
    await groupRef.collection('messages').add({
      'senderId': 'system',
      'text': 'أهلاً بك يا $name في غرفة الاختبار للمستوى $level. يرجى الانتظار حتى ينضم إليك أحد الإداريين لبدء الاختبار. تأكد من جودة الاتصال وتواجدك في مكان هادئ.',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': true,
    });

    // 2. تحديث بيانات الطالب
    await _db.collection('users').doc(uid).update({
      'waitingForTest': true,
      'currentTestGroupId': groupRef.id,
    });

    // 3. إرسال إشعار للإدارة مع رابط المجموعة
    await _db.collection('admin_notifications').add({
      'title': 'طلب اختبار مستوى',
      'body': 'أنهى الطالب $name دروس المستوى $level وينتظر الاختبار.',
      'studentUid': uid,
      'testGroupId': groupRef.id,
      'type': 'school_test',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // نتيجة الاختبار (ناجح/راسب)
  Future<void> setTestResult(String uid, bool passed, int currentLevel) async {
    // جلب معرف مجموعة الاختبار لحذفها
    var userDoc = await _db.collection('users').doc(uid).get();
    String? testGroupId = userDoc.data()?['currentTestGroupId'];

    if (passed) {
      await _db.collection('users').doc(uid).update({
        'studentLevel': currentLevel + 1,
        'levelStartedAt': FieldValue.serverTimestamp(),
        'waitingForTest': false,
        'currentTestGroupId': FieldValue.delete(),
      });
    } else {
      await _db.collection('users').doc(uid).update({
        'waitingForTest': false,
        'currentTestGroupId': FieldValue.delete(),
      });
    }

    // حذف مجموعة الاختبار بعد الانتهاء لضمان نظافة النظام
    if (testGroupId != null) {
      await _db.collection('groups').doc(testGroupId).delete();
    }
  }

  // انضمام الإداري لمجموعة الاختبار
  Future<void> joinTestGroup(String groupId, String adminUid) async {
    await _db.collection('groups').doc(groupId).update({
      'healersIds': FieldValue.arrayUnion([adminUid]),
    });
  }
}