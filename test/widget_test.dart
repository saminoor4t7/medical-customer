// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mediacl_panda/main.dart';

void main() {
  testWidgets('shows splash and registration screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.text('Medical Panda'), findsOneWidget);
    expect(find.text('Rider & Delivery Partner Edition'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Register as a pharmacy partner'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
