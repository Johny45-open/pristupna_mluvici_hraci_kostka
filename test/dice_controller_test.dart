import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristupna_mluvici_hraci_kostka/dice_controller.dart';

void main() {
  test('start rolls while held and stop settles on a value', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(1), sides: 6);
      int? result;
      var starts = 0;
      controller.onResult = (value) => result = value;
      controller.onRollStart = () => starts++;

      controller.start();
      expect(controller.state, RollState.rolling);
      expect(starts, 1);
      expect(controller.currentValue, isNotNull);

      final seen = <int>{controller.currentValue!};
      for (var i = 0; i < 30; i++) {
        async.elapse(const Duration(milliseconds: 100));
        expect(controller.state, RollState.rolling,
            reason: 'numbers must keep changing while held');
        expect(controller.currentValue!, inInclusiveRange(1, 6));
        seen.add(controller.currentValue!);
      }
      expect(seen.length, greaterThan(1),
          reason: 'the displayed value should vary while rolling');

      controller.stop();
      expect(controller.state, RollState.decelerating);
      async.elapse(const Duration(seconds: 5));

      expect(controller.state, RollState.done);
      expect(controller.currentValue, isNotNull);
      expect(controller.lastResult, controller.currentValue);
      expect(result, controller.currentValue);
      expect(result!, inInclusiveRange(1, 6));
      expect(starts, 1, reason: 'no extra roll start during deceleration');

      controller.dispose();
    });
  });

  test('toggle starts from idle/done and stops from rolling', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(2), sides: 8);

      controller.toggle();
      expect(controller.state, RollState.rolling);

      controller.toggle();
      expect(controller.state, RollState.decelerating);
      async.elapse(const Duration(seconds: 5));
      expect(controller.state, RollState.done);

      controller.toggle();
      expect(controller.state, RollState.rolling);

      controller.toggle();
      controller.toggle();
      expect(controller.state, RollState.decelerating,
          reason: 'toggle while decelerating is ignored');
      async.elapse(const Duration(seconds: 5));
      expect(controller.state, RollState.done);

      controller.dispose();
    });
  });

  test('start during deceleration restarts rolling', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(3), sides: 6);

      controller.start();
      async.elapse(const Duration(milliseconds: 300));
      controller.stop();
      expect(controller.state, RollState.decelerating);

      controller.start();
      expect(controller.state, RollState.rolling);
      async.elapse(const Duration(seconds: 5));
      expect(controller.state, RollState.rolling,
          reason: 'decay was cancelled, still held');

      controller.stop();
      async.elapse(const Duration(seconds: 5));
      expect(controller.state, RollState.done);

      controller.dispose();
    });
  });

  test('sides are clamped to the supported range', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(4), sides: 6);

      controller.setSides(200);
      expect(controller.sides, DiceController.maxSides);

      controller.setSides(1);
      expect(controller.sides, DiceController.minSides);

      controller.setSides(12);
      expect(controller.sides, 12);
      expect(controller.currentValue, isNull);

      controller.start();
      controller.setSides(6);
      expect(controller.currentValue!, lessThanOrEqualTo(6));

      controller.dispose();
    });
  });

  test('sides respect the custom limit when rolling', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(5), sides: 20);
      controller.start();
      for (var i = 0; i < 50; i++) {
        async.elapse(const Duration(milliseconds: 100));
        expect(controller.currentValue!, inInclusiveRange(1, 20));
      }
      controller.dispose();
    });
  });
}