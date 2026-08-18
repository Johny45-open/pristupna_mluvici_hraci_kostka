import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings.
class Settings {
  const Settings({
    this.sides = 6,
    this.explicitSpeech = true,
    this.semanticsAnnounce = true,
    this.themeMode = ThemeMode.system,
  });

  final int sides;
  final bool explicitSpeech;
  final bool semanticsAnnounce;
  final ThemeMode themeMode;

  Settings copyWith({
    int? sides,
    bool? explicitSpeech,
    bool? semanticsAnnounce,
    ThemeMode? themeMode,
  }) {
    return Settings(
      sides: sides ?? this.sides,
      explicitSpeech: explicitSpeech ?? this.explicitSpeech,
      semanticsAnnounce: semanticsAnnounce ?? this.semanticsAnnounce,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  static const String _sidesKey = 'dice_sides';
  static const String _speechKey = 'explicit_speech';
  static const String _semanticsKey = 'semantics_announce';
  static const String _themeKey = 'theme_mode';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sidesKey, sides);
    await prefs.setBool(_speechKey, explicitSpeech);
    await prefs.setBool(_semanticsKey, semanticsAnnounce);
    await prefs.setInt(_themeKey, themeMode.index);
  }

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    return Settings(
      sides: prefs.getInt(_sidesKey) ?? 6,
      explicitSpeech: prefs.getBool(_speechKey) ?? true,
      semanticsAnnounce: prefs.getBool(_semanticsKey) ?? true,
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
    );
  }
}

/// Mutable settings state shared between the app shell and the screen.
/// Every change is persisted and announced to listeners.
class SettingsController extends ChangeNotifier {
  SettingsController(this._settings);

  Settings _settings;

  Settings get value => _settings;

  Future<void> setSides(int value) async {
    _settings = _settings.copyWith(sides: value);
    notifyListeners();
    await _settings.save();
  }

  Future<void> setExplicitSpeech(bool value) async {
    _settings = _settings.copyWith(explicitSpeech: value);
    notifyListeners();
    await _settings.save();
  }

  Future<void> setSemanticsAnnounce(bool value) async {
    _settings = _settings.copyWith(semanticsAnnounce: value);
    notifyListeners();
    await _settings.save();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (value == _settings.themeMode) return;
    _settings = _settings.copyWith(themeMode: value);
    notifyListeners();
    await _settings.save();
  }

  static Future<SettingsController> load() async {
    return SettingsController(await Settings.load());
  }
}
