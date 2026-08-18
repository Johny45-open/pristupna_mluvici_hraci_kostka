import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/l10n/app_localizations.dart';
import 'package:pristupna_mluvici_hraci_kostka/main.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('dice app smoke test', (tester) async {
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
          controller: DiceController(sides: 6),
          settings: SettingsController(const Settings()),
          speech: FakeSpeechService(),
        ),
      ),
    );

    expect(find.text('Mluvící hrací kostka'), findsOneWidget);
    expect(find.text('Hodit kostkou'), findsOneWidget);
    expect(find.text('Počet stran'), findsOneWidget);
    expect(find.text('Vzhled'), findsOneWidget);
  });

  testWidgets('theme selection switches MaterialApp.themeMode', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('cs')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final settings = await SettingsController.load();
    await tester.pumpWidget(App(settings: settings));

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    await tester.ensureVisible(find.text('Tmavý'));
    await tester.pump();
    await tester.tap(find.text('Tmavý'));
    await tester.pump();
    expect(app().themeMode, ThemeMode.dark);

    await tester.tap(find.text('Světlý'));
    await tester.pump();
    expect(app().themeMode, ThemeMode.light);
  });
}