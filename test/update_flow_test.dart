import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/l10n/app_localizations.dart';
import 'package:pristupna_mluvici_hraci_kostka/presets.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';
import 'package:pristupna_mluvici_hraci_kostka/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const _newerRelease = UpdateInfo(
  version: '2.0.0',
  title: 'v2.0.0',
  notes: 'Nové funkce a opravy.',
  url: 'https://example.com/releases/v2.0.0',
);

Future<void> pumpScreen(
  WidgetTester tester,
  UpdateController updateController,
) async {
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
        controller: DiceController(random: Random(1), sides: 6),
        settings: SettingsController(const Settings()),
        presets: PresetsController(),
        speech: FakeSpeechService(),
        updateController: updateController,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('auto-check at startup announces the dialog for a new version',
      (tester) async {
    final controller = makeUpdateController(
      service: FakeUpdateService(latest: _newerRelease),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('K dispozici je nová verze'), findsOneWidget);
    expect(find.text('Verze 2.0.0'), findsOneWidget);
    expect(find.text('Nové funkce a opravy.'), findsOneWidget);
    expect(find.text('Otevřít v prohlížeči'), findsOneWidget);

    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    expect(await controller.wasNotified('2.0.0'), isTrue);
  });

  testWidgets('auto-check does not re-show an already notified version',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      UpdateController.lastNotifiedKey: '2.0.0',
    });
    final controller = makeUpdateController(
      service: FakeUpdateService(latest: _newerRelease),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('K dispozici je nová verze'), findsNothing);
  });

  testWidgets('auto-check stays quiet when the app is up to date',
      (tester) async {
    final controller = makeUpdateController(
      service: FakeUpdateService(
        latest: const UpdateInfo(
          version: '1.7.0',
          title: 'v1.7.0',
          notes: '',
          url: 'https://example.com/releases/v1.7.0',
        ),
      ),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('K dispozici je nová verze'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('manual check opens the dialog when a new version exists',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      UpdateController.lastNotifiedKey: '2.0.0',
    });
    final controller = makeUpdateController(
      service: FakeUpdateService(latest: _newerRelease),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('K dispozici je nová verze'), findsNothing);

    await tester.tap(find.byTooltip('Zkontrolovat aktualizace'));
    await tester.pumpAndSettle();

    expect(find.text('K dispozici je nová verze'), findsOneWidget);
    expect(find.text('Nové funkce a opravy.'), findsOneWidget);
    expect(await controller.wasNotified('2.0.0'), isTrue);
  });

  testWidgets('manual check announces up to date', (tester) async {
    final controller = makeUpdateController(
      service: FakeUpdateService(
        latest: const UpdateInfo(
          version: '1.7.0',
          title: 'v1.7.0',
          notes: '',
          url: 'https://example.com/releases/v1.7.0',
        ),
      ),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zkontrolovat aktualizace'));
    await tester.pumpAndSettle();

    expect(find.text('Máte nejnovější verzi.'), findsOneWidget);
    final screen = tester.widget<DiceScreen>(find.byType(DiceScreen));
    final announced =
        (screen.speech as FakeSpeechService).announced;
    expect(announced, contains('Máte nejnovější verzi.'));
  });

  testWidgets('manual check announces a failure', (tester) async {
    final controller = makeUpdateController(
      service: FakeUpdateService(error: StateError('boom')),
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zkontrolovat aktualizace'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Aktualizace se nepodařilo zkontrolovat'),
      findsOneWidget,
    );
    final screen = tester.widget<DiceScreen>(find.byType(DiceScreen));
    final announced = (screen.speech as FakeSpeechService).announced;
    expect(
      announced.any((m) => m.contains('nepodařilo zkontrolovat')),
      isTrue,
    );
  });
}