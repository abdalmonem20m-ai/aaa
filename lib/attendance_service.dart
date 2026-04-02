import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // تسجيل الحضور أو الانصراف
  Future<void> markAttendance(String uid, String userName, String role, bool isCheckIn) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    await _db.collection('attendance').doc("${today}_$uid").set({
      'uid': uid,
      'name': userName,
      'role': role,
      'date': today,
      isCheckIn ? 'checkIn' : 'checkOut': FieldValue.serverTimestamp(),
      'status': isCheckIn ? 'present' : 'left',
    }, SetOptions(merge: true));
  }

  // جلب حضور اليوم للمدير
  Stream<List<Map<String, dynamic>>> getTodayAttendance() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _db
        .collection('attendance')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}