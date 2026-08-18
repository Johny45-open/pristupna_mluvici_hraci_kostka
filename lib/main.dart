import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dice_controller.dart';
import 'dice_screen.dart';
import 'l10n/app_localizations.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  runApp(App(settings: settings));
}

class App extends StatefulWidget {
  const App({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final DiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiceController(sides: widget.settings.value.sides);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: widget.settings.value.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: DiceScreen(
            controller: _controller,
            settings: widget.settings,
          ),
        );
      },
    );
  }
}
