// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Mluvící hrací kostka';

  @override
  String get instructions =>
      'Podržte tlačítko a kostka se bude točit. Po uvolnění se zpomalí a zastaví na výsledném čísle. Stiskem klávesy nebo aktivací kostku roztočíte a druhým stiskem zastavíte.';

  @override
  String get rollingLabel => 'Házím kostkou.';

  @override
  String resultLabel(int value) {
    return 'Padlo číslo $value.';
  }

  @override
  String lastRollLabel(int value) {
    return 'Poslední hod: $value.';
  }

  @override
  String get readyLabel => 'Kostka je připravená. Hodit kostkou.';

  @override
  String get rollButton => 'Hodit kostkou';

  @override
  String get stopButton => 'Zastavit hod';

  @override
  String get sidesSectionTitle => 'Počet stran';

  @override
  String diceDescription(int sides) {
    return 'Kostka s $sides stranami';
  }

  @override
  String get decreaseSidesTooltip => 'Snížit počet stran';

  @override
  String get increaseSidesTooltip => 'Zvýšit počet stran';

  @override
  String sideCountLabel(int sides) {
    return 'Počet stran: $sides';
  }

  @override
  String get rollSpeedSectionTitle => 'Rychlost hodu';

  @override
  String get speedSlow => 'Pomalá';

  @override
  String get speedNormal => 'Normální';

  @override
  String get speedFast => 'Rychlá';

  @override
  String speedLabel(String speed) {
    return 'Rychlost hodu: $speed';
  }

  @override
  String get decelerationSectionTitle => 'Zpomalení hodu';

  @override
  String get decelerationFast => 'Rychlé';

  @override
  String get decelerationNormal => 'Normální';

  @override
  String get decelerationSlow => 'Pozvolné';

  @override
  String decelerationLabel(String speed) {
    return 'Zpomalení hodu: $speed';
  }

  @override
  String get appearanceTitle => 'Vzhled';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get themeSystem => 'Systémový';

  @override
  String get speechTitle => 'Vlastní hlas (TTS)';

  @override
  String get speechSubtitle => 'Kostka mluví i bez aktivní čtečky obrazovky.';

  @override
  String get announceTitle => 'Oznámení pro čtečku obrazovky';

  @override
  String get announceSubtitle => 'Výsledky oznamuje aktivní čtečka.';

  @override
  String get presetsSectionTitle => 'Předvolby';

  @override
  String get presetsEmptyHint =>
      'Zatím žádné předvolby. Uložte aktuální nastavení a později je vyvolejte.';

  @override
  String get savePresetButton => 'Uložit aktuální nastavení';

  @override
  String get savePresetDialogTitle => 'Uložit předvolbu';

  @override
  String get presetNameLabel => 'Název předvolby';

  @override
  String get presetNameHint => 'např. d6';

  @override
  String presetDefaultName(int sides) {
    return 'd$sides';
  }

  @override
  String get savePresetConfirm => 'Uložit';

  @override
  String get cancelButton => 'Zrušit';

  @override
  String get loadPresetTooltip => 'Načíst předvolbu';

  @override
  String get deletePresetTooltip => 'Smazat předvolbu';

  @override
  String presetSavedLabel(String name) {
    return 'Předvolba $name uložena.';
  }

  @override
  String presetLoadedLabel(String name) {
    return 'Předvolba $name načtena.';
  }

  @override
  String presetDeletedLabel(String name) {
    return 'Předvolba $name smazána.';
  }

  @override
  String presetSummary(int sides, String speed, String deceleration) {
    return '$sides stran, rychlost $speed, zpomalení $deceleration';
  }

  @override
  String presetEntryLabel(String name, String summary) {
    return 'Předvolba $name. $summary';
  }

  @override
  String get deletePresetDialogTitle => 'Smazat předvolbu?';

  @override
  String deletePresetDialogContent(String name) {
    return 'Předvolba $name bude trvale smazána.';
  }

  @override
  String get deleteConfirm => 'Smazat';

  @override
  String get renamePresetTooltip => 'Přejmenovat';

  @override
  String get renamePresetDialogTitle => 'Upravit předvolbu';

  @override
  String get spokenNameLabel => 'Mluvený název';

  @override
  String get spokenNameHint =>
      'Pro TTS a čtečku obrazovky místo názvu. Prázdné = použije se název.';

  @override
  String presetRenamedLabel(String name) {
    return 'Předvolba $name upravena.';
  }
}
