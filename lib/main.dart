import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/settings.dart';
import 'screens/home.dart';
import 'screens/parent.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AppState.I.load();
  await Audio.I.init();
  runApp(const KidsLearningApp());
}

class KidsLearningApp extends StatefulWidget {
  const KidsLearningApp({super.key});
  @override
  State<KidsLearningApp> createState() => _KidsLearningAppState();
}

class _KidsLearningAppState extends State<KidsLearningApp> with WidgetsBindingObserver {
  Timer? _clock;
  bool _active = true;
  bool _resting = false;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppState.I.sessionStart = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) => _checkTime());
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkTime() {
    if (!_active) return;
    _seconds += 15;
    if (_seconds >= 60) {
      _seconds = 0;
      AppState.I.addMinute();
    }
    final limit = AppState.I.limitMinutes;
    if (limit <= 0 || _resting) return;
    if (DateTime.now().difference(AppState.I.sessionStart).inMinutes >= limit) {
      _resting = true;
      Audio.I.pauseAll();
      Audio.I.say([AppState.I.hindi ? 'आराम का समय! चलो बाहर खेलें।' : "Time to rest! Let's play outside."]);
      navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => const RestScreen()))
          .then((_) => _resting = false);
    }
  }

  // Pause all sound when the app goes to background, and restart session time after a long break.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _active = true;
      Audio.I.resumeMusic();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _active = false;
      Audio.I.pauseAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Kids Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8A65)),
      ),
      home: const HomeScreen(),
    );
  }
}
