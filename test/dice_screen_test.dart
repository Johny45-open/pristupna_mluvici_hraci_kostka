import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_preset.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/l10n/app_localizations.dart';
import 'package:pristupna_mluvici_hraci_kostka/presets.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<FakeSpeechService> pumpScreen(
  WidgetTester tester, {
  DiceController? controller,
  SettingsController? settings,
  PresetsController? presets,
}) async {
  final speech = FakeSpeechService();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('cs'),
      home: DiceScreen(
        controller: controller ?? DiceController(random: Random(1), sides: 6),
        settings: settings ?? SettingsController(const Settings()),
        presets: presets ?? PresetsController(),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the initial state', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Hodit kostkou'), findsOneWidget);
    expect(readDisplay(tester), '—');
  });

  testWidgets('holding keeps numbers changing, release settles and announces',
      (tester) async {
    final speech = await pumpScreen(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('rollButton'))),
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
      tester
          .widget<FilledButton>(find.byKey(const Key('rollButton')))
          .onPressed!();
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

  testWidgets('preset chips announce the new side count', (tester) async {
    final speech = await pumpScreen(tester);

    await tester.ensureVisible(find.text('d8'));
    await tester.pump();
    await tester.tap(find.text('d8'));
    await tester.pump();

    expect(speech.announced, contains('Počet stran: 8.'));
  });

  testWidgets('stepper announces the new side count', (tester) async {
    final speech = await pumpScreen(tester);

    await tester.ensureVisible(find.byTooltip('Zvýšit počet stran'));
    await tester.tap(find.byTooltip('Zvýšit počet stran'));
    await tester.pump();

    expect(speech.announced, contains('Počet stran: 7.'));
  });

  testWidgets('stepper at the limit does not announce', (tester) async {
    final controller = DiceController(random: Random(1), sides: 100);
    final speech = await pumpScreen(tester, controller: controller);

    await tester.ensureVisible(find.byTooltip('Zvýšit počet stran'));
    await tester.tap(find.byTooltip('Zvýšit počet stran'));
    await tester.pump();

    expect(
      speech.announced.where((m) => m.startsWith('Počet stran: ')),
      isEmpty,
    );
  });

  testWidgets('preset chips expose a readable semantics label', (tester) async {
    await pumpScreen(tester);
    final handle = tester.ensureSemantics();

    await tester.ensureVisible(find.text('d20'));
    await tester.pump();

    expect(
      find.bySemanticsLabel(RegExp('Kostka s 20 stranami')),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('dice respects a custom limit while rolling', (tester) async {
    final controller = DiceController(random: Random(2), sides: 20);
    await pumpScreen(tester, controller: controller);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('rollButton'))),
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

  testWidgets('theme chips update the theme mode', (tester) async {
    final settings = SettingsController(const Settings());
    await pumpScreen(tester, settings: settings);

    await tester.ensureVisible(find.text('Tmavý'));
    await tester.pump();
    await tester.tap(find.text('Tmavý'));
    await tester.pump();
    expect(settings.value.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Světlý'));
    await tester.pump();
    expect(settings.value.themeMode, ThemeMode.light);

    await tester.tap(find.text('Systémový'));
    await tester.pump();
    expect(settings.value.themeMode, ThemeMode.system);
  });

  testWidgets('speed chips update the roll speed', (tester) async {
    final controller = DiceController(random: Random(1), sides: 6);
    final settings = SettingsController(const Settings());
    await pumpScreen(tester, controller: controller, settings: settings);

    await tester.ensureVisible(find.text('Pomalá'));
    await tester.pump();
    await tester.tap(find.text('Pomalá'));
    await tester.pump();
    expect(settings.value.rollSpeed, RollSpeed.slow);
    expect(controller.rollSpeed, RollSpeed.slow);
    expect(controller.rollInterval, const Duration(milliseconds: 180));

    await tester.tap(find.text('Rychlá'));
    await tester.pump();
    expect(settings.value.rollSpeed, RollSpeed.fast);
    expect(controller.rollSpeed, RollSpeed.fast);
  });

  testWidgets('speed chips announce the new speed', (tester) async {
    final speech = await pumpScreen(tester);

    await tester.ensureVisible(find.text('Rychlá'));
    await tester.pump();
    await tester.tap(find.text('Rychlá'));
    await tester.pump();

    expect(speech.announced, contains('Rychlost hodu: Rychlá.'));
  });

  testWidgets('deceleration chips update the deceleration', (tester) async {
    final controller = DiceController(random: Random(1), sides: 6);
    final settings = SettingsController(const Settings());
    await pumpScreen(tester, controller: controller, settings: settings);

    await tester.ensureVisible(find.text('Rychlé'));
    await tester.pump();
    await tester.tap(find.text('Rychlé'));
    await tester.pump();
    expect(settings.value.deceleration, DecelerationSpeed.fast);
    expect(controller.deceleration, DecelerationSpeed.fast);
    expect(controller.decelerationGrowth, 1.6);

    await tester.tap(find.text('Pozvolné'));
    await tester.pump();
    expect(settings.value.deceleration, DecelerationSpeed.slow);
    expect(controller.deceleration, DecelerationSpeed.slow);
  });

  testWidgets('deceleration chips announce the new speed', (tester) async {
    final speech = await pumpScreen(tester);

    await tester.ensureVisible(find.text('Pozvolné'));
    await tester.pump();
    await tester.tap(find.text('Pozvolné'));
    await tester.pump();

    expect(speech.announced, contains('Zpomalení hodu: Pozvolné.'));
  });

  test('roll speed is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(const Settings());
    await settings.setRollSpeed(RollSpeed.fast);
    final reloaded = await SettingsController.load();
    expect(reloaded.value.rollSpeed, RollSpeed.fast);

    SharedPreferences.setMockInitialValues({});
    final defaults = await SettingsController.load();
    expect(defaults.value.rollSpeed, RollSpeed.normal);
  });

  test('deceleration is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(const Settings());
    await settings.setDeceleration(DecelerationSpeed.slow);
    final reloaded = await SettingsController.load();
    expect(reloaded.value.deceleration, DecelerationSpeed.slow);

    SharedPreferences.setMockInitialValues({});
    final defaults = await SettingsController.load();
    expect(defaults.value.deceleration, DecelerationSpeed.normal);
  });

  testWidgets('shows a hint when there are no presets', (tester) async {
    await pumpScreen(tester);
    await tester.ensureVisible(find.text('Uložit aktuální nastavení'));
    expect(find.textContaining('Zatím žádné předvolby'), findsOneWidget);
  });

  testWidgets('saving current settings creates a preset', (tester) async {
    final presets = PresetsController();
    await pumpScreen(tester, presets: presets);

    await tester.ensureVisible(find.text('Uložit aktuální nastavení'));
    await tester.tap(find.text('Uložit aktuální nastavení'));
    await tester.pumpAndSettle();

    expect(find.text('Uložit předvolbu'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'd6'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Má kostka');
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();

    expect(find.text('Má kostka'), findsOneWidget);
    expect(presets.presets.single.name, 'Má kostka');
    expect(presets.presets.single.sides, 6);
  });

  testWidgets('saving a preset announces the saved name', (tester) async {
    final speech = await pumpScreen(tester);

    await tester.ensureVisible(find.text('Uložit aktuální nastavení'));
    await tester.tap(find.text('Uložit aktuální nastavení'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Moje d6');
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();

    expect(speech.announced, contains('Předvolba Moje d6 uložena.'));
  });

  testWidgets('loading a preset applies its settings and announces',
      (tester) async {
    final controller = DiceController(random: Random(1), sides: 6);
    final settings = SettingsController(const Settings());
    final presets = PresetsController([
      const DicePreset(
        name: 'd8 svižná',
        sides: 8,
        rollSpeed: RollSpeed.fast,
        deceleration: DecelerationSpeed.fast,
      ),
    ]);
    final speech = await pumpScreen(
      tester,
      controller: controller,
      settings: settings,
      presets: presets,
    );

    await tester.ensureVisible(find.byTooltip('Načíst předvolbu'));
    await tester.tap(find.byTooltip('Načíst předvolbu'));
    await tester.pumpAndSettle();

    expect(controller.sides, 8);
    expect(controller.rollSpeed, RollSpeed.fast);
    expect(controller.deceleration, DecelerationSpeed.fast);
    expect(settings.value.sides, 8);
    expect(settings.value.rollSpeed, RollSpeed.fast);
    expect(settings.value.deceleration, DecelerationSpeed.fast);
    expect(speech.announced, contains('Předvolba d8 svižná načtena.'));
  });

  testWidgets('deleting a preset asks for confirmation', (tester) async {
    final presets = PresetsController([
      const DicePreset(
        name: 'Záloha',
        sides: 20,
        rollSpeed: RollSpeed.normal,
        deceleration: DecelerationSpeed.normal,
      ),
    ]);
    final speech = await pumpScreen(tester, presets: presets);

    await tester.ensureVisible(find.byTooltip('Smazat předvolbu'));
    await tester.tap(find.byTooltip('Smazat předvolbu'));
    await tester.pumpAndSettle();

    expect(find.text('Smazat předvolbu?'), findsOneWidget);
    expect(find.textContaining('trvale smazána'), findsOneWidget);

    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    expect(presets.presets, hasLength(1));

    await tester.tap(find.byTooltip('Smazat předvolbu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat'));
    await tester.pumpAndSettle();

    expect(presets.presets, isEmpty);
    expect(find.text('Záloha'), findsNothing);
    expect(speech.announced, contains('Předvolba Záloha smazána.'));
  });

  testWidgets('preset rows expose a readable semantics label', (tester) async {
    final presets = PresetsController([
      const DicePreset(
        name: 'd12',
        sides: 12,
        rollSpeed: RollSpeed.slow,
        deceleration: DecelerationSpeed.slow,
      ),
    ]);
    await pumpScreen(tester, presets: presets);
    final handle = tester.ensureSemantics();

    await tester.ensureVisible(find.byTooltip('Načíst předvolbu'));
    await tester.pump();

    expect(
      find.bySemanticsLabel(RegExp(
        'Předvolba d12\\. 12 stran, rychlost Pomalá, zpomalení Pozvolné',
      )),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('presets are restored from storage', (tester) async {
    final presets = PresetsController([
      const DicePreset(
        name: 'Šestka',
        sides: 6,
        rollSpeed: RollSpeed.normal,
        deceleration: DecelerationSpeed.normal,
      ),
    ]);
    await presets.savePreset(presets.presets.single);

    await pumpScreen(tester, presets: presets);
    await tester.ensureVisible(find.text('Šestka'));
    expect(find.text('Šestka'), findsOneWidget);
  });
}

bool controllerStateIsDone(WidgetTester tester) {
  final widget = tester.widget<DiceScreen>(find.byType(DiceScreen));
  return widget.controller.state == RollState.done;
}