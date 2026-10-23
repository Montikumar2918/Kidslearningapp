import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

enum AgeMode { baby, toddler, preschool }

class PlacedSticker {
  final String emoji;
  final double x, y; // 0..1 inside the scene
  final int scene;
  PlacedSticker(this.emoji, this.x, this.y, this.scene);

  String encode() => '$emoji|$x|$y|$scene';
  static PlacedSticker? decode(String s) {
    final p = s.split('|');
    if (p.length != 4) return null;
    return PlacedSticker(p[0], double.tryParse(p[1]) ?? .5, double.tryParse(p[2]) ?? .5, int.tryParse(p[3]) ?? 0);
  }
}

const stickerPool = [
  '🦄', '🐼', '🦋', '🌈', '⭐', '🐳', '🦒', '🍭', '🚀', '🌻', '🐠', '🐥', '🦕', '🎈', '🍦', '🐞',
  '🐙', '🦜', '🌙', '🍉', '🐢', '🦊', '🐨', '🎀',
];

/// All app settings and progress. Saved only on this phone (shared_preferences file).
/// No database, no server, no internet.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();
  SharedPreferences? _p;

  bool hindi = false;
  bool calm = false;
  bool muted = false;
  bool music = true;
  AgeMode age = AgeMode.baby;
  int limitMinutes = 15; // 0 = off
  int? birthdayMonth, birthdayDay;
  Set<String> disabledGames = {};

  int stickers = 0;
  List<PlacedSticker> placed = [];
  Set<String> traced = {};
  Map<String, int> plays = {};
  int totalMinutes = 0;
  List<String> toys = [];
  Map<String, List<int>> letterStats = {}; // letter -> [right, wrong]
  bool childLock = true; // hold the home button to leave, back button blocked
  bool teacher = false; // Teacher Mode: all activities unlocked + report card

  // ── Magic Letter Adventure learning model (local only) ──
  int adventureLevel = 0; // how many letters of the A–Z path are finished
  Set<String> introduced = {};
  Map<String, int> demoCount = {}; // demonstrations requested per glyph
  Map<String, int> offTrack = {}; // off-track moments per glyph
  Set<String> garden = {}; // letters planted in the Magic Garden
  List<String> drawings = []; // saved Drawing Studio pictures (JSON)

  /// One present for every 5 stickers.
  int get presents => (stickers ~/ 5 - toys.length).clamp(0, 999);

  DateTime sessionStart = DateTime.now();

  int get unplacedStickers => (stickers - placed.length).clamp(0, 999);

  bool get isBirthday {
    final n = DateTime.now();
    return birthdayMonth == n.month && birthdayDay == n.day;
  }

  Future<void> load() async {
    try {
      final p = _p = await SharedPreferences.getInstance();
      hindi = p.getBool('hindi') ?? false;
      calm = p.getBool('calm') ?? false;
      muted = p.getBool('muted') ?? false;
      music = p.getBool('music') ?? true;
      age = AgeMode.values[(p.getInt('age') ?? 0).clamp(0, 2)];
      limitMinutes = p.getInt('limit') ?? 15;
      birthdayMonth = p.getInt('bMonth');
      birthdayDay = p.getInt('bDay');
      disabledGames = (p.getStringList('disabled') ?? []).toSet();
      stickers = p.getInt('stickers') ?? 0;
      placed = (p.getStringList('placed') ?? []).map(PlacedSticker.decode).whereType<PlacedSticker>().toList();
      traced = (p.getStringList('traced') ?? []).toSet();
      totalMinutes = p.getInt('minutes') ?? 0;
      toys = p.getStringList('toys') ?? [];
      childLock = p.getBool('childLock') ?? true;
      teacher = p.getBool('teacher') ?? false;
      adventureLevel = p.getInt('advLevel') ?? 0;
      introduced = (p.getStringList('introduced') ?? []).toSet();
      garden = (p.getStringList('garden') ?? []).toSet();
      drawings = p.getStringList('drawings') ?? [];
      demoCount = _decodeCounts(p.getStringList('demoCount'));
      offTrack = _decodeCounts(p.getStringList('offTrack'));
      for (final s in p.getStringList('letterStats') ?? <String>[]) {
        final parts = s.split(':');
        if (parts.length == 3) {
          letterStats[parts[0]] = [int.tryParse(parts[1]) ?? 0, int.tryParse(parts[2]) ?? 0];
        }
      }
      for (final s in p.getStringList('plays') ?? <String>[]) {
        final i = s.lastIndexOf(':');
        if (i > 0) plays[s.substring(0, i)] = int.tryParse(s.substring(i + 1)) ?? 0;
      }
    } catch (e) {
      debugPrint('Settings load failed: $e');
    }
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setBool('hindi', hindi);
    p.setBool('calm', calm);
    p.setBool('muted', muted);
    p.setBool('music', music);
    p.setInt('age', age.index);
    p.setInt('limit', limitMinutes);
    if (birthdayMonth != null) p.setInt('bMonth', birthdayMonth!);
    if (birthdayDay != null) p.setInt('bDay', birthdayDay!);
    p.setStringList('disabled', disabledGames.toList());
    p.setInt('stickers', stickers);
    p.setStringList('placed', placed.map((e) => e.encode()).toList());
    p.setStringList('traced', traced.toList());
    p.setInt('minutes', totalMinutes);
    p.setStringList('toys', toys);
    p.setBool('childLock', childLock);
    p.setBool('teacher', teacher);
    p.setInt('advLevel', adventureLevel);
    p.setStringList('introduced', introduced.toList());
    p.setStringList('garden', garden.toList());
    p.setStringList('drawings', drawings);
    p.setStringList('demoCount', demoCount.entries.map((e) => '${e.key}:${e.value}').toList());
    p.setStringList('offTrack', offTrack.entries.map((e) => '${e.key}:${e.value}').toList());
    p.setStringList('letterStats', letterStats.entries.map((e) => '${e.key}:${e.value[0]}:${e.value[1]}').toList());
    p.setStringList('plays', plays.entries.map((e) => '${e.key}:${e.value}').toList());
  }

  void update(void Function() f) {
    f();
    _save();
    notifyListeners();
  }

  /// Gives one sticker and returns its picture.
  String earnSticker() {
    final s = stickerPool[stickers % stickerPool.length];
    update(() => stickers++);
    return s;
  }

  void recordPlay(String id) => update(() => plays[id] = (plays[id] ?? 0) + 1);
  void recordTraced(String l) => update(() => traced.add(l));
  void addMinute() => update(() => totalMinutes++);

  /// Remember right / wrong answers per letter for the report card.
  void recordLetter(String letter, bool right) => update(() {
        final k = letter.toUpperCase();
        final v = letterStats[k] ?? [0, 0];
        letterStats[k] = right ? [v[0] + 1, v[1]] : [v[0], v[1] + 1];
      });

  static Map<String, int> _decodeCounts(List<String>? l) {
    final m = <String, int>{};
    for (final s in l ?? const <String>[]) {
      final i = s.lastIndexOf(':');
      if (i > 0) m[s.substring(0, i)] = int.tryParse(s.substring(i + 1)) ?? 0;
    }
    return m;
  }

  void recordDemo(String g) => update(() => demoCount[g] = (demoCount[g] ?? 0) + 1);
  void recordOffTrack(String g) => update(() => offTrack[g] = (offTrack[g] ?? 0) + 1);
  void markIntroduced(String g) => update(() => introduced.add(g));

  void finishAdventureLetter(int index) => update(() {
        if (index + 1 > adventureLevel) adventureLevel = (index + 1).clamp(0, 26);
      });

  /// Letters that could use a little more practice (gentle revision, not a diagnosis):
  /// many demos requested, often off the path, or low recognition accuracy.
  List<String> practiceSuggestions() {
    final out = <String, double>{};
    for (final g in introduced) {
      final k = g.toUpperCase();
      final st = letterStats[k];
      final tries = st == null ? 0 : st[0] + st[1];
      final acc = tries == 0 ? 1.0 : st![0] / tries;
      final score = (demoCount[g] ?? 0) * 1.0 + (offTrack[g] ?? 0) * 0.5 + (tries >= 3 && acc < 0.6 ? 3 : 0);
      if (score >= 3) out[g] = score;
    }
    final l = out.keys.toList()..sort((a, b) => out[b]!.compareTo(out[a]!));
    return l;
  }

  String openPresent(int seed) {
    final t = toyPool[(toys.length * 7 + seed) % toyPool.length];
    update(() => toys.add(t));
    return t;
  }

  void resetProgress() => update(() {
        stickers = 0;
        placed = [];
        traced = {};
        plays = {};
        totalMinutes = 0;
        toys = [];
        letterStats = {};
        adventureLevel = 0;
        introduced = {};
        demoCount = {};
        offTrack = {};
        garden = {};
      });
}
