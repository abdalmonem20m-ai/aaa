import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'case_model.dart';

class TherapyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب الحالات المسندة لمعالج معين بشكل فوري (Stream)
  Stream<List<HealingCase>> getTherapistCases(String therapistId) {
    return _db
        .collection('cases')
        .where('assignedHealerId', isEqualTo: therapistId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealingCase.fromMap(doc.data(), doc.id))
            .toList());
  }

  // جلب المعالجين التابعين لمشرف معين
  Stream<List<AppUser>> getTherapistsUnderSupervisor(String supervisorId) {
    return _db
        .collection('users')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('role', isEqualTo: UserRole.therapist.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data()))
            .toList());
  }

  // جلب جميع الحالات التي تحت إشراف مشرف معين (لمتابعة التقارير)
  Stream<List<HealingCase>> getSupervisorCases(String supervisorId) {
    return _db
        .collection('cases')
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealingCase.fromMap(doc.data(), doc.id))
            .toList());
  }

  // تحديث حالة الحالة إلى "تمت المعالجة" مع إضافة تقرير
  Future<void> completeCase(String caseId, String report, {List<String> evidenceUrls = const []}) async {
    await _db.collection('cases').doc(caseId).update({
      'status': CaseStatus.completed.index,
      'report': report,
      'evidenceUrls': evidenceUrls,
    });

    // إضافة إشعار للمدير العام بمراجعة الحالة
    await _db.collection('admin_notifications').add({
      'title': 'مراجعة حالة شفاء',
      'body': 'قام أحد المعالجين بإتمام حالة جديدة، يرجى مراجعة التقرير للموافقة على النشر.',
      'caseId': caseId,
      'type': 'case_completion',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // جلب جميع المستخدمين (للمدير العام)
  Stream<List<AppUser>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }

  // جلب الحالات الجديدة فقط (التي لم تُسند)
  Stream<List<HealingCase>> getNewCases() {
    return _db
        .collection('cases')
        .where('status', isEqualTo: CaseStatus.newCase.index)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HealingCase.fromMap(doc.data(), doc.id)).toList());
  }

  // جلب جميع الحالات (للمدير العام)
  Stream<List<HealingCase>> getAllCases() {
    return _db.collection('cases').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => HealingCase.fromMap(doc.data(), doc.id)).toList());
  }

  // حذف مستخدم من قاعدة البيانات
  Future<void> deleteUser(String uid) async {
    // ملاحظة: الحذف النهائي من Auth يتطلب Cloud Functions، هنا نحذفه من Firestore
    await _db.collection('users').doc(uid).delete();
  }

  // تحديث رتبة المستخدم (ترقية معالج إلى مشرف، إلخ)
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    await _db.collection('users').doc(uid).update({
      'role': newRole.index,
    });
  }

  // ترقية مستوى الطالب في المدرسة
  Future<void> updateStudentLevel(String uid, int newLevel) async {
    await _db.collection('users').doc(uid).update({
      'studentLevel': newLevel,
    });
  }

  // نقل حالة من معالج لآخر (تستخدم في لوحة تحكم المشرف)
  Future<void> assignOrTransferCase(String caseId, String newTherapistId, String newSupervisorId) async {
    await _db.collection('cases').doc(caseId).update({
      'assignedHealerId': newTherapistId,
      'supervisorId': newSupervisorId, // قد يتغير المشرف إذا كان المعالج الجديد تحت إشراف مشرف آخر
      'status': CaseStatus.assigned.index, // إعادة تعيين الحالة كـ "مسندة"
    });
    // تحديث قائمة المرضى لدى المعالج القديم والجديد (اختياري، يمكن أن يتم عبر Cloud Functions)
    // await _db.collection('users').doc(oldTherapistId).update({'myPatients': FieldValue.arrayRemove([caseId])});
    // await _db.collection('users').doc(newTherapistId).update({'myPatients': FieldValue.arrayUnion([caseId])});
  }

  // إرسال مادة من المكتبة إلى دردشة (فردية أو مجموعة) مع إشارة
  Future<void> sendLibraryContentToChat({
    required String chatId,
    required String content,
    required String senderId,
    String? mentionUserId,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': content,
      'mentionUid': mentionUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'isLibraryItem': true,
    });
  }

  // جلب بيانات المرضى المسندين لمعالج معين
  Stream<List<AppUser>> getPatientsForTherapist(String therapistId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.patient.index)
        .where('supervisorId', isEqualTo: therapistId) // في حال كان المعالج هو المشرف المباشر
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }

  // جلب المجموعات العلاجية المسند إليها المعالج
  Stream<List<Map<String, dynamic>>> getTherapistGroups(String therapistId) {
    return _db
        .collection('groups')
        .where('healersIds', arrayContains: therapistId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // إرسال مادة من المكتبة إلى مجموعة علاجية
  Future<void> sendLibraryContentToGroup({
    required String groupId,
    required String content,
    required String senderId,
  }) async {
    await _db.collection('groups').doc(groupId).collection('messages').add({
      'senderId': senderId,
      'text': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isLibraryItem': true,
    });
  }

  // إنشاء مجموعة علاجية جديدة
  Future<void> createTherapyGroup({
    required String name,
    required String supervisorId,
    required String assistantId,
  }) async {
    await _db.collection('groups').add({
      'name': name,
      'supervisorId': supervisorId,
      'assistantId': assistantId,
      'healersIds': [supervisorId, assistantId], // المشرف والمساعد هم معالجون أيضاً في المجموعة
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // إدارة المكالمات الجارية للمراقبة
  Future<void> startLiveCall(String channelId, String title, String hostId, String hostName, {bool isRecording = false}) async {
    await _db.collection('active_calls').doc(channelId).set({
      'channelId': channelId,
      'title': title,
      'hostId': hostId,
      'hostName': hostName,
      'startTime': FieldValue.serverTimestamp(),
      'isRecording': isRecording,
    });
  }

  Future<void> updateRecordingStatus(String channelId, bool isRecording) async {
    await _db.collection('active_calls').doc(channelId).update({
      'isRecording': isRecording,
    });
  }

  Future<void> endLiveCall(String channelId) async {
    await _db.collection('active_calls').doc(channelId).delete();
  }

  Stream<List<Map<String, dynamic>>> getActiveCalls() {
    return _db.collection('active_calls').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  // إرسال دعوة استدعاء لمسؤول آخر للمراقبة المشتركة
  Future<void> sendMonitoringInvitation({
    required String fromName,
    required String toAdminUid,
    required String channelId,
    required String channelTitle,
  }) async {
    await _db.collection('monitoring_invitations').add({
      'fromName': fromName,
      'toAdminUid': toAdminUid,
      'channelId': channelId,
      'channelTitle': channelTitle,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // الاستماع لدعوات الاستدعاء الواردة للمسؤول الحالي
  Stream<List<Map<String, dynamic>>> getMonitoringInvitations(String adminUid) {
    return _db
        .collection('monitoring_invitations')
        .where('toAdminUid', isEqualTo: adminUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // جلب سجل المكالمات المسجلة سابقاً
  Stream<List<Map<String, dynamic>>> getRecordedCalls() {
    return _db.collection('recorded_calls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data()
        }).toList());
  }

  // جلب كافة المحادثات (الفردية والجماعية) للمراقبة الإدارية
  Stream<List<Map<String, dynamic>>> getAllActiveChats() {
    // نفترض وجود مجموعة chats تحتوي على المحادثات
    return _db.collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data()
        }).toList());
  }

  // جلب قصص الشفاء المعتمدة للنشر العام
  Stream<List<HealingCase>> getApprovedStories() {
    return _db
        .collection('cases')
        .where('status', isEqualTo: CaseStatus.completed.index)
        .where('isApprovedForPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HealingCase.fromMap(doc.data(), doc.id)).toList());
  }

  // جلب كافة الحالات المكتملة لمراجعتها من قبل المدير
  Stream<List<HealingCase>> getCompletedCases() {
    return _db
        .collection('cases')
        .where('status', isEqualTo: CaseStatus.completed.index)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HealingCase.fromMap(doc.data(), doc.id)).toList());
  }

  // الموافقة أو إلغاء الموافقة على نشر القصة
  Future<void> toggleStoryApproval(String caseId, bool isApproved) async {
    await _db.collection('cases').doc(caseId).update({
      'isApprovedForPublic': isApproved,
    });
  }
}