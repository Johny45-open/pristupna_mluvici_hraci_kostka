import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';

import 'fakes.dart';

Future<FakeSpeechService> pumpScreen(
  WidgetTester tester, {
  DiceController? controller,
  Settings settings = const Settings(),
}) async {
  final speech = FakeSpeechService();
  await tester.pumpWidget(
    MaterialApp(
      home: DiceScreen(
        controller: controller ?? DiceController(random: Random(1), sides: 6),
        settings: settings,
        speech: speech,
      ),
    ),
  );
  return speech;
}

String readDisplay(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('diceValue')));
  return text.data ?? '';
}

void main() {
  testWidgets('renders the initial state', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Hodit kostkou'), findsOneWidget);
    expect(readDisplay(tester), '—');
  });

  testWidgets('holding keeps numbers changing, release settles and announces',
      (tester) async {
    final speech = await pumpScreen(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(find.text('Zastavit hod'), findsOneWidget);

    final seen = <String>{readDisplay(tester)};
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen.add(readDisplay(tester));
    }
    expect(seen.length, greaterThan(1),
        reason: 'numbers must keep changing while the button is held');
    expect(find.text('Zastavit hod'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(seconds: 5));

    expect(controllerStateIsDone(tester), isTrue);
    expect(
      speech.announced.where((m) => m.startsWith('Padlo číslo ')),
      isNotEmpty,
    );
    expect(find.text('Hodit kostkou'), findsOneWidget);
    expect(readDisplay(tester), isNot('—'));
  });

  testWidgets('activation (keyboard/screen reader) toggles roll and stop',
      (tester) async {
    final speech = await pumpScreen(tester);

    void activate() {
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
    }

    activate();
    await tester.pump();
    expect(find.text('Zastavit hod'), findsOneWidget);
    expect(speech.announced, contains('Házím kostkou.'));

    activate();
    await tester.pump(const Duration(seconds: 5));

    expect(controllerStateIsDone(tester), isTrue);
    expect(
      speech.announced.where((m) => m.startsWith('Padlo číslo ')),
      isNotEmpty,
    );
    expect(find.text('Hodit kostkou'), findsOneWidget);
  });

  testWidgets('presets and stepper update the number of sides', (tester) async {
    final controller = DiceController(random: Random(1), sides: 6);
    await pumpScreen(tester, controller: controller);

    await tester.ensureVisible(find.text('d8'));
    await tester.pump();
    await tester.tap(find.text('d8'));
    await tester.pump();
    expect(controller.sides, 8);

    await tester.tap(find.byTooltip('Zvýšit počet stran'));
    await tester.pump();
    expect(controller.sides, 9);

    await tester.tap(find.byTooltip('Snížit počet stran'));
    await tester.pump();
    expect(controller.sides, 8);
  });

  testWidgets('dice respects a custom limit while rolling', (tester) async {
    final controller = DiceController(random: Random(2), sides: 20);
    await pumpScreen(tester, controller: controller);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final value = int.parse(readDisplay(tester));
      expect(value, inInclusiveRange(1, 20));
    }

    await gesture.up();
    await tester.pump(const Duration(seconds: 5));
    expect(controllerStateIsDone(tester), isTrue);
  });
}

bool controllerStateIsDone(WidgetTester tester) {
  final widget = tester.widget<DiceScreen>(find.byType(DiceScreen));
  return widget.controller.state == RollState.done;
}