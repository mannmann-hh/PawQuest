import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class LogoutCoordinator {
  final AuthService authService;

  const LogoutCoordinator(this.authService);

  Future<void> logout({
    required void Function() stopStepListener,
    required void Function() resetSteps,
  }) async {
    stopStepListener();
    resetSteps();
    await authService.signOut();
  }
}
