import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../core/strokes.dart';
import '../widgets/common.dart';
import '../widgets/letter_magic.dart';
import '../widgets/mascot.dart';
import '../widgets/tracing_canvas.dart';
import 'creative.dart';
import 'explore.dart';
import 'games_a.dart';
import 'letter_games.dart';
import 'tracing.dart';

// ═════════════════════════════ Adventure map ═════════════════════════════

class _Place {
  final String id, en, hi, emoji;
  final Color color;
  final int needLetters; // letters finished in the adventure to unlock (0 = always open)
  final List<_Act> acts;
  const _Place(this.id, this.en, this.hi, this.emoji, this.color, this.needLetters, this.acts);
}

class _Act {
  final String en, hi, emoji;
  final Widget Function() build;
  const _Act(this.en, this.hi, this.emoji, this.build);
}

Category _cat(String id) => learnCategories.firstWhere((c) => c.id == id);

final _places = [
  _Place('garden', 'Alphabet Garden', 'अक्षर बगीचा', '🌷', const Color(0xFF81C784), 0, [
    _Act('Magic Letter Adventure', 'जादुई अक्षर यात्रा', '✨', () => const AdventurePathScreen()),
    _Act('Magic Garden', 'जादुई बगीचा', '🌱', () => const MagicGardenScreen()),
    _Act('Build the Letter', 'अक्षर बनाओ', '🧩', () => const BuildLetterScreen()),
  ]),
  _Place('forest', 'Animal Forest', 'जानवर जंगल', '🌳', const Color(0xFF66BB6A), 2, [
    _Act('Letter Rescue', 'अक्षर बचाओ', '🐘', () => const LetterRescueScreen()),
    _Act('Animals', 'जानवर', '🐄', () => ExploreScreen(category: _cat('animals'))),
    _Act('Letter Catcher', 'अक्षर पकड़ो', '🧺', () => const CollectLettersScreen()),
    _Act('Frog Jump', 'मेंढक कूद', '🐸', () => const FrogScreen()),
  ]),
  _Place('art', 'Colorful Art Island', 'रंगीन टापू', '🎨', const Color(0xFFFFB74D), 4, [
    _Act('Draw & Discover', 'बनाओ और खोजो', '🖍️', () => const DrawDiscoverScreen()),
    _Act('Drawing Studio', 'चित्र स्टूडियो', '🖼️', () => const DrawingStudioScreen()),
    _Act('Color by Letters', 'अक्षर से रंग', '🖌️', () => const ColorByLettersScreen()),
  ]),
  _Place('hindi', 'Hindi Story Village', 'हिंदी गाँव', '🛖', const Color(0xFFBA68C8), 0, [
    _Act('Swar अ आ इ', 'स्वर', 'अ', () => ExploreScreen(category: _cat('swar'))),
    _Act('Vyanjan क ख ग', 'व्यंजन', 'क', () => ExploreScreen(category: _cat('vyanjan'))),
    _Act('Hindi tracing', 'हिंदी लिखो', '✍️', () => const TracingMenuScreen()),
  ]),
  _Place('sky', 'Discovery Sky', 'खोज आसमान', '☁️', const Color(0xFF64B5F6), 6, [
    _Act('Listen & Find', 'सुनो और ढूँढो', '👂', () => const SoundMatchScreen()),
    _Act('Bubble A–Z', 'बुलबुले', '🫧', () => const BubbleAZScreen()),
    _Act('Trampoline', 'उछल कूद', '🤸', () => const TrampolineScreen()),
    _Act('ABC Bingo', 'बिंगो', '🎯', () => const BingoScreen()),
  ]),
];

bool _open(_Place p) => AppState.I.teacher || AppState.I.adventureLevel >= p.needLetters;

class AdventureMapScreen extends StatelessWidget {
  const AdventureMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final hi = AppState.I.hindi;
        final level = AppState.I.adventureLevel;
        final practice = AppState.I.practiceSuggestions();
        return GameScaffold(
          id: 'advmap',
          title: hi ? 'जादुई यात्रा' : 'Magic Adventure',
          hills: true,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: level / 26, minHeight: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$level/26', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ]),
            ),
            if (practice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    final l = practice.first;
                    final idx = abc.indexWhere((a) => a.label == l.toUpperCase());
                    if (idx >= 0) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MagicLetterAdventureScreen(index: idx)));
                    }
                  },
                  child: TalkingMascot(
                    kind: MascotKind.chiku,
                    mood: Mood.wave,
                    size: 60,
                    text: hi ? '${practice.first} फिर से खेलें? 👉' : "Let's play ${practice.first} again! 👉",
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth;
                return SingleChildScrollView(
                  child: SizedBox(
                    height: _places.length * 170.0 + 40,
                    child: Stack(children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter([
                            for (var i = 0; i < _places.length; i++) Offset(w * (i.isEven ? 0.3 : 0.7), 90 + i * 170.0)
                          ]),
                        ),
                      ),
                      for (var i = 0; i < _places.length; i++)
                        Positioned(
                          left: w * (i.isEven ? 0.3 : 0.7) - 80,
                          top: 20 + i * 170.0,
                          child: _Island(place: _places[i], hindi: hi),
                        ),
                    ]),
                  ),
                );
              }),
            ),
          ]),
        );
      },
    );
  }
}

