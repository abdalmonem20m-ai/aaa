enum CaseStatus {
  newCase,      // حالة جديدة لم تُسند بعد
  assigned,     // أُسندت لمجموعة
  inProgress,   // جاري المعالجة
  completed     // تم الشفاء
}

class HealingCase {
  final String id;
  final String patientId;
  final String? assignedGroupId;
  final String? assignedHealerId;
  final String? supervisorId;
  final CaseStatus status;
  final String report;
  final DateTime createdAt;
  final List<String> evidenceUrls; // صور المحادثات أو فيديوهات الإثبات
  final bool isApprovedForPublic; // هل وافق المدير على نشرها كقصة شفاء؟

  HealingCase({
    required this.id,
    required this.patientId,
    this.assignedGroupId,
    this.assignedHealerId,
    this.supervisorId,
    required this.status,
    this.report = '',
    required this.createdAt,
    this.evidenceUrls = const [],
    this.isApprovedForPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'assignedGroupId': assignedGroupId,
      'assignedHealerId': assignedHealerId,
      'supervisorId': supervisorId,
      'status': status.index,
      'report': report,
      'createdAt': createdAt.toIso8601String(),
      'evidenceUrls': evidenceUrls,
      'isApprovedForPublic': isApprovedForPublic,
    };
  }

  factory HealingCase.fromMap(Map<String, dynamic> map, String documentId) {
    return HealingCase(
      id: documentId,
      patientId: map['patientId'] ?? '',
      assignedGroupId: map['assignedGroupId'],
      assignedHealerId: map['assignedHealerId'],
      supervisorId: map['supervisorId'],
      status: CaseStatus.values[map['status'] ?? 0],
      report: map['report'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? []),
      isApprovedForPublic: map['isApprovedForPublic'] ?? false,
    );
  }
}