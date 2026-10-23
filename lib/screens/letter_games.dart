import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import 'abc_trace.dart';
import 'games_a.dart';
import 'games_b.dart';
import 'tracing.dart';

final _rnd = Random();
const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
List<String> get _all => _letters.split('');
String _randLetter([Set<String> not = const {}]) {
  String l;
  do {
    l = _letters[_rnd.nextInt(26)];
  } while (not.contains(l));
  return l;
}

const _tileColors = [
  Color(0xFFEF5350), Color(0xFFFFA726), Color(0xFFFFCA28), Color(0xFF66BB6A),
  Color(0xFF29B6F6), Color(0xFF5C6BC0), Color(0xFFAB47BC), Color(0xFFEC407A),
];
Color letterColor(String l) => _tileColors[(l.toUpperCase().codeUnitAt(0)) % _tileColors.length];

class LetterBall extends StatelessWidget {
  final String letter;
  final double size;
  final Color? color;
  const LetterBall({super.key, required this.letter, this.size = 80, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? letterColor(letter);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Color.lerp(c, Colors.white, 0.4)!, c]),
        border: Border.all(color: Colors.white, width: size * 0.06),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
    );
  }
}

// ═════════════════════════════ ABC LAND (hub) ═════════════════════════════

class LetterGame {
  final String id, en, hi, emoji, group; // group: tracing | phonics | games
  final AgeMode minAge;
  final Widget Function() build;
  const LetterGame(this.id, this.en, this.hi, this.emoji, this.group, this.minAge, this.build);
}

final letterGames = [
  LetterGame('sounds', 'Letter Sounds', 'अक्षर ध्वनि', '🔊', 'phonics', AgeMode.baby, () => const PhonicsScreen()),
  LetterGame('bubbleaz', 'Bubble A–Z', 'बुलबुले A–Z', '🫧', 'games', AgeMode.baby, () => const BubbleAZScreen()),
  LetterGame('abcdoor', 'Alphabet House', 'अक्षर घर', '🏠', 'games', AgeMode.baby, () => const DoorbellScreen(letters: true)),
  LetterGame('tracecap', 'Trace ABC', 'ABC लिखो', '✍️', 'tracing', AgeMode.toddler,
      () => ArrowTraceScreen(items: abc, id: 'tracecap')),
  LetterGame('tracesmall', 'Trace abc', 'abc लिखो', '✏️', 'tracing', AgeMode.toddler,
      () => ArrowTraceScreen(items: abcSmall, id: 'tracesmall')),
  LetterGame('tracenum', 'Trace 123', '123 लिखो', '🔢', 'tracing', AgeMode.toddler,
      () => ArrowTraceScreen(items: numbers, id: 'tracenum')),
  LetterGame('tracehindi', 'Trace अ क', 'अ क लिखो', 'अ', 'tracing', AgeMode.toddler, () => const TracingMenuScreen()),
  LetterGame('soundmatch', 'Sound Match', 'आवाज़ मिलाओ', '👂', 'phonics', AgeMode.toddler, () => const SoundMatchScreen()),
  LetterGame('casematch', 'Big & Small', 'बड़ा और छोटा', '🔠', 'phonics', AgeMode.toddler, () => const CaseMatchScreen()),
  LetterGame('trampoline', 'Trampoline', 'उछल कूद', '🤸', 'games', AgeMode.toddler, () => const TrampolineScreen()),
  LetterGame('collect', 'Collect Letters', 'अक्षर पकड़ो', '🧺', 'games', AgeMode.toddler, () => const CollectLettersScreen()),
  LetterGame('abcpuzzle', 'Letter Puzzle', 'अक्षर पहेली', '🧩', 'games', AgeMode.toddler, () => const PuzzleScreen(letters: true)),
  LetterGame('frog', 'Frog Jump', 'मेंढक कूद', '🐸', 'games', AgeMode.toddler, () => const FrogScreen()),
  LetterGame('colorletters', 'Color by Letters', 'अक्षर से रंग', '🖍️', 'games', AgeMode.toddler, () => const ColorByLettersScreen()),
  LetterGame('bingo', 'ABC Bingo', 'ABC बिंगो', '🎯', 'games', AgeMode.preschool, () => const BingoScreen()),
  LetterGame('sort', 'Letter Sorting', 'अक्षर छाँटो', '🗂️', 'phonics', AgeMode.preschool, () => const LetterSortScreen()),
  LetterGame('order', 'Caterpillar', 'इल्ली', '🐛', 'games', AgeMode.preschool, () => const OrderScreen()),
  LetterGame('writing', 'A–Z Writing', 'A–Z लेखन', '📝', 'tracing', AgeMode.preschool,
      () => ArrowTraceScreen(items: abc, id: 'writing', writing: true)),
];

