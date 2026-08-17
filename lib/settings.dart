import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings.
class Settings {
  const Settings({
    this.sides = 6,
    this.explicitSpeech = true,
    this.semanticsAnnounce = true,
  });

  final int sides;
  final bool explicitSpeech;
  final bool semanticsAnnounce;

  Settings copyWith({int? sides, bool? explicitSpeech, bool? semanticsAnnounce}) {
    return Settings(
      sides: sides ?? this.sides,
      explicitSpeech: explicitSpeech ?? this.explicitSpeech,
      semanticsAnnounce: semanticsAnnounce ?? this.semanticsAnnounce,
    );
  }

  static const String _sidesKey = 'dice_sides';
  static const String _speechKey = 'explicit_speech';
  static const String _semanticsKey = 'semantics_announce';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sidesKey, sides);
    await prefs.setBool(_speechKey, explicitSpeech);
    await prefs.setBool(_semanticsKey, semanticsAnnounce);
  }

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      sides: prefs.getInt(_sidesKey) ?? 6,
      explicitSpeech: prefs.getBool(_speechKey) ?? true,
      semanticsAnnounce: prefs.getBool(_semanticsKey) ?? true,
    );
  }
}
