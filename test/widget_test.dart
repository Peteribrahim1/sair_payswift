// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sair/main.dart';

void main() {
  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PaySwiftApp());

    // Verify that our first screen is shown.
    expect(find.text('Page 4.5'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);

    // Tap the 'Go to Next Page' button and trigger a frame.
    await tester.tap(find.text('Go to Next Page'));
    await tester.pumpAndSettle();

    // Verify that our second screen is shown.
    expect(find.text('Page 4.5'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);

    // Tap the 'Go Back' button and trigger a frame.
    await tester.tap(find.text('Go Back'));
    await tester.pumpAndSettle();

    // Verify that our first screen is shown again.
    expect(find.text('Page 1.9883'), findsOneWidget);
  });
}