bool letterGameVisible(LetterGame g) {
  final s = AppState.I;
  if (s.disabledGames.contains(g.id) || s.disabledGames.contains('group:${g.group}')) return false;
  return s.teacher || g.minAge.index <= s.age.index;
}

class AbcLandScreen extends StatelessWidget {
  const AbcLandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final hi = AppState.I.hindi;
        final games = letterGames.where(letterGameVisible).toList();
        return GameScaffold(
          id: 'abcland',
          color: const Color(0xFF90CAF9),
          title: hi ? 'ABC नगर' : 'ABC Land',
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TalkingMascot(
                kind: MascotKind.chiku,
                mood: Mood.wave,
                size: 70,
                text: hi ? 'कौन सा खेल खेलें?' : 'Which letter game?',
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                return GridView.count(
                  padding: const EdgeInsets.all(14),
                  crossAxisCount: box.maxWidth > 600 ? 4 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final g in games)
                      GestureDetector(
                        onTap: () {
                          Audio.I.fx('whoosh');
                          Audio.I.say([hi ? g.hi : g.en]);
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => g.build()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _groupColor(g.group), width: 4),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Expanded(
                              child: FittedBox(
                                child: Text(g.emoji,
                                    style: TextStyle(
                                        fontSize: 48, fontWeight: FontWeight.w900, color: _groupColor(g.group))),
                              ),
                            ),
                            Text(hi ? g.hi : g.en,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ]),
        );
      },
    );
  }

  static Color _groupColor(String g) => switch (g) {
        'tracing' => const Color(0xFF42A5F5),
        'phonics' => const Color(0xFFAB47BC),
        _ => const Color(0xFFFF7043),
      };
}

// ═════════════════════════════ PHONICS: Letter Sounds ═════════════════════════════

class PhonicsScreen extends StatefulWidget {
  const PhonicsScreen({super.key});
  @override
  State<PhonicsScreen> createState() => _PhonicsScreenState();
}

class _PhonicsScreenState extends State<PhonicsScreen> {
  bool _small = false;
  int? _flipped;

