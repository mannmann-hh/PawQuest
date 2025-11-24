import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'step_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ---------------- LOGIN ----------------
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Login successful: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Login failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unknown login error: $e');
      rethrow;
    }
  }

  /// ---------------- REGISTER ----------------
  Future<User?> registerWithEmail(String email, String password) async {
  try {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    print('✅ Auth account created: ${user.uid}');

    // 等待登录状态同步
    await Future.delayed(const Duration(seconds: 1));
    await _auth.currentUser?.reload();
    print('✅ Auth state reloaded');

    // 尝试写入 Firestore（带错误捕获）
    await _createUserDoc(user);
    print('✅ Firestore user doc created');

    return user;
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    rethrow;
  } catch (e) {
    print('❌ Unknown registration error: $e');
    rethrow;
  }
}


  /// ---------------- CREATE USER DOCUMENT ----------------
  Future<void> _createUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      print('ℹ️ User document already exists, skipping.');
      return;
    }

    try {
      await docRef.set({
        'email': user.email ?? '',
        'nickname': 'New User',
        'currentStep': 0,
        'cat': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore document successfully created.');
    } catch (e) {
      print('❌ Firestore write failed: $e');

      // Firestore 写入失败 → 删除刚创建的 Auth 用户，避免数据不一致
      try {
        await user.delete();
        print('🧹 Auth user deleted due to Firestore failure.');
      } catch (delError) {
        print('⚠️ Failed to delete user after Firestore error: $delError');
      }

      rethrow;
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout(StepService stepService) async {
    try {
      // Reset steps
      stepService.resetSteps();
      stepService.dispose(); // Stop step monitoring

      // Logout Firebase
      await _auth.signOut();
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout failed: $e');
      rethrow;
    }
  }
}
