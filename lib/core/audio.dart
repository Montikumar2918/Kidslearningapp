import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings.dart';

/// Offline audio: on-device text-to-speech + bundled sound effects and music.
/// Every call is guarded so a missing voice or audio error never crashes the app.
class Audio {
  Audio._();
  static final Audio I = Audio._();

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _fx = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  final AudioPlayer _music = AudioPlayer();
  int _next = 0;
  bool hindiVoiceOk = true;
  bool _musicPlaying = false;
  String _lang = '';

  bool get _muted => AppState.I.muted;

  /// Recorded voice files found in assets/voice/. A phrase is played from a
  /// recording when a file named after it exists, e.g. "B says buh, buh" →
  /// assets/voice/b_says_buh_buh.mp3 (or .wav / .m4a). Otherwise the phone voice speaks.
  final Map<String, String> _voices = {};
  final AudioPlayer _voice = AudioPlayer();

  static String slug(String phrase) => phrase
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.25);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      final ok = await _tts.isLanguageAvailable('hi-IN');
      hindiVoiceOk = ok == true || ok == 1;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final a in manifest.listAssets()) {
        if (!a.startsWith('assets/voice/')) continue;
        final name = a.split('/').last;
        final dot = name.lastIndexOf('.');
        if (dot <= 0) continue;
        final ext = name.substring(dot + 1).toLowerCase();
        if (ext == 'mp3' || ext == 'wav' || ext == 'm4a' || ext == 'ogg') {
          _voices[name.substring(0, dot).toLowerCase()] = a.substring('assets/'.length);
        }
      }
      if (_voices.isNotEmpty) debugPrint('Recorded voices: ${_voices.length}');
    } catch (e) {
      debugPrint('Voice manifest failed: $e');
    }
    try {
      for (final p in _fx) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.7);
      }
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.18);
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
  }

  bool _hasDevanagari(String s) => s.runes.any((r) => r >= 0x0900 && r <= 0x097F);

  /// Speak phrases in order. Stops any speech already playing (no overlap).
  Future<void> say(List<String> phrases) async {
    if (_muted) return;
    try {
      await _tts.stop();
      await _voice.stop();
      for (final p in phrases) {
        final rec = _voices[slug(p)];
        if (rec != null) {
          await _voice.play(AssetSource(rec));
          await _voice.onPlayerComplete.first.timeout(const Duration(seconds: 8), onTimeout: () {});
          continue;
        }
        final lang = _hasDevanagari(p) ? 'hi-IN' : 'en-IN';
        if (lang != _lang) {
          await _tts.setLanguage(lang);
          _lang = lang;
        }
        await _tts.speak(p);
      }
    } catch (e) {
      debugPrint('TTS failed: $e');
    }
  }

  /// Play a sound effect from assets/sounds/<name>.wav
  Future<void> fx(String name) async {
    if (_muted) return;
    try {
      final p = _fx[_next];
      _next = (_next + 1) % _fx.length;
      await p.stop();
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (e) {
      debugPrint('FX failed: $e');
    }
  }

  Future<void> note(int i) => fx('note${i.clamp(0, 7)}');

  /// Start/stop background music according to settings.
  Future<void> refreshMusic() async {
    final want = AppState.I.music && !_muted;
    try {
      if (want && !_musicPlaying) {
        _musicPlaying = true;
        await _music.play(AssetSource('sounds/music.wav'));
      } else if (!want && _musicPlaying) {
        _musicPlaying = false;
        await _music.stop();
      }
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  Future<void> pauseAll() async {
    try {
      await _tts.stop();
      await _voice.stop();
      for (final p in _fx) {
        await p.stop();
      }
      if (_musicPlaying) await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    try {
      if (_musicPlaying) await _music.resume();
    } catch (_) {}
  }

  Future<void> stopSpeech() async {
    try {
      await _tts.stop();
      await _voice.stop();
    } catch (_) {}
  }
}
