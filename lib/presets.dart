import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dice_preset.dart';

/// Persisted, named dice presets that can be saved and recalled.
class PresetsController extends ChangeNotifier {
  PresetsController([List<DicePreset>? initial])
      : _presets = List.of(initial ?? const []);

  static const String _presetsKey = 'dice_presets';

  List<DicePreset> _presets;

  List<DicePreset> get presets => List.unmodifiable(_presets);

  bool contains(String name) => _presets.any((p) => p.name == name);

  /// Saves a preset. A preset with the same name is overwritten.
  Future<void> savePreset(DicePreset preset) async {
    final index = _presets.indexWhere((p) => p.name == preset.name);
    if (index == -1) {
      _presets = [..._presets, preset];
    } else {
      _presets = [..._presets]..[index] = preset;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deletePreset(String name) async {
    if (!contains(name)) return;
    _presets = _presets.where((p) => p.name != name).toList();
    notifyListeners();
    await _persist();
  }

  /// Replaces the preset currently stored under [currentName] with [updated].
  /// Also covers renames: after this call the preset is keyed by
  /// [updated.name]. A no-op when [currentName] is unknown.
  Future<void> updatePreset(String currentName, DicePreset updated) async {
    final index = _presets.indexWhere((p) => p.name == currentName);
    if (index == -1) return;
    _presets = [..._presets]..[index] = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _presetsKey,
      jsonEncode(_presets.map((p) => p.toJson()).toList()),
    );
  }

  static Future<PresetsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetsKey);
    if (raw == null) return PresetsController();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return PresetsController();
      final presets = decoded
          .map(DicePreset.fromJson)
          .whereType<DicePreset>()
          .toList();
      return PresetsController(presets);
    } catch (_) {
      return PresetsController();
    }
  }
}