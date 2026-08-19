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
    this.publishedAt,
  });

  /// Version without a leading 'v' (e.g. "1.7.0").
  final String version;
  final String title;
  final String notes;
  final String url;

  /// When the release was published, when the source provides it.
  final DateTime? publishedAt;

  /// Cleaned text without Markdown markup suitable for TTS playback.
  String get plainTextBody {
    if (notes.trim().isEmpty) return '';
    return notes
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*', multiLine: true), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*', multiLine: true), r'$1')
        .replaceAll('`', '')
        .replaceAll('_', '')
        .replaceAll('\r\n', '\n')
        .trim();
  }

  Map<String, Object?> toJson() => {
        'version': version,
        'title': title,
        'notes': notes,
        'url': url,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      };

  static UpdateInfo? fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final title = json['title'];
    final notes = json['notes'];
    final url = json['url'];
    if (version is! String ||
        title is! String ||
        notes is! String ||
        url is! String) {
      return null;
    }
    final publishedAt = json['publishedAt'];
    return UpdateInfo(
      version: version,
      title: title,
      notes: notes,
      url: url,
      publishedAt:
          publishedAt is String ? DateTime.tryParse(publishedAt) : null,
    );
  }
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

  /// Fetches the published releases, newest first.
  Future<List<UpdateInfo>> fetchHistory({int perPage = 50});
}

/// Fetches the latest release from the public GitHub API.
class GitHubUpdateService implements UpdateService {
  GitHubUpdateService({
    http.Client? client,
    String? repo,
    Future<SharedPreferences> Function()? prefs,
  }) : this._(client ?? http.Client(), repo ?? defaultRepo, prefs);

  GitHubUpdateService._(this._client, this._repo, this._prefs);

  static const String defaultRepo =
      'Johny45-open/pristupna_mluvici_hraci_kostka';

  static const String historyCacheKey = 'news_history_cache';
  static const int maxCachedEntries = 50;

  final http.Client _client;
  final String _repo;
  final Future<SharedPreferences> Function()? _prefs;

  List<UpdateInfo>? _memoryCache;
  bool _cacheLoaded = false;

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
    return _releaseFromJson(json);
  }

  @override
  Future<List<UpdateInfo>> fetchHistory({int perPage = 50}) async {
    final uri = Uri.parse(
        'https://api.github.com/repos/$_repo/releases?per_page=$perPage');
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) return const [];
      if (response.statusCode != 200) {
        throw UpdateCheckException('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const UpdateCheckException('Unexpected response shape');
      }
      final releases = <UpdateInfo>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final info = _releaseFromJson(Map<String, dynamic>.from(item));
        if (info != null) releases.add(info);
      }
      await _writeCache(releases);
      return releases;
    } catch (_) {
      final cached = await _readCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  UpdateInfo? _releaseFromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'];
    if (tag is! String) return null;
    final published = json['published_at'];
    return UpdateInfo(
      version: _stripV(tag),
      title: json['name'] as String? ?? '',
      notes: json['body'] as String? ?? '',
      url: json['html_url'] as String? ?? '',
      publishedAt: published is String ? DateTime.tryParse(published) : null,
    );
  }

  Future<List<UpdateInfo>?> _readCache() async {
    if (!_cacheLoaded) {
      _memoryCache = null;
      final prefs = _prefs != null ? await _prefs() : null;
      if (prefs != null) {
        final raw = prefs.getString(historyCacheKey);
        if (raw != null) _memoryCache = _decodeCache(raw);
      }
      _cacheLoaded = true;
    }
    return _memoryCache;
  }

  Future<void> _writeCache(List<UpdateInfo> releases) async {
    final stored = releases.take(maxCachedEntries).toList();
    _memoryCache = stored;
    _cacheLoaded = true;
    final prefs = _prefs != null ? await _prefs() : null;
    if (prefs != null) {
      await prefs.setString(
        historyCacheKey,
        jsonEncode([for (final release in stored) release.toJson()]),
      );
    }
  }

  List<UpdateInfo>? _decodeCache(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final result = <UpdateInfo>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final info = UpdateInfo.fromJson(
          item.map((key, value) => MapEntry('$key', value)),
        );
        if (info != null) result.add(info);
      }
      return result;
    } catch (_) {
      return null;
    }
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

  /// The service used to check for updates and read the news history.
  UpdateService get service => _service;

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