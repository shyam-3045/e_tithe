import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_tithe/app/e_tithe_app.dart';
import 'package:e_tithe/common/constants/app_constants.dart';
import 'package:e_tithe/common/services/auth_service.dart';

const String _loginResponse = '''
{
  "token": "test-token",
  "refreshToken": null,
  "expiration": "2026-04-20T08:29:41Z",
  "userId": "3",
  "userGuid": "86dbee57-2e24-4b1e-baa0-173d8f70984e",
  "userName": "Saran",
  "email": "etithe@gmail.com",
  "userTypeId": 1,
  "isActive": true,
  "message": "Authentication successful"
}
''';

void _installMockAuthClient() {
  AuthService.instance = AuthService(
    client: MockClient((request) async {
      if (request.url.path == '/api/Auth/login') {
        return http.Response(_loginResponse, 200);
      }

      if (request.url.path == '/api/Donor') {
        final String? authorization = request.headers['authorization'];
        expect(authorization, isNotNull);
        expect(authorization, 'Bearer test-token');
        if (request.method == 'GET') {
          return http.Response('''[
              {"donorName":"Test Donor","email":"test@gmail.com","mobileNo":"9999999999","city":"TestCity","area":"TestArea","pincode":"123456"}
            ]''', 200);
        }
        return http.Response('{"message":"saved"}', 201);
      }

      return http.Response('Not found', 404);
    }),
  );
}

void main() {
  setUp(_installMockAuthClient);

  Future<void> _signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'etithe@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('Splash opens login page after delay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ETitheApp());

    expect(find.text('SU-INDIA'), findsOneWidget);
    expect(find.text('Email'), findsNothing);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Login opens dashboard page', (WidgetTester tester) async {
    await tester.pumpWidget(const ETitheApp());
    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();

    await _signIn(tester);

    expect(find.text('e-Tithe'), findsOneWidget);
    expect(find.text('Wilson Behera  -  [Field Officer]'), findsOneWidget);
    expect(find.text('New Donor'), findsOneWidget);
    expect(find.text('Donors'), findsOneWidget);
    expect(find.text('Receipts'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('New donor card opens donor form page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ETitheApp());
    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();

    await _signIn(tester);

    await tester.tap(find.text('New Donor'));
    await tester.pumpAndSettle();

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Address Details'), findsOneWidget);
    expect(find.text('Save Donor'), findsOneWidget);
  });
}
