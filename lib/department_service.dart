import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  final String id;
  final String name;
  final List<String> assignedAdminIds;

  Department({required this.id, required this.name, required this.assignedAdminIds});

  factory Department.fromMap(Map<String, dynamic> map, String id) {
    return Department(
      id: id,
      name: map['name'] ?? '',
      assignedAdminIds: List<String>.from(map['assignedAdminIds'] ?? []),
    );
  }
}

class DepartmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إنشاء قسم جديد
  Future<void> createDepartment(String name) async {
    await _db.collection('departments').add({
      'name': name,
      'assignedAdminIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // جلب كافة الأقسام
  Stream<List<Department>> getDepartments() {
    return _db.collection('departments').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Department.fromMap(doc.data(), doc.id)).toList());
  }

  // إضافة إداري لقسم معين
  Future<void> assignAdminToDepartment(String departmentId, String adminUid) async {
    await _db.collection('departments').doc(departmentId).update({
      'assignedAdminIds': FieldValue.arrayUnion([adminUid]),
    });
    await _db.collection('users').doc(adminUid).update({'departmentId': departmentId});
  }
}