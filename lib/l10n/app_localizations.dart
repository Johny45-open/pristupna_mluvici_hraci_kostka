import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In cs, this message translates to:
  /// **'Mluvící hrací kostka'**
  String get appTitle;

  /// No description provided for @instructions.
  ///
  /// In cs, this message translates to:
  /// **'Podržte tlačítko a kostka se bude točit. Po uvolnění se zpomalí a zastaví na výsledném čísle. Stiskem klávesy nebo aktivací kostku roztočíte a druhým stiskem zastavíte.'**
  String get instructions;

  /// No description provided for @rollingLabel.
  ///
  /// In cs, this message translates to:
  /// **'Házím kostkou.'**
  String get rollingLabel;

  /// No description provided for @resultLabel.
  ///
  /// In cs, this message translates to:
  /// **'Padlo číslo {value}.'**
  String resultLabel(int value);

  /// No description provided for @lastRollLabel.
  ///
  /// In cs, this message translates to:
  /// **'Poslední hod: {value}.'**
  String lastRollLabel(int value);

  /// No description provided for @readyLabel.
  ///
  /// In cs, this message translates to:
  /// **'Kostka je připravená. Hodit kostkou.'**
  String get readyLabel;

  /// No description provided for @rollButton.
  ///
  /// In cs, this message translates to:
  /// **'Hodit kostkou'**
  String get rollButton;

  /// No description provided for @stopButton.
  ///
  /// In cs, this message translates to:
  /// **'Zastavit hod'**
  String get stopButton;

  /// No description provided for @sidesSectionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Počet stran'**
  String get sidesSectionTitle;

  /// No description provided for @diceDescription.
  ///
  /// In cs, this message translates to:
  /// **'Kostka s {sides} stranami'**
  String diceDescription(int sides);

  /// No description provided for @decreaseSidesTooltip.
  ///
  /// In cs, this message translates to:
  /// **'Snížit počet stran'**
  String get decreaseSidesTooltip;

  /// No description provided for @increaseSidesTooltip.
  ///
  /// In cs, this message translates to:
  /// **'Zvýšit počet stran'**
  String get increaseSidesTooltip;

  /// No description provided for @sideCountLabel.
  ///
  /// In cs, this message translates to:
  /// **'Počet stran: {sides}'**
  String sideCountLabel(int sides);

  /// No description provided for @rollSpeedSectionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Rychlost hodu'**
  String get rollSpeedSectionTitle;

  /// No description provided for @speedSlow.
  ///
  /// In cs, this message translates to:
  /// **'Pomalá'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In cs, this message translates to:
  /// **'Normální'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In cs, this message translates to:
  /// **'Rychlá'**
  String get speedFast;

  /// No description provided for @speedLabel.
  ///
  /// In cs, this message translates to:
  /// **'Rychlost hodu: {speed}'**
  String speedLabel(String speed);

  /// No description provided for @decelerationSectionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Zpomalení hodu'**
  String get decelerationSectionTitle;

  /// No description provided for @decelerationFast.
  ///
  /// In cs, this message translates to:
  /// **'Rychlé'**
  String get decelerationFast;

  /// No description provided for @decelerationNormal.
  ///
  /// In cs, this message translates to:
  /// **'Normální'**
  String get decelerationNormal;

  /// No description provided for @decelerationSlow.
  ///
  /// In cs, this message translates to:
  /// **'Pozvolné'**
  String get decelerationSlow;

  /// No description provided for @decelerationLabel.
  ///
  /// In cs, this message translates to:
  /// **'Zpomalení hodu: {speed}'**
  String decelerationLabel(String speed);

  /// No description provided for @appearanceTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vzhled'**
  String get appearanceTitle;

  /// No description provided for @themeLight.
  ///
  /// In cs, this message translates to:
  /// **'Světlý'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In cs, this message translates to:
  /// **'Tmavý'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In cs, this message translates to:
  /// **'Systémový'**
  String get themeSystem;

  /// No description provided for @speechTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vlastní hlas (TTS)'**
  String get speechTitle;

  /// No description provided for @speechSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Kostka mluví i bez aktivní čtečky obrazovky.'**
  String get speechSubtitle;

  /// No description provided for @announceTitle.
  ///
  /// In cs, this message translates to:
  /// **'Oznámení pro čtečku obrazovky'**
  String get announceTitle;

  /// No description provided for @announceSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Výsledky oznamuje aktivní čtečka.'**
  String get announceSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
