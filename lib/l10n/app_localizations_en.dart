// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Talking dice';

  @override
  String get instructions =>
      'Press and hold the button and the die will keep rolling. Release it and it slows down and settles on the result. Pressing a key or activating the die starts the roll; pressing again stops it.';

  @override
  String get rollingLabel => 'Rolling the die.';

  @override
  String resultLabel(int value) {
    return 'It rolled $value.';
  }

  @override
  String lastRollLabel(int value) {
    return 'Last roll: $value.';
  }

  @override
  String get readyLabel => 'The die is ready. Roll the die.';

  @override
  String get rollButton => 'Roll the die';

  @override
  String get stopButton => 'Stop the roll';

  @override
  String get sidesSectionTitle => 'Number of sides';

  @override
  String diceDescription(int sides) {
    return 'Die with $sides sides';
  }

  @override
  String get decreaseSidesTooltip => 'Decrease the number of sides';

  @override
  String get increaseSidesTooltip => 'Increase the number of sides';

  @override
  String sideCountLabel(int sides) {
    return 'Number of sides: $sides';
  }

  @override
  String get rollSpeedSectionTitle => 'Roll speed';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String speedLabel(String speed) {
    return 'Roll speed: $speed';
  }

  @override
  String get decelerationSectionTitle => 'Deceleration';

  @override
  String get decelerationFast => 'Fast';

  @override
  String get decelerationNormal => 'Normal';

  @override
  String get decelerationSlow => 'Gradual';

  @override
  String decelerationLabel(String speed) {
    return 'Deceleration: $speed';
  }

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get speechTitle => 'Built-in voice (TTS)';

  @override
  String get speechSubtitle =>
      'The die speaks even without an active screen reader.';

  @override
  String get announceTitle => 'Screen reader announcements';

  @override
  String get announceSubtitle =>
      'Results are announced by an active screen reader.';

  @override
  String get presetsSectionTitle => 'Presets';

  @override
  String get presetsEmptyHint =>
      'No presets yet. Save the current settings, then recall them later.';

  @override
  String get savePresetButton => 'Save current settings';

  @override
  String get savePresetDialogTitle => 'Save preset';

  @override
  String get presetNameLabel => 'Preset name';

  @override
  String get presetNameHint => 'e.g. d6';

  @override
  String presetDefaultName(int sides) {
    return 'd$sides';
  }

  @override
  String get savePresetConfirm => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get loadPresetTooltip => 'Load preset';

  @override
  String get deletePresetTooltip => 'Delete preset';

  @override
  String presetSavedLabel(String name) {
    return 'Preset $name saved.';
  }

  @override
  String presetLoadedLabel(String name) {
    return 'Preset $name loaded.';
  }

  @override
  String presetDeletedLabel(String name) {
    return 'Preset $name deleted.';
  }

  @override
  String presetSummary(int sides, String speed, String deceleration) {
    return '$sides sides, speed $speed, deceleration $deceleration';
  }

  @override
  String presetEntryLabel(String name, String summary) {
    return 'Preset $name. $summary';
  }

  @override
  String get deletePresetDialogTitle => 'Delete preset?';

  @override
  String deletePresetDialogContent(String name) {
    return 'The preset $name will be permanently deleted.';
  }

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get renamePresetTooltip => 'Rename preset';

  @override
  String get renamePresetDialogTitle => 'Edit preset';

  @override
  String get spokenNameLabel => 'Spoken name';

  @override
  String get spokenNameHint =>
      'Spoken by the voice and screen reader instead of the name. Leave empty to use the name.';

  @override
  String presetRenamedLabel(String name) {
    return 'Preset $name updated.';
  }

  @override
  String get updatesTooltip => 'Check for updates';

  @override
  String get newsTooltip => 'News';

  @override
  String get newsTitle => 'News';

  @override
  String get newsLoading => 'Loading news…';

  @override
  String get newsEmpty => 'No news available.';

  @override
  String get newsFailed => 'Could not load the news.';

  @override
  String get newsRetryButton => 'Try again';

  @override
  String get checkingUpdatesLabel => 'Checking for updates…';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get noReleaseNotesLabel => 'The author did not add any release notes.';

  @override
  String get openInBrowserButton => 'Open in browser';

  @override
  String get upToDateLabel => 'You are up to date.';

  @override
  String get updateCheckFailedLabel =>
      'Could not check for updates. Try again later.';

  @override
  String get updateLinkFailedLabel => 'Could not open the link.';

  @override
  String get readNewsButton => 'Read news';

  @override
  String readNewsSemantics(String version) {
    return 'Read news for version $version';
  }

  @override
  String get readAllNewsTooltip => 'Read all news';

  @override
  String get stopReadingTooltip => 'Stop reading';

  @override
  String get noNewsToRead => 'Nothing to read.';
}
