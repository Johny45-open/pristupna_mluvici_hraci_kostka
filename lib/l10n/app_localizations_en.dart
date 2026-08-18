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
}
