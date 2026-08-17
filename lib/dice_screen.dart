import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dice_controller.dart';
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
  final Settings settings;
  final SpeechService? speech;

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  static const List<int> _presets = [4, 6, 8, 10, 12, 20];

  late final DiceController _controller;
  late final SpeechService _speech;
  late Settings _settings;

  RollState? _lastState;
  int? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _speech = widget.speech ?? SpeechService();
    _settings = widget.settings;
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
    await _speech.announceStart(
      context,
      explicitSpeech: _settings.explicitSpeech,
      semanticsAnnounce: _settings.semanticsAnnounce,
    );
  }

  Future<void> _announceResult(int value) async {
    if (!mounted) return;
    await _speech.announceResult(
      context,
      value,
      explicitSpeech: _settings.explicitSpeech,
      semanticsAnnounce: _settings.semanticsAnnounce,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mluvící hrací kostka')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
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
                    'Podržte tlačítko a kostka se bude točit. Po uvolnění se zpomalí '
                    'a zastaví na výsledném čísle. Stiskem klávesy nebo aktivací '
                    'kostku roztočíte a druhým stiskem zastavíte.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildSidesSection(context),
                  const SizedBox(height: 16),
                  _buildSpeechSettings(),
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
    final value = _controller.currentValue;
    final label = switch (_controller.state) {
      RollState.rolling || RollState.decelerating => 'Házím kostkou.',
      RollState.done => 'Padlo číslo $value.',
      RollState.idle when value != null => 'Poslední hod: $value.',
      RollState.idle => 'Kostka je připravená. Hodit kostkou.',
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
    final (label, onTap) = switch (_controller.state) {
      RollState.rolling ||
      RollState.decelerating => ('Zastavit hod', _controller.toggle),
      RollState.idle || RollState.done => ('Hodit kostkou', _controller.toggle),
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
    final sides = _controller.sides;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Počet stran', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              ChoiceChip(
                label: Text('d$preset'),
                selected: sides == preset,
                onSelected: (_) => _setSides(preset),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: 'Snížit počet stran',
              onPressed: () => _setSides(sides - 1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 24),
            Semantics(
              label: 'Počet stran: $sides',
              child: ExcludeSemantics(
                child: Text(
                  '$sides',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton.filledTonal(
              tooltip: 'Zvýšit počet stran',
              onPressed: () => _setSides(sides + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  void _setSides(int value) {
    setState(() {
      _settings = _settings.copyWith(sides: value.clamp(2, 100));
      _controller.setSides(_settings.sides);
      _settings.save();
    });
  }

  Widget _buildSpeechSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Vlastní hlas (TTS)'),
          subtitle: const Text('Kostka mluví i bez aktivní čtečky obrazovky.'),
          value: _settings.explicitSpeech,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(explicitSpeech: value);
              _settings.save();
            });
          },
        ),
        SwitchListTile(
          title: const Text('Oznámení pro čtečku obrazovky'),
          subtitle: const Text('Výsledky oznamuje aktivní čtečka.'),
          value: _settings.semanticsAnnounce,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(semanticsAnnounce: value);
              _settings.save();
            });
          },
        ),
      ],
    );
  }
}