class _Island extends StatelessWidget {
  final _Place place;
  final bool hindi;
  const _Island({required this.place, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final open = _open(place);
    return GestureDetector(
      onTap: () {
        if (!open) {
          Audio.I.fx('boing');
          final need = place.needLetters - AppState.I.adventureLevel;
          Audio.I.say([hindi ? '$need अक्षर और सीखो' : 'Learn $need more letters to open this place!']);
          return;
        }
        Audio.I.fx('whoosh');
        Audio.I.say([hindi ? place.hi : place.en]);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PlaceScreen(place: place)));
      },
      child: SizedBox(
        width: 160,
        child: Column(children: [
          Container(
            width: 130,
            height: 110,
            decoration: BoxDecoration(
              color: open ? place.color : Colors.grey.shade400,
              borderRadius: const BorderRadius.all(Radius.elliptical(130, 110)),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: [BoxShadow(color: (open ? place.color : Colors.grey).withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: Text(open ? place.emoji : '🔒',
                style: TextStyle(fontSize: 54, color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(hindi ? place.hi : place.en,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> pts;
  _TrailPainter(this.pts);
  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 26) {
        canvas.drawPath(
            m.extractPath(d, d + 12),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter o) => false;
}

class _PlaceScreen extends StatelessWidget {
  final _Place place;
  const _PlaceScreen({required this.place});

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'place_${place.id}',
      color: place.color,
      hills: true,
      title: hi ? place.hi : place.en,
      child: GridView.count(
        padding: const EdgeInsets.all(18),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final a in place.acts)
            GestureDetector(
              onTap: () {
                Audio.I.fx('whoosh');
                Audio.I.say([hi ? a.hi : a.en]);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => a.build()));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: place.color, width: 5),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(
                      child: FittedBox(
                          child: Text(a.emoji,
                              style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: darker(place.color))))),
                  Text(hi ? a.hi : a.en,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ A–Z path ═════════════════════════════

class AdventurePathScreen extends StatelessWidget {
  const AdventurePathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final level = AppState.I.adventureLevel;
        final practice = AppState.I.practiceSuggestions().toSet();
        return GameScaffold(
          id: 'advpath',
          color: const Color(0xFFA5D6A7),
          title: AppState.I.hindi ? 'जादुई अक्षर यात्रा' : 'Magic Letter Adventure',
          child: GridView.count(
            padding: const EdgeInsets.all(14),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (var i = 0; i < 26; i++)
                Builder(builder: (context) {
                  final l = abc[i].label!;
                  final done = i < level;
                  final open = AppState.I.teacher || i <= level;
                  return GestureDetector(
                    onTap: () {
                      if (!open) {
                        Audio.I.fx('boing');
                        Audio.I.say([AppState.I.hindi ? 'पहले ${abc[level].label} सीखो' : 'First learn ${abc[level].label}']);
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MagicLetterAdventureScreen(index: i)));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: open ? letterColor(l) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: Border.all(color: i == level ? Colors.amber : Colors.white, width: i == level ? 6 : 4),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        Text(open ? l : '🔒',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                        if (done) const Positioned(right: 2, top: 0, child: Text('⭐', style: TextStyle(fontSize: 18))),
                        if (practice.contains(l))
                          const Positioned(left: 2, top: 0, child: Text('🔁', style: TextStyle(fontSize: 16))),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════ Magic Letter Adventure (one letter) ═════════════════════════════

enum AdvStep { meet, hear, trace, draw, discover, play, reward }

/// The 9 parts of the journey, grouped into 7 screens:
/// 1 meet → 2 hear name+sound → 3 watch demo + 4 trace (TracingCanvas) → 5 creative drawing (optional)
/// → 6 discover object (letter comes alive) → 7 short recognition game → 8 reward → 9 unlock next.
class MagicLetterAdventureScreen extends StatefulWidget {
  final int index; // 0..25
  const MagicLetterAdventureScreen({super.key, required this.index});
  @override
  State<MagicLetterAdventureScreen> createState() => _MagicLetterAdventureScreenState();
}

class _MagicLetterAdventureScreenState extends State<MagicLetterAdventureScreen> with TickerProviderStateMixin {
  AdvStep _step = AdvStep.meet;
  Mood _mood = Mood.wave;
  final _canvas = GlobalKey<TracingCanvasState>();
  late final AnimationController _enter =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  // recognition game
  late List<String> _choices;
  String? _wrong;
  int _found = 0;

  LearnItem get item => abc[widget.index];
  String get letter => item.label!;
  String get word => item.en.split(' for ').last;
  bool get hi => AppState.I.hindi;

  @override
  void initState() {
    super.initState();
    AppState.I.markIntroduced(letter);
    _setupChoices();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakStep());
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _setupChoices() {
    final rnd = Random();
    final set = <String>{letter};
    final n = AppState.I.age == AgeMode.baby ? 2 : (AppState.I.age == AgeMode.toddler ? 3 : 4);
    while (set.length < n) {
      set.add(String.fromCharCode(65 + rnd.nextInt(26)));
    }
    _choices = set.toList()..shuffle(rnd);
  }

  void _speakStep() {
    switch (_step) {
      case AdvStep.meet:
        Audio.I.say([hi ? 'नमस्ते! मैं हूँ अक्षर $letter' : "Hello! I'm the letter $letter!"]);
      case AdvStep.hear:
        Audio.I.say(['$letter', ...letterSoundPhrase(item)]);
      case AdvStep.trace:
        break; // the canvas speaks its own instructions
      case AdvStep.draw:
        Audio.I.say([hi ? '$word का चित्र रंगो' : "Let's colour a $word!"]);
      case AdvStep.discover:
        Audio.I.say([hi ? 'देखो! जादू!' : 'Look! Magic!', '$letter for $word']);
      case AdvStep.play:
        Audio.I.say([hi ? '$letter ढूँढो' : 'Find the letter $letter!']);
      case AdvStep.reward:
        Audio.I.say([hi ? 'तुमने $letter सीख लिया!' : 'You learned $letter!']);
    }
  }

  void _go(AdvStep s) {
    Audio.I.fx('whoosh');
    setState(() {
      _step = s;
      _mood = s == AdvStep.reward ? Mood.happy : Mood.idle;
    });
    _enter.forward(from: 0);
    _speakStep();
    if (s == AdvStep.reward) _finish();
  }

  void _next() {
    final i = AdvStep.values.indexOf(_step);
    if (i + 1 < AdvStep.values.length) _go(AdvStep.values[i + 1]);
  }

  void _finish() {
    AppState.I.finishAdventureLetter(widget.index);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) celebrate(context);
    });
  }

  void _pick(String l) {
    if (l == letter) {
      AppState.I.recordLetter(l, true);
      HapticFeedback.mediumImpact();
      Audio.I.fx('chime');
      setState(() {
        _found++;
        _wrong = null;
        _mood = Mood.happy;
      });
      if (_found >= 2) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _go(AdvStep.reward);
        });
      } else {
        Audio.I.say([hi ? 'शाबाश! एक बार और' : 'Yes! One more time!']);
        setState(_setupChoices);
      }
    } else {
      AppState.I.recordLetter(letter, false);
      Audio.I.fx('boing');
      setState(() {
        _wrong = l;
        _mood = Mood.idle;
      });
      Audio.I.say([hi ? 'यह $l है। $letter ढूँढो' : 'That is $l. Find $letter']);
    }
  }

  Widget _stepDots() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final s in AdvStep.values)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(3),
          width: s == _step ? 26 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: s.index <= _step.index ? letterColor(letter) : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
    ]);
  }

  Widget _bigButton(String text, IconData icon, VoidCallback onTap, {Color color = const Color(0xFF43A047)}) =>
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 30),
        label: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      );

  Widget _body() {
    final c = letterColor(letter);
    switch (_step) {
      case AdvStep.meet:
        return Column(children: [
          Expanded(
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _enter, curve: Curves.elasticOut),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(letter, style: TextStyle(fontSize: 190, fontWeight: FontWeight.w900, color: c, height: 1)),
                  Text(letter.toLowerCase(),
                      style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: darker(c), height: 1)),
                ]),
              ),
            ),
          ),
          TalkingMascot(kind: MascotKind.golu, mood: _mood, size: 90, text: hi ? 'मिलो $letter से!' : 'Meet $letter!'),
          const SizedBox(height: 12),
          _bigButton(hi ? 'आगे' : 'Next', Icons.arrow_forward_rounded, _next),
        ]);
      case AdvStep.hear:
        return Column(children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _speakStep,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(letter, style: TextStyle(fontSize: 150, fontWeight: FontWeight.w900, color: c, height: 1)),
                  const SizedBox(height: 10),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _soundChip(hi ? 'नाम' : 'Name', letter, () => Audio.I.say([letter])),
                    const SizedBox(width: 12),
                    _soundChip(hi ? 'ध्वनि' : 'Sound', '/${soundOf(letter)}/',
                        () => Audio.I.say([soundOf(letter), soundOf(letter)])),
                  ]),
                ]),
              ),
            ),
          ),
          _bigButton(hi ? 'लिखना सीखो' : "Let's write it", Icons.edit_rounded, _next),
        ]);
      case AdvStep.trace:
        return Column(children: [
          Expanded(
            child: TracingCanvas(
              key: _canvas,
              glyphId: letter,
              strokes: strokes[letter]!,
              color: c,
              onStrokeDone: (_) => setState(() => _mood = Mood.happy),
              onComplete: () {
                setState(() => _mood = Mood.happy);
                Audio.I.say([(hi ? praiseHi : praiseEn)[Random().nextInt(3)]]);
                Future.delayed(const Duration(milliseconds: 1300), () {
                  if (mounted) _next();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            RoundBtn(
                icon: Icons.play_circle_fill_rounded,
                semantic: 'Show me again',
                color: const Color(0xFFFFF59D),
                onTap: () => _canvas.currentState?.replayDemo()),
            RoundBtn(icon: Icons.refresh_rounded, semantic: 'Start again', onTap: () => _canvas.currentState?.reset()),
            Mascot(kind: MascotKind.chiku, mood: _mood, size: 64),
          ]),
        ]);
      case AdvStep.draw:
        return Column(children: [
          Expanded(child: DrawDiscoverScreen(item: item, onDone: _next)),
          TextButton(onPressed: _next, child: Text(hi ? 'छोड़ो ⏭' : 'Skip ⏭', style: const TextStyle(fontSize: 18))),
        ]);
      case AdvStep.discover:
        return Column(children: [
          Expanded(child: LetterMagicView(glyph: letter, strokes: strokes[letter]!, color: c, loop: true)),
          Text('$letter  ·  ${item.emoji}  $word', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: darker(c))),
          const SizedBox(height: 12),
          _bigButton(hi ? 'खेलो' : "Let's play", Icons.sports_esports_rounded, _next),
        ]);
      case AdvStep.play:
        return Column(children: [
          TalkingMascot(kind: MascotKind.golu, mood: _mood, size: 80, text: hi ? '$letter ढूँढो!' : 'Find $letter!'),
          Expanded(
            child: Center(
              child: Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
                for (final l in _choices)
                  GestureDetector(
                    onTap: () => _pick(l),
                    child: AnimatedOpacity(
                      opacity: _wrong == l ? 0.45 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: LetterBall(letter: l, size: 120),
                    ),
                  ),
              ]),
            ),
          ),
          Text('⭐' * _found, style: const TextStyle(fontSize: 36)),
        ]);
      case AdvStep.reward:
        final nextIdx = widget.index + 1;
        return Column(children: [
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Mascot(kind: MascotKind.golu, mood: Mood.happy, size: 160),
                Text(hi ? '$letter सीख लिया! 🎉' : 'You learned $letter! 🎉',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (nextIdx < 26)
                  Text(hi ? 'अगला अक्षर खुल गया: ${abc[nextIdx].label}' : 'New letter unlocked: ${abc[nextIdx].label}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black54)),
              ]),
            ),
          ),
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            _bigButton(hi ? 'फिर से' : 'Again', Icons.replay_rounded, () {
              setState(() {
                _found = 0;
                _setupChoices();
              });
              _go(AdvStep.meet);
            }, color: const Color(0xFF42A5F5)),
            if (nextIdx < 26)
              _bigButton('${abc[nextIdx].label} ➜', Icons.arrow_forward_rounded, () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => MagicLetterAdventureScreen(index: nextIdx)));
              }),
          ]),
          const SizedBox(height: 10),
        ]);
    }
  }

  Widget _soundChip(String label, String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: letterColor(letter), width: 4),
          ),
          child: Column(children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w700)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.volume_up_rounded),
              const SizedBox(width: 4),
              Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'adventure',
      color: letterColor(letter),
      onSpeak: _speakStep,
      title: '$letter  ${item.emoji}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(children: [
          _stepDots(),
          const SizedBox(height: 8),
          Expanded(child: _body()),
        ]),
      ),
    );
  }
}
