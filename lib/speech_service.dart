import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Minimal TTS surface so tests can substitute a fake.
abstract class TtsAdapter {
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> stop();
  Future<void> speak(String text);
}

/// [flutter_tts] backed adapter (Android, iOS, macOS, web, Windows).
class FlutterTtsAdapter implements TtsAdapter {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> setLanguage(String language) => _tts.setLanguage(language);

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setVolume(double volume) => _tts.setVolume(volume);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> speak(String text) => _tts.speak(text);
}

/// Speaks results and routes announcements to screen readers.
///
/// Strategy:
/// * Screen reader active -> rely on the reader. Imperative announcements on
///   platforms that support them (Windows, Linux, iOS, web), live region on
///   Android (handled by the display widget).
/// * No screen reader   -> explicit TTS (flutter_tts; on Linux speech-dispatcher
///   or eSpeak through a small platform channel).
class SpeechService {
  SpeechService({TtsAdapter? tts, MethodChannel? linuxChannel})
      : _tts = tts ?? FlutterTtsAdapter(),
        _linuxChannel = linuxChannel ??
            const MethodChannel('cz.pristupna_mluvici_kostka/speech');

  final TtsAdapter _tts;
  final MethodChannel _linuxChannel;
  bool _initialized = false;

  bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage('cs-CZ');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    try {
      if (_isLinux) {
        await _linuxChannel.invokeMethod<void>('speak', text);
        return;
      }
      await _init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      try {
        await _linuxChannel.invokeMethod<void>('speak', text);
      } catch (_) {
        // No speech output available on this platform.
      }
    }
  }

  Future<void> announceStart(
    BuildContext context, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    final supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
    final accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
    if (semanticsAnnounce && supportsAnnounce) {
      final view = View.of(context);
      final direction = Directionality.of(context);
      try {
        await SemanticsService.sendAnnouncement(view, 'Házím kostkou.', direction);
      } catch (_) {}
    }
    if (explicitSpeech && !accessibleNavigation) {
      await _speak('Házím kostkou.');
    }
  }

  Future<void> announceResult(
    BuildContext context,
    int value, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    final supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
    final accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
    if (semanticsAnnounce && supportsAnnounce) {
      final view = View.of(context);
      final direction = Directionality.of(context);
      try {
        await SemanticsService.sendAnnouncement(
          view,
          'Padlo číslo $value.',
          direction,
        );
      } catch (_) {}
    }
    if (explicitSpeech && !accessibleNavigation) {
      await _speak('Padlo číslo $value.');
    }
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
