import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dice_controller.dart';
import 'l10n/app_localizations.dart';
import 'settings.dart';
import 'speech_service.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({
    super.key,
    required this.controller,
    required this.settings,
    this.speech,
  });

  final DiceController controller;
  final SettingsController settings;
  final SpeechService? speech;

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  static const List<int> _presets = [4, 6, 8, 10, 12, 20];

  late final DiceController _controller;
  late final SpeechService _speech;

  RollState? _lastState;
  int? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _speech = widget.speech ?? SpeechService();
    _lastState = _controller.state;
    _lastValue = _controller.currentValue;

    _controller.onRollStart = _announceStart;
    _controller.onResult = _announceResult;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final valueChanged = _controller.currentValue != _lastValue;
    if (valueChanged && _controller.isBusy) {
      HapticFeedback.selectionClick();
    }
    if (_controller.state == RollState.done && _lastState != RollState.done) {
      HapticFeedback.mediumImpact();
    }
    _lastState = _controller.state;
    _lastValue = _controller.currentValue;
  }

  Future<void> _announceStart() async {
    if (!mounted) return;
    final settings = widget.settings.value;
    await _speech.announceStart(
      context,
      explicitSpeech: settings.explicitSpeech,
      semanticsAnnounce: settings.semanticsAnnounce,
    );
  }

  Future<void> _announceResult(int value) async {
    if (!mounted) return;
    final settings = widget.settings.value;
    await _speech.announceResult(
      context,
      value,
      explicitSpeech: settings.explicitSpeech,
      semanticsAnnounce: settings.semanticsAnnounce,
    );
  }

  Future<void> _announceSides(int sides) async {
    if (!mounted) return;
    final settings = widget.settings.value;
    await _speech.announceSides(
      context,
      sides,
      explicitSpeech: settings.explicitSpeech,
      semanticsAnnounce: settings.semanticsAnnounce,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, widget.settings]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumberDisplay(context),
                  const SizedBox(height: 32),
                  _buildRollButton(context),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).instructions,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildSidesSection(context),
                  const SizedBox(height: 24),
                  _buildRollSpeedSection(context),
                  const SizedBox(height: 24),
                  _buildThemeSection(context),
                  const SizedBox(height: 16),
                  _buildSpeechSettings(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberDisplay(BuildContext context) {
    final useLiveRegion = !MediaQuery.supportsAnnounceOf(context);
    final l10n = AppLocalizations.of(context);
    final value = _controller.currentValue;
    final label = switch (_controller.state) {
      RollState.rolling || RollState.decelerating => l10n.rollingLabel,
      RollState.done => l10n.resultLabel(value!),
      RollState.idle when value != null => l10n.lastRollLabel(value),
      RollState.idle => l10n.readyLabel,
    };

    return Semantics(
      liveRegion: useLiveRegion,
      label: label,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value?.toString() ?? '—',
            key: const Key('diceValue'),
            style: TextStyle(
              fontSize: 160,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRollButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, onTap) = switch (_controller.state) {
      RollState.rolling ||
      RollState.decelerating => (l10n.stopButton, _controller.toggle),
      RollState.idle || RollState.done => (l10n.rollButton, _controller.toggle),
    };

    return Listener(
      onPointerDown: (event) {
        if (event.buttons & kPrimaryButton != 0) {
          _controller.start();
        }
      },
      onPointerUp: (_) => _controller.stop(),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(320, 160),
          textStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildSidesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sides = _controller.sides;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sidesSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              MergeSemantics(
                child: Semantics(
                  label: l10n.diceDescription(preset),
                  child: ChoiceChip(
                    label: ExcludeSemantics(child: Text('d$preset')),
                    selected: sides == preset,
                    onSelected: (_) => _setSides(preset),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: l10n.decreaseSidesTooltip,
              onPressed: () => _setSides(sides - 1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 24),
            Semantics(
              label: l10n.sideCountLabel(sides),
              liveRegion: !MediaQuery.supportsAnnounceOf(context),
              child: ExcludeSemantics(
                child: Text(
                  '$sides',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton.filledTonal(
              tooltip: l10n.increaseSidesTooltip,
              onPressed: () => _setSides(sides + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  void _setSides(int value) {
    final clamped = value.clamp(2, 100);
    if (clamped == _controller.sides) return;
    widget.settings.setSides(clamped);
    _controller.setSides(clamped);
    _announceSides(clamped);
  }

  String _speedName(BuildContext context, RollSpeed speed) {
    final l10n = AppLocalizations.of(context);
    return switch (speed) {
      RollSpeed.slow => l10n.speedSlow,
      RollSpeed.normal => l10n.speedNormal,
      RollSpeed.fast => l10n.speedFast,
    };
  }

  Future<void> _announceSpeed(RollSpeed speed) async {
    if (!mounted) return;
    final settings = widget.settings.value;
    await _speech.announceSpeed(
      context,
      _speedName(context, speed),
      explicitSpeech: settings.explicitSpeech,
      semanticsAnnounce: settings.semanticsAnnounce,
    );
  }

  void _setRollSpeed(RollSpeed value) {
    if (value == widget.settings.value.rollSpeed) return;
    widget.settings.setRollSpeed(value);
    _controller.setRollSpeed(value);
    _announceSpeed(value);
  }

  Widget _buildRollSpeedSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speed = widget.settings.value.rollSpeed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.rollSpeedSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in RollSpeed.values)
              MergeSemantics(
                child: Semantics(
                  label: l10n.speedLabel(_speedName(context, option)),
                  child: ChoiceChip(
                    label: ExcludeSemantics(
                      child: Text(_speedName(context, option)),
                    ),
                    selected: speed == option,
                    onSelected: (_) => _setRollSpeed(option),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = widget.settings.value.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appearanceTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.themeLight),
              selected: themeMode == ThemeMode.light,
              onSelected: (_) => widget.settings.setThemeMode(ThemeMode.light),
            ),
            ChoiceChip(
              label: Text(l10n.themeDark),
              selected: themeMode == ThemeMode.dark,
              onSelected: (_) => widget.settings.setThemeMode(ThemeMode.dark),
            ),
            ChoiceChip(
              label: Text(l10n.themeSystem),
              selected: themeMode == ThemeMode.system,
              onSelected: (_) => widget.settings.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeechSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = widget.settings.value;
    return Column(
      children: [
        SwitchListTile(
          title: Text(l10n.speechTitle),
          subtitle: Text(l10n.speechSubtitle),
          value: settings.explicitSpeech,
          onChanged: widget.settings.setExplicitSpeech,
        ),
        SwitchListTile(
          title: Text(l10n.announceTitle),
          subtitle: Text(l10n.announceSubtitle),
          value: settings.semanticsAnnounce,
          onChanged: widget.settings.setSemanticsAnnounce,
        ),
      ],
    );
  }
}
