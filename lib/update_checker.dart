import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A published app update as exposed by the GitHub releases API.
@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.url,
  });

  /// Version without a leading 'v' (e.g. "1.7.0").
  final String version;
  final String title;
  final String notes;
  final String url;
}

/// Compares dotted numeric versions ("1.7.0"), tolerating a leading 'v' and
/// per-part suffixes such as "1.8.0-rc.1" or build metadata "1.7.0+2".
int compareVersions(String a, String b) {
  final left = _split(a);
  final right = _split(b);
  final length = math.max(left.length, right.length);
  for (var i = 0; i < length; i++) {
    final aPart = i < left.length ? left[i] : 0;
    final bPart = i < right.length ? right[i] : 0;
    if (aPart != bPart) return aPart.compareTo(bPart);
  }
  return 0;
}

List<int> _split(String version) {
  var cleaned = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
  cleaned = cleaned.split(RegExp(r'[-+]')).first;
  final result = <int>[];
  for (final part in cleaned.split('.')) {
    final match = RegExp(r'^\d+').firstMatch(part);
    result.add(match == null ? 0 : int.parse(match.group(0)!));
  }
  return result;
}

/// The outcome of an update check.
sealed class UpdateResult {
  const UpdateResult();
}

/// A newer version than the installed one was found.
class UpdateAvailable extends UpdateResult {
  const UpdateAvailable(this.info);

  final UpdateInfo info;
}

/// The installed version is the newest available one.
class UpdateUpToDate extends UpdateResult {
  const UpdateUpToDate();
}

/// The check could not be completed.
class UpdateCheckFailed extends UpdateResult {
  const UpdateCheckFailed();
}

/// Thrown by [UpdateService] implementations on unexpected responses.
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => 'UpdateCheckException: $message';
}

/// Minimal surface so tests can substitute a fake.
abstract class UpdateService {
  Future<UpdateInfo?> fetchLatest();
}

/// Fetches the latest release from the public GitHub API.
class GitHubUpdateService implements UpdateService {
  GitHubUpdateService({http.Client? client, String? repo})
      : _client = client ?? http.Client(),
        _repo = repo ?? defaultRepo;

  static const String defaultRepo =
      'Johny45-open/pristupna_mluvici_hraci_kostka';

  final http.Client _client;
  final String _repo;

  @override
  Future<UpdateInfo?> fetchLatest() async {
    final uri =
        Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw UpdateCheckException('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UpdateInfo(
      version: _stripV(json['tag_name'] as String? ?? ''),
      title: json['name'] as String? ?? '',
      notes: json['body'] as String? ?? '',
      url: json['html_url'] as String? ?? '',
    );
  }

  static String _stripV(String tag) => tag.replaceFirst(RegExp(r'^[vV]'), '');
}

/// Possible states of an update check, surfaced to the UI.
enum UpdateStatus { idle, checking, updateAvailable, upToDate, error }

/// Runs update checks and remembers which release was already announced.
class UpdateController extends ChangeNotifier {
  UpdateController({
    required UpdateService service,
    required Future<String> Function() currentVersion,
    required Future<SharedPreferences> Function() prefs,
  }) : this._(service, currentVersion, prefs);

  UpdateController._(
    this._service,
    this._currentVersion,
    this._prefs,
  );

  static const String lastNotifiedKey = 'last_notified_release';

  final UpdateService _service;
  final Future<String> Function() _currentVersion;
  final Future<SharedPreferences> Function() _prefs;

  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _latest;
  String? _error;

  UpdateStatus get status => _status;
  UpdateInfo? get latest => _latest;
  String? get error => _error;

  /// Fetches the latest release and compares it with the installed version.
  Future<UpdateResult> check() async {
    _status = UpdateStatus.checking;
    _error = null;
    _latest = null;
    notifyListeners();
    try {
      final current = await _currentVersion();
      final latest = await _service.fetchLatest();
      if (latest == null) {
        _status = UpdateStatus.upToDate;
        notifyListeners();
        return const UpdateUpToDate();
      }
      if (compareVersions(latest.version, current) <= 0) {
        _status = UpdateStatus.upToDate;
        notifyListeners();
        return const UpdateUpToDate();
      }
      _latest = latest;
      _status = UpdateStatus.updateAvailable;
      notifyListeners();
      return UpdateAvailable(latest);
    } catch (_) {
      _error = 'check_failed';
      _status = UpdateStatus.error;
      notifyListeners();
      return const UpdateCheckFailed();
    }
  }

  /// Remembers that [version] was shown to the user.
  Future<void> markNotified(String version) async {
    final prefs = await _prefs();
    await prefs.setString(lastNotifiedKey, version);
  }

  /// Whether [version] was already announced to the user.
  Future<bool> wasNotified(String version) async {
    final prefs = await _prefs();
    return prefs.getString(lastNotifiedKey) == version;
  }
}