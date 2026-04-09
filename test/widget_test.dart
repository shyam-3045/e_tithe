import 'package:flutter_test/flutter_test.dart';

import 'package:e_tithe/app/e_tithe_app.dart';
import 'package:e_tithe/common/constants/app_constants.dart';

void main() {
  testWidgets('Splash opens login page after delay', (WidgetTester tester) async {
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

    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(AppConstants.loginDuration);
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(AppConstants.loginDuration);
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Donor'));
    await tester.pumpAndSettle();

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Address Details'), findsOneWidget);
    expect(find.text('Save Donor'), findsOneWidget);
  });
}
