import 'package:flutter/material.dart';
import 'package:pristupna_mluvici_hraci_kostka/speech_service.dart';

class NoopTts implements TtsAdapter {
  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> speak(String text) async {}
}

class FakeSpeechService extends SpeechService {
  FakeSpeechService() : super(tts: NoopTts());

  final List<String> announced = [];

  @override
  Future<void> announceStart(
    BuildContext context, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add('Házím kostkou.');
  }

  @override
  Future<void> announceResult(
    BuildContext context,
    int value, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add('Padlo číslo $value.');
  }
}