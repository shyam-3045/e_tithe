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
}
