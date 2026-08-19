import 'package:flutter/material.dart';
import 'package:pristupna_mluvici_hraci_kostka/speech_service.dart';
import 'package:pristupna_mluvici_hraci_kostka/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Future<void> announceSides(
    BuildContext context,
    int sides, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add('Počet stran: $sides.');
  }

  @override
  Future<void> announceSpeed(
    BuildContext context,
    String speed, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add('Rychlost hodu: $speed.');
  }

  @override
  Future<void> announceDeceleration(
    BuildContext context,
    String speed, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add('Zpomalení hodu: $speed.');
  }

  @override
  Future<void> announceText(
    BuildContext context,
    String text, {
    required bool explicitSpeech,
    required bool semanticsAnnounce,
  }) async {
    announced.add(text);
  }
}

class FakeUpdateService implements UpdateService {
  FakeUpdateService({this.latest, this.error});

  final UpdateInfo? latest;
  final Object? error;
  int calls = 0;

  @override
  Future<UpdateInfo?> fetchLatest() async {
    calls++;
    if (error != null) throw error!;
    return latest;
  }
}

UpdateController makeUpdateController({
  UpdateService? service,
  String currentVersion = '1.7.0',
}) {
  return UpdateController(
    service: service ?? FakeUpdateService(),
    currentVersion: () async => currentVersion,
    prefs: SharedPreferences.getInstance,
  );
}