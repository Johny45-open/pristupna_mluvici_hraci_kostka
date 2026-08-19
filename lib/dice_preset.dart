import 'dice_controller.dart';

/// A user-defined, named dice configuration that can be saved and recalled.
class DicePreset {
  const DicePreset({
    required this.name,
    required this.sides,
    required this.rollSpeed,
    required this.deceleration,
  });

  final String name;
  final int sides;
  final RollSpeed rollSpeed;
  final DecelerationSpeed deceleration;

  bool sameSettings(DicePreset other) =>
      sides == other.sides &&
      rollSpeed == other.rollSpeed &&
      deceleration == other.deceleration;

  Map<String, Object> toJson() => {
        'name': name,
        'sides': sides,
        'rollSpeed': rollSpeed.index,
        'deceleration': deceleration.index,
      };

  static DicePreset? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final sides = json['sides'];
    if (name is! String || name.isEmpty || sides is! int) return null;
    return DicePreset(
      name: name,
      sides: sides.clamp(
        DiceController.minSides,
        DiceController.maxSides,
      ),
      rollSpeed: _enumFromIndex(
        RollSpeed.values,
        json['rollSpeed'],
        RollSpeed.normal,
      ),
      deceleration: _enumFromIndex(
        DecelerationSpeed.values,
        json['deceleration'],
        DecelerationSpeed.normal,
      ),
    );
  }

  static T _enumFromIndex<T>(List<T> values, Object? index, T fallback) {
    if (index is! int) return fallback;
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }
}