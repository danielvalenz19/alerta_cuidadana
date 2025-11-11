// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// import 'package:alerta_ciudadana/main.dart';
import 'package:alerta_ciudadana/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  testWidgets('Login screen renders inputs', (WidgetTester tester) async {
  await dotenv.load(fileName: '.env');
    await tester.pumpWidget(const ProviderScope(child: App(initialRoute: '/')));
    expect(find.text('Alerta Ciudadana'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
