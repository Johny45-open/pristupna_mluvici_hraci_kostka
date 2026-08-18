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

  test('setRollSpeed updates the timing parameters', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(6));
      expect(controller.rollSpeed, RollSpeed.normal);
      expect(controller.rollInterval, const Duration(milliseconds: 90));
      expect(controller.decelerationStart, const Duration(milliseconds: 120));

      controller.setRollSpeed(RollSpeed.slow);
      expect(controller.rollSpeed, RollSpeed.slow);
      expect(controller.rollInterval, const Duration(milliseconds: 180));
      expect(controller.decelerationStart, const Duration(milliseconds: 240));

      controller.setRollSpeed(RollSpeed.fast);
      expect(controller.rollSpeed, RollSpeed.fast);
      expect(controller.rollInterval, const Duration(milliseconds: 45));
      expect(controller.decelerationStart, const Duration(milliseconds: 60));

      controller.dispose();
    });
  });

  test('setRollSpeed with the same value does nothing', () {
    fakeAsync((async) {
      final controller = DiceController(random: Random(7));
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setRollSpeed(RollSpeed.normal);
      expect(notifications, 0);

      controller.dispose();
    });
  });

  test('slow roll changes the value less often than a fast one', () {
    fakeAsync((async) {
      final slow = DiceController(random: Random(8), rollSpeed: RollSpeed.slow);
      final fast = DiceController(random: Random(9), rollSpeed: RollSpeed.fast);

      var slowTicks = 0;
      var fastTicks = 0;
      slow.addListener(() => slowTicks++);
      fast.addListener(() => fastTicks++);

      slow.start();
      fast.start();
      async.elapse(const Duration(milliseconds: 360));

      // start() notifies once, then the periodic timer ticks every interval.
      expect(slowTicks, 3, reason: 'slow rolls every 180 ms');
      expect(fastTicks, 9, reason: 'fast rolls every 45 ms');
      expect(slowTicks, lessThan(fastTicks));

      slow.dispose();
      fast.dispose();
    });
  });
}