enum UserRole {
  superAdmin,
  adminStaff,
  supervisor,
  assistantSupervisor,
  therapist,
  student,
  patient
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? supervisorId;      // للمشرف أو المعالج
  final String? assistantSupId;    // النائب
  final String? groupId;           // المجموعة العلاجية
  final bool isApproved;      // للموافقة على المعالجين والطلاب
  final Map<String, bool> permissions; // صلاحيات أقسام الإدارة
  final String status;        // (online/offline)
  final int studentLevel;     // لمراحل الدراسة
  final DateTime? levelStartedAt; // متى بدأ المستوى الحالي
  final bool waitingForTest;      // هل ينتظر الاختبار؟
  final String? currentTestGroupId; // معرف مجموعة الاختبار الحالية
  final List<String>? myPatients;  // للمُعالجين: قائمة الحالات المسندة

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.supervisorId,
    this.assistantSupId,
    this.groupId,
    this.isApproved = false,
    this.permissions = const {},
    this.status = 'offline',
    this.studentLevel = 0,
    this.levelStartedAt,
    this.waitingForTest = false,
    this.currentTestGroupId,
    this.myPatients,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.index,
      'supervisorId': supervisorId,
      'assistantSupId': assistantSupId,
      'groupId': groupId,
      'isApproved': isApproved,
      'permissions': permissions,
      'status': status,
      'studentLevel': studentLevel,
      'levelStartedAt': levelStartedAt?.toIso8601String(),
      'waitingForTest': waitingForTest,
      'currentTestGroupId': currentTestGroupId,
      'myPatients': myPatients,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values[map['role']],
      supervisorId: map['supervisorId'],
      assistantSupId: map['assistantSupId'],
      groupId: map['groupId'],
      isApproved: map['isApproved'] ?? false,
      permissions: Map<String, bool>.from(map['permissions'] ?? {}),
      status: map['status'] ?? 'offline',
      studentLevel: map['studentLevel'] ?? 0,
      levelStartedAt: map['levelStartedAt'] != null ? DateTime.parse(map['levelStartedAt']) : null,
      waitingForTest: map['waitingForTest'] ?? false,
      currentTestGroupId: map['currentTestGroupId'],
      myPatients: map['myPatients'] != null ? List<String>.from(map['myPatients']) : null,
    );
  }
}