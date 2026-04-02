import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // تسجيل الدخول
  Future<UserCredential?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // التحقق من هيدر التطبيق (Super Admin) وتحديث بياناته الأساسية
      if (email == "abdalmonem20m@gmail.com" && password == "abd123123") {
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': 'المدير العام',
          'role': UserRole.superAdmin.index,
          'email': email,
          'isApproved': true,
          'status': 'online',
        }, SetOptions(merge: true));
      } else {
        // تحديث حالة الاتصال للمستخدمين العاديين
        updatePresence(userCredential.user!.uid, true);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code}");
      rethrow; // لإتاحة الفرصة لواجهة المستخدم لعرض رسالة خطأ مناسبة
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // إنشاء حساب جديد
  Future<UserCredential?> register(String email, String password, String name, UserRole role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // إنشاء وثيقة المستخدم في Firestore
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': role.index,
        'isApproved': role == UserRole.patient || role == UserRole.student ? true : false,
        'status': 'offline',
      });
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // جلب بيانات المستخدم كاملة من Firestore
  Future<AppUser?> getUserData(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  // تسجيل الدخول عبر جوجل
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // التحقق من وجود بيانات المستخدم في Firestore
      DocumentSnapshot doc = await _db.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        // إنشاء حساب افتراضي للمستخدمين الجدد عبر جوجل (رتبة مريض)
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'مستخدم جوجل',
          'email': userCredential.user!.email,
          'role': UserRole.patient.index,
          'isApproved': true,
          'status': 'online',
        });
      } else {
        updatePresence(userCredential.user!.uid, true);
      }
      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // تحديث الحضور
  void updatePresence(String uid, bool isOnline) {
    _db.collection('users').doc(uid).update({
      'status': isOnline ? 'online' : 'offline',
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // إنشاء حساب مسؤول (بواسطة المدير العام)
  Future<void> createAdminAccount(String email, String password, Map<String, bool> permissions) async {
    try {
      // ملاحظة: لإنشاء مستخدم دون تسجيل الخروج، يفضل استخدام Cloud Functions
      // هنا نقوم بإنشاء سجل في Firestore ليقوم الأدمن بإكمال التسجيل أو تفعيل الحساب
      await _db.collection('admin_invitations').add({
        'email': email,
        'password': password, // يجب تشفيره في بيئة الإنتاج
        'permissions': permissions,
        'role': UserRole.adminStaff.index,
        'createdBy': _auth.currentUser!.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating admin invitation: $e");
      rethrow;
    }
  }
}