  void _tap(int i) {
    HapticFeedback.lightImpact();
    Audio.I.fx('pop');
    setState(() => _flipped = i);
    final it = _small ? abcSmall[i] : abc[i];
    Audio.I.say(letterSoundPhrase(it));
    AppState.I.recordLetter(abc[i].label!, true);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted && _flipped == i) setState(() => _flipped = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'sounds',
      color: const Color(0xFFE1BEE7),
      title: hi ? 'अक्षर की आवाज़' : 'Letter Sounds',
      trailing: GestureDetector(
        onTap: () => setState(() => _small = !_small),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Text(_small ? 'abc' : 'ABC', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
      ),
      child: GridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          for (var i = 0; i < 26; i++)
            GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: _flipped == i
                    ? Container(
                        key: const ValueKey('pic'),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: letterColor(abc[i].label!), width: 4),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(children: [
                              Text(abc[i].emoji, style: const TextStyle(fontSize: 40)),
                              Text('/${soundOf(abc[i].label!)}/',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('letter'),
                        decoration: BoxDecoration(
                          color: letterColor(abc[i].label!),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        alignment: Alignment.center,
                        child: Text(_small ? abcSmall[i].label! : abc[i].label!,
                            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ PHONICS: Sound Match ═════════════════════════════

class SoundMatchScreen extends StatefulWidget {
  const SoundMatchScreen({super.key});
  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen> {
  late String _target;
  late List<String> _choices;
  String? _wrong;
  bool _done = false;
  int _right = 0;
  Mood _mood = Mood.idle;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _target = _randLetter();
    final set = <String>{_target};
    // avoid two letters with the same sound (C/K)
    while (set.length < 3) {
      final l = _randLetter(set);
      if (soundOf(l) != soundOf(_target)) set.add(l);
    }
    _choices = set.toList()..shuffle(_rnd);
    _wrong = null;
    _done = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() {
    final s = soundOf(_target);
    Audio.I.say(['Which letter says $s?', s, s]);
  }

  void _pick(String l) {
    if (_done) return;
    if (l == _target) {
      AppState.I.recordLetter(l, true);
      setState(() {
        _done = true;
        _right++;
        _mood = Mood.happy;
      });
      Audio.I.fx('chime');
      if (_right % 5 == 0) {
        celebrate(context);
      } else {
        Audio.I.say(['Yes! $l says ${soundOf(l)}']);
      }
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) {
          setState(() {
            _mood = Mood.idle;
            _newRound();
          });
        }
      });
    } else {
      AppState.I.recordLetter(_target, false);
      setState(() => _wrong = l);
      Audio.I.fx('boing');
      Audio.I.say(['$l says ${soundOf(l)}. Listen again: ${soundOf(_target)}']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'soundmatch',
      color: const Color(0xFFCE93D8),
      onSpeak: _ask,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TalkingMascot(kind: MascotKind.chiku, mood: _mood, size: 90, text: '👂 /${soundOf(_target)}/', onTap: _ask),
        ),
        Expanded(
          child: Center(
            child: Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
              for (final l in _choices)
                GestureDetector(
                  onTap: () => _pick(l),
                  child: AnimatedScale(
                    scale: _done && l != _target ? 0.6 : (_done ? 1.2 : 1),
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedOpacity(
                      opacity: _wrong == l ? 0.5 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: LetterBall(letter: l, size: 130),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ PHONICS: Big & Small (drag) ═════════════════════════════

class CaseMatchScreen extends StatefulWidget {
  const CaseMatchScreen({super.key});
  @override
  State<CaseMatchScreen> createState() => _CaseMatchScreenState();
}

class _CaseMatchScreenState extends State<CaseMatchScreen> {
  late String _cap;
  late List<String> _smalls;
  bool _matched = false;
  int _right = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _cap = _randLetter();
    final set = <String>{_cap};
    while (set.length < 3) {
      set.add(_randLetter(set));
    }
    _smalls = set.map((e) => e.toLowerCase()).toList()..shuffle(_rnd);
    _matched = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() => Audio.I.say(['Find small ${_cap.toLowerCase()} for big $_cap']);

  void _drop(String s) {
    if (s.toUpperCase() == _cap) {
      AppState.I.recordLetter(_cap, true);
      HapticFeedback.mediumImpact();
      Audio.I.fx('chime');
      setState(() {
        _matched = true;
        _right++;
      });
      if (_right % 4 == 0) {
        celebrate(context);
      } else {
        Audio.I.say(['Big $_cap, small $s. ${abcItem(_cap).en}']);
      }
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (mounted) setState(_newRound);
      });
    } else {
      AppState.I.recordLetter(_cap, false);
      Audio.I.fx('boing');
      Audio.I.say(['That is small $s. Try again!']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'casematch',
      color: const Color(0xFFB3E5FC),
      title: hi ? 'बड़ा और छोटा मिलाओ' : 'Match big and small',
      onSpeak: _ask,
      child: Column(children: [
        const SizedBox(height: 12),
        DragTarget<String>(
          onAcceptWithDetails: (d) => _drop(d.data),
          builder: (_, cand, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 240,
            height: 220,
            decoration: BoxDecoration(
              color: cand.isNotEmpty ? const Color(0xFFFFF9C4) : Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: letterColor(_cap), width: 6),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_cap, style: TextStyle(fontSize: 110, fontWeight: FontWeight.w900, color: letterColor(_cap))),
              if (_matched)
                Text(_cap.toLowerCase(),
                    style: TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: darker(letterColor(_cap)))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text(hi ? '👇 छोटा अक्षर ऊपर खींचो' : '👇 Drag the small letter up',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black54)),
        Expanded(
          child: Center(
            child: Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
              for (final s in _smalls)
                if (!(_matched && s.toUpperCase() == _cap))
                  Draggable<String>(
                    data: s,
                    feedback: Material(color: Colors.transparent, child: LetterBall(letter: s, size: 120)),
                    childWhenDragging: Opacity(opacity: 0.25, child: LetterBall(letter: s, size: 110)),
                    onDragStarted: () => Audio.I.fx('tick'),
                    child: LetterBall(letter: s, size: 110),
                  ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ Bubble A–Z: pop the asked letter ═════════════════════════════

class BubbleAZScreen extends StatefulWidget {
  const BubbleAZScreen({super.key});
  @override
  State<BubbleAZScreen> createState() => _BubbleAZScreenState();
}

class _LB {
  double x, y, r, speed, wob;
  final String l;
  _LB(this.x, this.y, this.r, this.speed, this.wob, this.l);
}

class _BubbleAZScreenState extends State<BubbleAZScreen> with SingleTickerProviderStateMixin {
  final List<_LB> _b = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  late String _target;
  int _found = 0;
  final List<Offset> _pops = [];

  @override
  void initState() {
    super.initState();
    _target = _randLetter();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ask() => Audio.I.say(['Pop the letter $_target!']);

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    while (_b.length < 6) {
      final hasTarget = _b.any((e) => e.l == _target);
      final l = !hasTarget || _rnd.nextDouble() < 0.35 ? _target : _randLetter({_target});
      final r = 50.0 + _rnd.nextDouble() * 20;
      _b.add(_LB(r + _rnd.nextDouble() * (_size.width - 2 * r), _size.height + r, r,
          (AppState.I.calm ? 30 : 50) + _rnd.nextDouble() * 30, _rnd.nextDouble() * 6, l));
    }
    for (final b in _b) {
      b.y -= b.speed * dt;
      b.wob += dt * 1.6;
    }
    _b.removeWhere((b) => b.y < -b.r);
    setState(() {});
  }

  void _pop(_LB b) {
    HapticFeedback.mediumImpact();
    Audio.I.fx('pop');
    setState(() {
      _b.remove(b);
      _pops
        ..clear()
        ..add(Offset(b.x, b.y));
    });
    if (b.l == _target) {
      AppState.I.recordLetter(b.l, true);
      _found++;
      Audio.I.say(['$_target! ${soundOf(_target)}']);
      if (_found % 5 == 0) {
        celebrate(context);
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _target = _randLetter({_target}));
          _ask();
        });
      }
    } else {
      Audio.I.say(['${b.l}. Find $_target!']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'bubbleaz',
      color: const Color(0xFF81D4FA),
      onSpeak: _ask,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        LetterBall(letter: _target, size: 56),
        const SizedBox(width: 6),
        Text('${_found % 5}/5', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
      ]),
      child: LayoutBuilder(builder: (context, box) {
        _size = box.biggest;
        return Stack(children: [
          for (final b in _b)
            Positioned(
              left: b.x - b.r + sin(b.wob) * 10,
              top: b.y - b.r,
              child: GestureDetector(
                onTapDown: (_) => _pop(b),
                child: Container(
                  width: b.r * 2,
                  height: b.r * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      colors: [Colors.white, letterColor(b.l).withValues(alpha: 0.55)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(b.l,
                      style: TextStyle(fontSize: b.r * 0.95, fontWeight: FontWeight.w900, color: darker(letterColor(b.l)))),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

// ═════════════════════════════ Trampoline ═════════════════════════════

class TrampolineScreen extends StatefulWidget {
  const TrampolineScreen({super.key});
  @override
  State<TrampolineScreen> createState() => _TrampolineScreenState();
}

class _Fly {
  double x, y;
  final String l;
  _Fly(this.x, this.y, this.l);
}

class _TrampolineScreenState extends State<TrampolineScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  double _tx = 0.5; // trampoline x (0..1)
  double _phase = 0;
  double _spawn = 0;
  final List<_Fly> _flies = [];
  late String _target;
  int _caught = 0;
  Mood _mood = Mood.idle;

  @override
  void initState() {
    super.initState();
    _target = _randLetter();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ask() => Audio.I.say(['Jump and catch the letter $_target!']);

  double get _jump => sin(_phase).abs(); // 0 on trampoline, 1 at top

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    final prev = sin(_phase).abs();
    _phase += dt * (AppState.I.calm ? 1.8 : 2.6);
    if (sin(_phase).abs() < 0.08 && prev >= 0.08) Audio.I.fx('boing');
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = 1.4 + _rnd.nextDouble();
      final l = _rnd.nextDouble() < 0.45 ? _target : _randLetter({_target});
      _flies.add(_Fly(1.1, 0.15 + _rnd.nextDouble() * 0.4, l));
    }
    final w = _size.width, h = _size.height;
    final mx = _tx * w, my = h * 0.72 - _jump * h * 0.55;
    final hit = <_Fly>[];
    for (final f in _flies) {
      f.x -= dt * (AppState.I.calm ? 0.1 : 0.15);
      if ((Offset(f.x * w, f.y * h) - Offset(mx, my)).distance < 70) hit.add(f);
    }
    _flies.removeWhere((f) => f.x < -0.1);
    for (final f in hit) {
      _flies.remove(f);
      if (f.l == _target) {
        _caught++;
        AppState.I.recordLetter(f.l, true);
        Audio.I.fx('chime');
        Audio.I.say(['$_target!']);
        _mood = Mood.happy;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _mood = Mood.idle);
        });
        if (_caught % 5 == 0) {
          celebrate(context);
          _target = _randLetter({_target});
          Future.delayed(const Duration(seconds: 3), _ask);
        }
      } else {
        Audio.I.say(['${f.l}. Catch $_target!']);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'trampoline',
      color: const Color(0xFFFFE082),
      hills: true,
      onSpeak: _ask,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        LetterBall(letter: _target, size: 56),
        const SizedBox(width: 6),
        Text('${_caught % 5}/5', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
      ]),
      child: LayoutBuilder(builder: (context, box) {
        _size = box.biggest;
        final w = box.maxWidth, h = box.maxHeight;
        final mx = _tx * w, my = h * 0.72 - _jump * h * 0.55;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _tx = (d.localPosition.dx / w).clamp(0.1, 0.9),
          onTapDown: (d) => _tx = (d.localPosition.dx / w).clamp(0.1, 0.9),
          child: Stack(children: [
            for (final f in _flies)
              Positioned(left: f.x * w - 38, top: f.y * h - 38, child: LetterBall(letter: f.l, size: 76)),
            // trampoline
            Positioned(
              left: mx - 80,
              top: h * 0.8,
              child: CustomPaint(size: const Size(160, 60), painter: _TrampolinePainter(1 - _jump)),
            ),
            Positioned(
              left: mx - 55,
              top: my - 55,
              child: Mascot(kind: MascotKind.chiku, mood: _mood, size: 110),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Text('👈 move 👉',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.black.withValues(alpha: 0.4))),
            ),
          ]),
        );
      }),
    );
  }
}

class _TrampolinePainter extends CustomPainter {
  final double press; // 1 when the bird lands
  _TrampolinePainter(this.press);
  @override
  void paint(Canvas canvas, Size s) {
    final legs = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(16, 14), Offset(6, s.height), legs);
    canvas.drawLine(Offset(s.width - 16, 14), Offset(s.width - 6, s.height), legs);
    final sag = press > 0.9 ? (press - 0.9) * 10 * 14 : 0.0;
    final mat = Path()
      ..moveTo(8, 12)
      ..quadraticBezierTo(s.width / 2, 12 + sag * 2, s.width - 8, 12);
    canvas.drawPath(
        mat,
        Paint()
          ..color = const Color(0xFF1E88E5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _TrampolinePainter o) => o.press != press;
}

// ═════════════════════════════ Collect Letters (basket) ═════════════════════════════

class CollectLettersScreen extends StatefulWidget {
  const CollectLettersScreen({super.key});
  @override
  State<CollectLettersScreen> createState() => _CollectLettersScreenState();
}

class _Drop {
  double x, y, speed;
  final String l;
  _Drop(this.x, this.y, this.speed, this.l);
}

class _CollectLettersScreenState extends State<CollectLettersScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  double _basket = 0.5, _spawn = 0, _squash = 0;
  final List<_Drop> _drops = [];
  late String _target;
  int _caught = 0;

  @override
  void initState() {
    super.initState();
    _target = _randLetter();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ask() => Audio.I.say(['Catch the letter $_target in the basket!']);

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    _spawn -= dt;
    if (_spawn <= 0 && _drops.length < 4) {
      _spawn = 1.2 + _rnd.nextDouble();
      final l = _rnd.nextDouble() < 0.5 ? _target : _randLetter({_target});
      _drops.add(_Drop(0.1 + _rnd.nextDouble() * 0.8, 0.0, (AppState.I.calm ? 0.09 : 0.13) + _rnd.nextDouble() * 0.05, l));
    }
    final got = <_Drop>[];
    for (final d in _drops) {
      d.y += d.speed * dt;
      if (d.y > 0.78 && d.y < 0.9 && (d.x - _basket).abs() < 0.14) got.add(d);
    }
    _drops.removeWhere((d) => d.y > 1.05);
    for (final d in got) {
      _drops.remove(d);
      _squash = 1;
      if (d.l == _target) {
        _caught++;
        AppState.I.recordLetter(d.l, true);
        Audio.I.fx('chime');
        Audio.I.say([d.l]);
        if (_caught % 5 == 0) {
          celebrate(context, text: 'Basket full of $_target!');
          _target = _randLetter({_target});
          Future.delayed(const Duration(seconds: 3), _ask);
        }
      } else {
        Audio.I.fx('boing');
        Audio.I.say(['Oops, ${d.l}! Catch $_target']);
      }
    }
    _squash = max(0, _squash - dt * 4);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'collect',
      color: const Color(0xFFC5E1A5),
      hills: true,
      onSpeak: _ask,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        LetterBall(letter: _target, size: 56),
        const SizedBox(width: 6),
        Text('${_caught % 5}/5', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
      ]),
      child: LayoutBuilder(builder: (context, box) {
        _size = box.biggest;
        final w = box.maxWidth, h = box.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _basket = (d.localPosition.dx / w).clamp(0.08, 0.92),
          onTapDown: (d) => _basket = (d.localPosition.dx / w).clamp(0.08, 0.92),
          child: Stack(children: [
            for (final d in _drops)
              Positioned(left: d.x * w - 36, top: d.y * h - 36, child: LetterBall(letter: d.l, size: 72)),
            Positioned(
              left: _basket * w - 60,
              top: h * 0.8,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(1 + _squash * 0.15, 1 - _squash * 0.15, 1),
                child: const SizedBox(
                    width: 120, child: Text('🧺', textAlign: TextAlign.center, style: TextStyle(fontSize: 84))),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ═════════════════════════════ ABC Bingo ═════════════════════════════

class BingoScreen extends StatefulWidget {
  const BingoScreen({super.key});
  @override
  State<BingoScreen> createState() => _BingoScreenState();
}

class _BingoScreenState extends State<BingoScreen> {
  late int _n;
  late List<String> _card;
  final Set<int> _marked = {};
  String? _called;
  int? _wrong;
  List<int>? _winLine;

  @override
  void initState() {
    super.initState();
    _newCard();
  }

  void _newCard() {
    _n = AppState.I.age == AgeMode.preschool ? 4 : 3;
    _card = (_all..shuffle(_rnd)).take(_n * _n).toList();
    _marked.clear();
    _winLine = null;
    _call();
  }

  void _call() {
    final left = [for (var i = 0; i < _card.length; i++) if (!_marked.contains(i)) _card[i]];
    if (left.isEmpty) return;
    _called = left[_rnd.nextInt(left.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  void _say() => Audio.I.say(['Find $_called!', '$_called says ${soundOf(_called!)}']);

  List<List<int>> get _lines {
    final n = _n;
    return [
      for (var r = 0; r < n; r++) [for (var c = 0; c < n; c++) r * n + c],
      for (var c = 0; c < n; c++) [for (var r = 0; r < n; r++) r * n + c],
      [for (var i = 0; i < n; i++) i * n + i],
      [for (var i = 0; i < n; i++) i * n + (n - 1 - i)],
    ];
  }

  void _tap(int i) {
    if (_winLine != null || _marked.contains(i)) return;
    if (_card[i] == _called) {
      HapticFeedback.mediumImpact();
      Audio.I.fx('pop');
      AppState.I.recordLetter(_card[i], true);
      setState(() => _marked.add(i));
      for (final line in _lines) {
        if (line.every(_marked.contains)) {
          setState(() => _winLine = line);
          celebrate(context, text: 'BINGO!');
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) setState(_newCard);
          });
          return;
        }
      }
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(_call);
      });
    } else {
      AppState.I.recordLetter(_called!, false);
      setState(() => _wrong = i);
      Audio.I.fx('boing');
      Audio.I.say(['That is ${_card[i]}. Find $_called']);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'bingo',
      color: const Color(0xFFFFCC80),
      title: 'ABC Bingo',
      onSpeak: _say,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TalkingMascot(
              kind: MascotKind.golu,
              mood: _winLine != null ? Mood.happy : Mood.idle,
              size: 80,
              text: _winLine != null ? 'BINGO! 🎉' : 'Find  ${_called ?? ''}',
              onTap: _say),
        ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFFF7043), width: 6),
                ),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _n,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < _card.length; i++)
                      GestureDetector(
                        onTap: () => _tap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: _winLine?.contains(i) == true
                                ? const Color(0xFFFFF176)
                                : (_wrong == i ? const Color(0xFFFFCDD2) : const Color(0xFFFFF3E0)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            Text(_card[i],
                                style: TextStyle(fontSize: _n == 3 ? 64 : 46, fontWeight: FontWeight.w900, color: letterColor(_card[i]))),
                            if (_marked.contains(i))
                              const IgnorePointer(child: Text('⭐', style: TextStyle(fontSize: 54))),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ Letter Sorting ═════════════════════════════

class LetterSortScreen extends StatefulWidget {
  const LetterSortScreen({super.key});
  @override
  State<LetterSortScreen> createState() => _LetterSortScreenState();
}

class _LetterSortScreenState extends State<LetterSortScreen> {
  bool _vowelMode = false; // false: capital vs small, true: vowels vs others
  late List<String> _cards;
  final List<String> _left = [], _right = [];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _left.clear();
    _right.clear();
    if (_vowelMode) {
      final v = (vowels.toList()..shuffle(_rnd)).take(3);
      final c = (_all.where((l) => !vowels.contains(l)).toList()..shuffle(_rnd)).take(3);
      _cards = [...v, ...c]..shuffle(_rnd);
    } else {
      final ls = (_all..shuffle(_rnd)).take(6).toList();
      _cards = [for (var i = 0; i < 6; i++) i.isEven ? ls[i] : ls[i].toLowerCase()]..shuffle(_rnd);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() => Audio.I.say([
        _vowelMode ? 'Put vowels A E I O U in the red box, other letters in the blue box' : 'Put big letters here, small letters there'
      ]);

  bool _belongsLeft(String l) => _vowelMode ? vowels.contains(l.toUpperCase()) : l.toUpperCase() == l;

  void _drop(String l, bool left) {
    if (_belongsLeft(l) == left) {
      AppState.I.recordLetter(l, true);
      HapticFeedback.lightImpact();
      Audio.I.fx('pop');
      Audio.I.say([_vowelMode ? l : (left ? 'big $l' : 'small $l')]);
      setState(() {
        _cards.remove(l);
        (left ? _left : _right).add(l);
      });
      if (_cards.isEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          celebrate(context);
          Future.delayed(const Duration(seconds: 3), () {
            if (!mounted) return;
            setState(() {
              _vowelMode = AppState.I.age == AgeMode.preschool ? !_vowelMode : false;
              _newRound();
            });
          });
        });
      }
    } else {
      AppState.I.recordLetter(l, false);
      Audio.I.fx('boing');
      Audio.I.say([
        _vowelMode
            ? (vowels.contains(l.toUpperCase()) ? '$l is a vowel!' : '$l is not a vowel')
            : (l.toUpperCase() == l ? '$l is a big letter' : '$l is a small letter')
      ]);
    }
  }

  Widget _box(bool left) {
    final title = _vowelMode ? (left ? 'A E I O U' : 'Others') : (left ? 'BIG  ABC' : 'small  abc');
    final color = left ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);
    final items = left ? _left : _right;
    return Expanded(
      child: DragTarget<String>(
        onAcceptWithDetails: (d) => _drop(d.data, left),
        builder: (_, cand, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cand.isNotEmpty ? color.withValues(alpha: 0.25) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: color, width: 6),
          ),
          child: Column(children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 4, children: [for (final l in items) LetterBall(letter: l, size: 52, color: color)]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'sort',
      color: const Color(0xFFD1C4E9),
      title: _vowelMode ? 'Vowels' : 'Big or small?',
      onSpeak: _ask,
      child: Column(children: [
        Expanded(flex: 5, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_box(true), _box(false)])),
        Expanded(
          flex: 4,
          child: Center(
            child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
              for (final l in _cards)
                Draggable<String>(
                  data: l,
                  feedback: Material(color: Colors.transparent, child: LetterBall(letter: l, size: 96)),
                  childWhenDragging: Opacity(opacity: 0.25, child: LetterBall(letter: l, size: 86)),
                  onDragStarted: () => Audio.I.fx('tick'),
                  child: LetterBall(letter: l, size: 86),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ Frog Jump ═════════════════════════════

class FrogScreen extends StatefulWidget {
  const FrogScreen({super.key});
  @override
  State<FrogScreen> createState() => _FrogScreenState();
}

class _FrogScreenState extends State<FrogScreen> with TickerProviderStateMixin {
  late String _target;
  late List<String> _pads;
  int? _on; // pad index the frog sits on
  int? _wobble;
  int _right = 0;
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _jump.dispose();
    _bob.dispose();
    super.dispose();
  }

  void _newRound() {
    _target = _randLetter();
    final set = <String>{_target};
    final n = AppState.I.age == AgeMode.preschool ? 4 : 3;
    while (set.length < n) {
      set.add(_randLetter(set));
    }
    _pads = set.toList()..shuffle(_rnd);
    _on = null;
    _jump.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() => Audio.I.say(['Help the frog jump to $_target!']);

  void _tap(int i) {
    if (_on != null) return;
    if (_pads[i] == _target) {
      AppState.I.recordLetter(_target, true);
      HapticFeedback.mediumImpact();
      setState(() {
        _on = i;
        _right++;
      });
      Audio.I.fx('boing');
      _jump.forward(from: 0).then((_) {
        if (!mounted) return;
        Audio.I.fx('splash');
        if (_right % 4 == 0) {
          celebrate(context);
        } else {
          Audio.I.say(['Ribbit! $_target!']);
        }
        Future.delayed(const Duration(milliseconds: 2400), () {
          if (mounted) setState(_newRound);
        });
      });
    } else {
      AppState.I.recordLetter(_target, false);
      Audio.I.fx('splash');
      Audio.I.say(['That is ${_pads[i]}. Find $_target']);
      setState(() => _wobble = i);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wobble = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'frog',
      color: const Color(0xFF80DEEA),
      onSpeak: _ask,
      title: 'Jump to $_target',
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final n = _pads.length;
        Offset padPos(int i) => Offset(w * (i + 0.5) / n, h * (0.32 + 0.12 * ((i % 2) == 0 ? 0 : 1)));
        final start = Offset(w / 2, h * 0.84);
        return Stack(children: [
          // river
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.12,
            height: h * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // bank
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: h * 0.3,
            child: Container(color: const Color(0xFF9CCC65)),
          ),
          for (var i = 0; i < n; i++)
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) {
                final p = padPos(i);
                final wob = _wobble == i ? sin(_bob.value * pi * 16) * 8 : 0.0;
                final bob = AppState.I.calm ? 0.0 : sin((_bob.value + i * 0.3) * 2 * pi) * 4;
                return Positioned(left: p.dx - 60 + wob, top: p.dy - 45 + bob, child: child!);
              },
              child: GestureDetector(
                onTap: () => _tap(i),
                child: SizedBox(
                  width: 120,
                  height: 90,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 120,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: const Color(0xFF2E7D32), width: 4),
                      ),
                    ),
                    Text(_pads[i], style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _jump,
            builder: (_, __) {
              final t = _jump.value;
              final to = _on == null ? start : padPos(_on!);
              final pos = Offset.lerp(start, to, t)! - Offset(0, sin(t * pi) * h * 0.18);
              return Positioned(
                left: pos.dx - 45,
                top: pos.dy - 70,
                child: IgnorePointer(child: Text('🐸', style: TextStyle(fontSize: 80 - sin(t * pi) * -10))),
              );
            },
          ),
        ]);
      }),
    );
  }
}
