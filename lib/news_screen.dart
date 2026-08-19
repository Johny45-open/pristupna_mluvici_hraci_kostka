import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'speech_service.dart';
import 'update_checker.dart';

/// Shows the history of published releases, newest first.
class NewsScreen extends StatefulWidget {
  const NewsScreen({
    super.key,
    required this.service,
    this.speech,
    this.explicitSpeech = false,
    this.semanticsAnnounce = true,
  });

  final UpdateService service;
  final SpeechService? speech;
  final bool explicitSpeech;
  final bool semanticsAnnounce;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<UpdateInfo>> _future;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchHistory();
    _announceOnLoad();
  }

  @override
  void dispose() {
    if (_isSpeaking) {
      widget.speech?.stop();
    }
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = widget.service.fetchHistory();
    });
  }

  Future<void> _announceOnLoad() async {
    final releases = await _future.then<List<UpdateInfo>?>(
      (list) => list,
      onError: (Object _) => null,
    );
    if (!mounted || releases == null || releases.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message =
          '${l10n.newsTitle}. ${l10n.updateVersionLabel(releases.first.version)}.';
      widget.speech?.announceText(
        context,
        message,
        explicitSpeech: widget.explicitSpeech,
        semanticsAnnounce: widget.semanticsAnnounce,
      );
    });
  }

  Future<void> _readRelease(UpdateInfo release) async {
    final l10n = AppLocalizations.of(context);
    final text = release.plainTextBody;
    final speechText = text.isEmpty
        ? '${l10n.updateVersionLabel(release.version)}. ${l10n.noReleaseNotesLabel}'
        : '${l10n.updateVersionLabel(release.version)}. $text';

    setState(() {
      _isSpeaking = true;
    });

    await widget.speech?.announceText(
      context,
      speechText,
      explicitSpeech: widget.explicitSpeech,
      semanticsAnnounce: widget.semanticsAnnounce,
      force: true,
    );
  }

  Future<void> _readAll(List<UpdateInfo> releases) async {
    final l10n = AppLocalizations.of(context);
    if (releases.isEmpty) {
      await widget.speech?.announceText(
        context,
        l10n.noNewsToRead,
        explicitSpeech: widget.explicitSpeech,
        semanticsAnnounce: widget.semanticsAnnounce,
        force: true,
      );
      return;
    }

    final buffer = StringBuffer();
    for (final release in releases) {
      buffer.write('${l10n.updateVersionLabel(release.version)}. ');
      final text = release.plainTextBody;
      if (text.isEmpty) {
        buffer.write('${l10n.noReleaseNotesLabel} ');
      } else {
        buffer.write('$text. ');
      }
    }

    setState(() {
      _isSpeaking = true;
    });

    await widget.speech?.announceText(
      context,
      buffer.toString(),
      explicitSpeech: widget.explicitSpeech,
      semanticsAnnounce: widget.semanticsAnnounce,
      force: true,
    );
  }

  Future<void> _stopSpeech() async {
    await widget.speech?.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newsTitle),
        actions: [
          FutureBuilder<List<UpdateInfo>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: _isSpeaking
                    ? l10n.stopReadingTooltip
                    : l10n.readAllNewsTooltip,
                icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                onPressed: _isSpeaking
                    ? _stopSpeech
                    : () => _readAll(snapshot.data!),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<UpdateInfo>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: Semantics(
                  label: l10n.newsLoading,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return _ErrorView(l10n: l10n, onRetry: _retry);
            }
            final releases = snapshot.data ?? const [];
            if (releases.isEmpty) {
              return Center(child: Text(l10n.newsEmpty));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: releases.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) => _ReleaseTile(
                release: releases[index],
                onRead: () => _readRelease(releases[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.newsFailed, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(l10n.newsRetryButton),
          ),
        ],
      ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({
    required this.release,
    this.onRead,
  });

  final UpdateInfo release;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = release.publishedAt == null
        ? null
        : DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(release.publishedAt!);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.updateVersionLabel(release.version),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                date,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            release.notes.isEmpty ? l10n.noReleaseNotesLabel : release.notes,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              label: l10n.readNewsSemantics(release.version),
              child: ElevatedButton.icon(
                onPressed: onRead,
                icon: const Icon(Icons.volume_up),
                label: Text(l10n.readNewsButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}