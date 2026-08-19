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

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchHistory();
    _announceOnLoad();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newsTitle)),
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
              itemBuilder: (context, index) =>
                  _ReleaseTile(release: releases[index]),
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
  const _ReleaseTile({required this.release});

  final UpdateInfo release;

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
          Text(
            l10n.updateVersionLabel(release.version),
            style: Theme.of(context).textTheme.titleMedium,
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
        ],
      ),
    );
  }
}