import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'screens.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Audio.I.init();
  runApp(const KidsLearningApp());
}

class KidsLearningApp extends StatefulWidget {
  const KidsLearningApp({super.key});
  @override
  State<KidsLearningApp> createState() => _KidsLearningAppState();
}

class _KidsLearningAppState extends State<KidsLearningApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Stop all sound when the app goes to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) Audio.I.stop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Settings.I,
      builder: (_, __) => MaterialApp(
        title: 'Kids Learning App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8A65)),
          fontFamily: 'sans-serif',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
