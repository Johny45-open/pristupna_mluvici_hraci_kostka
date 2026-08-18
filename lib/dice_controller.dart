import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum RollState { idle, rolling, decelerating, done }

/// Presets controlling how fast the numbers cycle while held and how quickly
/// the dice settles once released.
enum RollSpeed {
  slow(
    rollInterval: Duration(milliseconds: 180),
    decelerationStart: Duration(milliseconds: 240),
  ),
  normal(
    rollInterval: Duration(milliseconds: 90),
    decelerationStart: Duration(milliseconds: 120),
  ),
  fast(
    rollInterval: Duration(milliseconds: 45),
    decelerationStart: Duration(milliseconds: 60),
  );

  const RollSpeed({
    required this.rollInterval,
    required this.decelerationStart,
  });

  final Duration rollInterval;
  final Duration decelerationStart;
}

/// Presets controlling how gradually the dice slows down after release.
///
/// The growth factor decides how much each deceleration step is delayed.
/// A small growth keeps the dice visibly changing for longer; a large growth
/// settles it almost immediately.
enum DecelerationSpeed {
  fast(growth: 1.6),
  normal(growth: 1.25),
  slow(growth: 1.12);

  const DecelerationSpeed({required this.growth});

  final double growth;
}

/// State machine driving the dice.
///
/// * Pointer press  -> [start] (numbers keep changing while held).
/// * Pointer release -> [stop] (numbers slow down until they settle).
/// * Discrete activation (keyboard / screen reader) -> [toggle].
class DiceController extends ChangeNotifier {
  DiceController({
    Random? random,
    this.sides = 6,
    RollSpeed rollSpeed = RollSpeed.normal,
    DecelerationSpeed deceleration = DecelerationSpeed.normal,
    this.maxDecelerationInterval = const Duration(milliseconds: 700),
    this.onRollStart,
    this.onResult,
  })  : _random = random ?? Random(),
        _rollSpeed = rollSpeed,
        _deceleration = deceleration,
        rollInterval = rollSpeed.rollInterval,
        decelerationStart = rollSpeed.decelerationStart,
        decelerationGrowth = deceleration.growth;

  static const int minSides = 2;
  static const int maxSides = 100;

  final Random _random;
  final Duration maxDecelerationInterval;

  RollSpeed _rollSpeed;
  DecelerationSpeed _deceleration;
  Duration rollInterval;
  Duration decelerationStart;
  double decelerationGrowth;

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

  RollSpeed get rollSpeed => _rollSpeed;

  /// Changes how fast the dice rolls. Takes effect from the next roll;
  /// a roll already in progress keeps its current timing.
  void setRollSpeed(RollSpeed value) {
    if (value == _rollSpeed) return;
    _rollSpeed = value;
    rollInterval = value.rollInterval;
    decelerationStart = value.decelerationStart;
    notifyListeners();
  }

  DecelerationSpeed get deceleration => _deceleration;

  /// Changes how gradually the dice settles. Takes effect from the next roll;
  /// a roll already slowing down keeps its current deceleration.
  void setDeceleration(DecelerationSpeed value) {
    if (value == _deceleration) return;
    _deceleration = value;
    decelerationGrowth = value.growth;
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
