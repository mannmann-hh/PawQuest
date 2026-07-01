import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/screens/login_screen.dart';
import 'package:pawquest/services/auth_service.dart';
import 'package:pawquest/theme/app_palette.dart';

void main() {
  testWidgets('login trims credentials and reports success', (tester) async {
    final auth = _FakeAuthService();
    var success = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: auth,
          palette: AppPalette.all.first,
          onLoginSuccess: () => success = true,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), ' user@example.com ');
    await tester.enterText(find.byType(TextField).at(1), ' secret ');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(auth.email, 'user@example.com');
    expect(auth.password, 'secret');
    expect(success, isTrue);
  });

  testWidgets('login displays an authentication failure', (tester) async {
    final auth = _FakeAuthService(error: Exception('Wrong credentials'));
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: auth,
          palette: AppPalette.all.first,
          onLoginSuccess: () {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Wrong credentials'), findsOneWidget);
  });
}

class _FakeAuthService implements AuthService {
  final Object? error;
  String? email;
  String? password;

  _FakeAuthService({this.error});

  @override
  Future<void> signIn({required String email, required String password}) async {
    this.email = email;
    this.password = password;
    if (error != null) throw error!;
  }

  @override
  Future<void> signOut() async {}
}
