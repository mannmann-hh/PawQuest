import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/services/auth_service.dart';

void main() {
  test('logout stops steps, resets state, then signs out', () async {
    final events = <String>[];
    final auth = _FakeAuthService(() => events.add('signOut'));

    await LogoutCoordinator(auth).logout(
      stopStepListener: () => events.add('stop'),
      resetSteps: () => events.add('reset'),
    );

    expect(events, ['stop', 'reset', 'signOut']);
    expect(auth.didSignOut, isTrue);
  });
}

class _FakeAuthService implements AuthService {
  final void Function() onSignOut;
  bool didSignOut = false;

  _FakeAuthService(this.onSignOut);

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    didSignOut = true;
    onSignOut();
  }
}
