import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Offline audio: on-device text-to-speech for words + bundled soft sound effects.
/// Every call is wrapped so a missing voice or audio error never crashes the app.
class Audio {
  Audio._();
  static final Audio I = Audio._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _fx = AudioPlayer();
  bool muted = false;
  bool hindiVoiceOk = true;
  String _lang = '';

  Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.38); // slow & clear for babies
      await _tts.setPitch(1.25); // friendly, higher voice
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      final ok = await _tts.isLanguageAvailable('hi-IN');
      hindiVoiceOk = ok == true || ok == 1;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
    try {
      await _fx.setReleaseMode(ReleaseMode.stop);
      await _fx.setVolume(0.6);
    } catch (_) {}
  }

  bool _hasDevanagari(String s) => s.runes.any((r) => r >= 0x0900 && r <= 0x097F);

  /// Speak one or more phrases in order. Stops anything already playing (no overlap).
  Future<void> say(List<String> phrases) async {
    if (muted) return;
    try {
      await _tts.stop();
      for (final p in phrases) {
        final lang = _hasDevanagari(p) ? 'hi-IN' : 'en-IN';
        if (lang != _lang) {
          await _tts.setLanguage(lang);
          _lang = lang;
        }
        await _tts.speak(p);
      }
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> fx(String name) async {
    if (muted) return;
    try {
      await _fx.stop();
      await _fx.play(AssetSource('sounds/$name.wav'));
    } catch (e) {
      debugPrint('FX failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      await _fx.stop();
    } catch (_) {}
  }
}
