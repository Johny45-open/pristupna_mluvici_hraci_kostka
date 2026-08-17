import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum RollState { idle, rolling, decelerating, done }

/// State machine driving the dice.
///
/// * Pointer press  -> [start] (numbers keep changing while held).
/// * Pointer release -> [stop] (numbers slow down until they settle).
/// * Discrete activation (keyboard / screen reader) -> [toggle].
class DiceController extends ChangeNotifier {
  DiceController({
    Random? random,
    this.sides = 6,
    this.rollInterval = const Duration(milliseconds: 90),
    this.decelerationStart = const Duration(milliseconds: 120),
    this.decelerationGrowth = 1.25,
    this.maxDecelerationInterval = const Duration(milliseconds: 700),
    this.onRollStart,
    this.onResult,
  }) : _random = random ?? Random();

  static const int minSides = 2;
  static const int maxSides = 100;

  final Random _random;
  final Duration rollInterval;
  final Duration decelerationStart;
  final double decelerationGrowth;
  final Duration maxDecelerationInterval;

  /// Called when a new roll starts.
  VoidCallback? onRollStart;

  /// Called with the final value once the dice has settled.
  ValueChanged<int>? onResult;

  int sides;
  RollState state = RollState.idle;
  int? currentValue;
  int? lastResult;

  Timer? _ticker;
  Duration _nextDelay = Duration.zero;

  bool get isBusy => state == RollState.rolling || state == RollState.decelerating;

  void setSides(int value) {
    final clamped = value.clamp(minSides, maxSides);
    if (clamped == sides) return;
    sides = clamped;
    if (currentValue != null && currentValue! > sides) {
      currentValue = sides;
    }
    notifyListeners();
  }

  int _roll() => _random.nextInt(sides) + 1;

  /// Begins rolling. If the dice is currently slowing down, the
  /// deceleration is cancelled and rolling resumes.
  void start() {
    _ticker?.cancel();
    _nextDelay = Duration.zero;
    state = RollState.rolling;
    currentValue = _roll();
    onRollStart?.call();
    notifyListeners();
    _ticker = Timer.periodic(rollInterval, (_) {
      currentValue = _roll();
      notifyListeners();
    });
  }

  /// Begins slowing down towards a final value.
  void stop() {
    if (state != RollState.rolling) return;
    _ticker?.cancel();
    state = RollState.decelerating;
    _nextDelay = decelerationStart;
    notifyListeners();
    _scheduleDecelerationStep();
  }

  void _scheduleDecelerationStep() {
    _ticker = Timer(_nextDelay, _decelerationStep);
  }

  void _decelerationStep() {
    currentValue = _roll();
    final next = _nextDelay * decelerationGrowth;
    if (next > maxDecelerationInterval) {
      state = RollState.done;
      lastResult = currentValue;
      notifyListeners();
      onResult?.call(currentValue!);
      return;
    }
    _nextDelay = next;
    notifyListeners();
    _scheduleDecelerationStep();
  }

  /// Toggle for discrete activations (button click, Enter, screen reader).
  void toggle() {
    switch (state) {
      case RollState.idle:
      case RollState.done:
        start();
      case RollState.rolling:
        stop();
      case RollState.decelerating:
        break;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
