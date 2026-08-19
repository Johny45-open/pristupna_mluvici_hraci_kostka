import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/l10n/app_localizations.dart';
import 'package:pristupna_mluvici_hraci_kostka/news_screen.dart';
import 'package:pristupna_mluvici_hraci_kostka/presets.dart';
import 'package:pristupna_mluvici_hraci_kostka/settings.dart';
import 'package:pristupna_mluvici_hraci_kostka/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

final _latest = UpdateInfo(
  version: '2.0.0',
  title: 'v2.0.0',
  notes: 'Nové funkce a opravy.',
  url: 'https://example.com/releases/v2.0.0',
  publishedAt: DateTime.utc(2024, 5, 1),
);

final _previous = UpdateInfo(
  version: '1.7.0',
  title: 'v1.7.0',
  notes: 'Oprava hlášení výsledků.',
  url: 'https://example.com/releases/v1.7.0',
  publishedAt: DateTime.utc(2024, 2, 10),
);

Future<void> pumpNews(
  WidgetTester tester, {
  required FakeUpdateService service,
  FakeSpeechService? speech,
}) async {
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
      home: NewsScreen(
        service: service,
        speech: speech ?? FakeSpeechService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpDice(
  WidgetTester tester, {
  required FakeUpdateService service,
  required FakeSpeechService speech,
}) async {
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
        speech: speech,
        updateController: makeUpdateController(service: service),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the releases newest first with date and notes',
      (tester) async {
    await pumpNews(
      tester,
      service: FakeUpdateService(history: [_latest, _previous]),
    );

    expect(find.text('Novinky'), findsOneWidget);
    expect(find.text('Verze 2.0.0'), findsOneWidget);
    expect(find.text('Nové funkce a opravy.'), findsOneWidget);
    expect(find.textContaining('2024'), findsWidgets);
    expect(find.text('Verze 1.7.0'), findsOneWidget);
    expect(find.text('Oprava hlášení výsledků.'), findsOneWidget);
  });

  testWidgets('shows a placeholder for releases without notes', (tester) async {
    await pumpNews(
      tester,
      service: FakeUpdateService(
        history: [
          UpdateInfo(
            version: '1.6.0',
            title: 'v1.6.0',
            notes: '',
            url: 'https://example.com/releases/v1.6.0',
          ),
        ],
      ),
    );

    expect(find.text('Autor vydání nepřidal žádné poznámky.'), findsOneWidget);
  });

  testWidgets('shows the empty message when there are no releases',
      (tester) async {
    await pumpNews(tester, service: FakeUpdateService());

    expect(find.text('Žádné novinky nejsou k dispozici.'), findsOneWidget);
  });

  testWidgets('shows an error view with a working retry button', (tester) async {
    final service = FakeUpdateService(
      history: [_latest],
      error: StateError('boom'),
    );
    await pumpNews(tester, service: service);

    expect(find.text('Novinky se nepodařilo načíst.'), findsOneWidget);
    expect(find.text('Zkusit znovu'), findsOneWidget);

    service.error = null;
    await tester.tap(find.text('Zkusit znovu'));
    await tester.pumpAndSettle();

    expect(find.text('Verze 2.0.0'), findsOneWidget);
    expect(service.historyCalls, greaterThan(1));
  });

  testWidgets('announces the newest release on open', (tester) async {
    final speech = FakeSpeechService();
    await pumpNews(
      tester,
      service: FakeUpdateService(history: [_latest, _previous]),
      speech: speech,
    );

    expect(speech.announced, contains('Novinky. Verze 2.0.0.'));
  });

  testWidgets('opens from the news button on the dice screen', (tester) async {
    final speech = FakeSpeechService();
    await pumpDice(
      tester,
      service: FakeUpdateService(history: [_latest]),
      speech: speech,
    );

    await tester.tap(find.byTooltip('Novinky'));
    await tester.pumpAndSettle();

    expect(find.text('Nové funkce a opravy.'), findsOneWidget);
    expect(speech.announced, contains('Novinky. Verze 2.0.0.'));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Hodit kostkou'), findsOneWidget);
  });
}