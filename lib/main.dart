import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dice_controller.dart';
import 'dice_screen.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(App(settings: settings));
}

class App extends StatefulWidget {
  const App({super.key, required this.settings});

  final Settings settings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final DiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiceController(sides: widget.settings.sides);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mluvící hrací kostka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('cs'), Locale('en')],
      locale: const Locale('cs'),
      home: DiceScreen(
        controller: _controller,
        settings: widget.settings,
      ),
    );
  }
}
