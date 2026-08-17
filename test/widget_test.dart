import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';

import 'fakes.dart';

void main() {
  testWidgets('dice app smoke test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiceScreen(
          controller: DiceController(sides: 6),
          settings: const Settings(),
          speech: FakeSpeechService(),
        ),
      ),
    );

    expect(find.text('Mluvící hrací kostka'), findsOneWidget);
    expect(find.text('Hodit kostkou'), findsOneWidget);
    expect(find.text('Počet stran'), findsOneWidget);
  });
}