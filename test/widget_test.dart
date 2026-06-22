import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('SHOW ME THE BIBLE'),
        ),
      ),
    );

    expect(find.text('SHOW ME THE BIBLE'), findsOneWidget);
  });
}
