import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_preset.dart';
import 'package:pristupna_mluvici_hraci_kostka/presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const preset = DicePreset(
    name: 'd20 pomalé',
    sides: 20,
    rollSpeed: RollSpeed.slow,
    deceleration: DecelerationSpeed.slow,
  );

  test('DicePreset toJson/fromJson round-trips', () {
    final decoded = DicePreset.fromJson(preset.toJson());
    expect(decoded, isNotNull);
    expect(decoded!.name, 'd20 pomalé');
    expect(decoded.sides, 20);
    expect(decoded.rollSpeed, RollSpeed.slow);
    expect(decoded.deceleration, DecelerationSpeed.slow);
  });

  test('DicePreset.fromJson clamps sides and falls back on bad enums', () {
    final decoded = DicePreset.fromJson(const {
      'name': 'x',
      'sides': 500,
      'rollSpeed': 99,
      'deceleration': 'nope',
    });
    expect(decoded, isNotNull);
    expect(decoded!.sides, DiceController.maxSides);
    expect(decoded.rollSpeed, RollSpeed.normal);
    expect(decoded.deceleration, DecelerationSpeed.normal);
  });

  test('DicePreset.fromJson rejects invalid maps', () {
    expect(DicePreset.fromJson(null), isNull);
    expect(DicePreset.fromJson('text'), isNull);
    expect(DicePreset.fromJson(const {'name': '', 'sides': 6}), isNull);
    expect(DicePreset.fromJson(const {'name': 'x', 'sides': 'six'}), isNull);
  });

  test('PresetsController persists and restores presets', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = PresetsController();
    await controller.savePreset(preset);
    expect(controller.presets, hasLength(1));

    final reloaded = await PresetsController.load();
    expect(reloaded.presets, hasLength(1));
    expect(reloaded.presets.first.name, 'd20 pomalé');
    expect(reloaded.presets.first.sides, 20);
    expect(reloaded.presets.first.rollSpeed, RollSpeed.slow);
    expect(reloaded.presets.first.deceleration, DecelerationSpeed.slow);
  });

  test('saving the same name overwrites instead of duplicating', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = PresetsController();
    await controller.savePreset(preset);
    await controller.savePreset(const DicePreset(
      name: 'd20 pomalé',
      sides: 12,
      rollSpeed: RollSpeed.fast,
      deceleration: DecelerationSpeed.fast,
    ));
    expect(controller.presets, hasLength(1));
    expect(controller.presets.first.sides, 12);
    expect(controller.presets.first.rollSpeed, RollSpeed.fast);
  });

  test('deletePreset removes only the matching preset', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = PresetsController([
      preset,
      const DicePreset(
        name: 'd6',
        sides: 6,
        rollSpeed: RollSpeed.normal,
        deceleration: DecelerationSpeed.normal,
      ),
    ]);
    await controller.deletePreset('d20 pomalé');
    expect(controller.presets, hasLength(1));
    expect(controller.presets.single.name, 'd6');

    final reloaded = await PresetsController.load();
    expect(reloaded.presets, hasLength(1));
    expect(reloaded.presets.single.name, 'd6');
  });

  test('deletePreset on an unknown name is a no-op', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = PresetsController([preset]);
    await controller.deletePreset('nope');
    expect(controller.presets, hasLength(1));
  });

  test('load tolerates missing and corrupt storage', () async {
    SharedPreferences.setMockInitialValues({});
    final empty = await PresetsController.load();
    expect(empty.presets, isEmpty);

    SharedPreferences.setMockInitialValues({'dice_presets': 'not json'});
    final corrupt = await PresetsController.load();
    expect(corrupt.presets, isEmpty);

    SharedPreferences.setMockInitialValues({'dice_presets': '42'});
    final notList = await PresetsController.load();
    expect(notList.presets, isEmpty);
  });
}