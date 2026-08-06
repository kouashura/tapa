// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapa_budget/main.dart' as app;

void main() {
  testWidgets('TAPA Budget app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const app.TapaBudgetApp());

    // Vérifier que l'app s'affiche
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}