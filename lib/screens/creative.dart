import 'dart:convert';
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
import 'letter_games.dart';

// ═════════════════════════════ Drawing board (shared) ═════════════════════════════

class InkStroke {
  final Color color;
  final double width; // fraction of canvas size
  final List<Offset> points; // normalised
  InkStroke(this.color, this.width, this.points);

  Map<String, dynamic> toJson() => {
        'c': color.toARGB32(),
        'w': width,
        'p': [for (final p in points) ...[double.parse(p.dx.toStringAsFixed(3)), double.parse(p.dy.toStringAsFixed(3))]],
      };

  static InkStroke fromJson(Map<String, dynamic> j) {
    final raw = (j['p'] as List).cast<num>();
    return InkStroke(Color(j['c'] as int), (j['w'] as num).toDouble(),
        [for (var i = 0; i + 1 < raw.length; i += 2) Offset(raw[i].toDouble(), raw[i + 1].toDouble())]);
  }
}

String encodeDrawing(List<InkStroke> s) => jsonEncode([for (final x in s) x.toJson()]);
List<InkStroke> decodeDrawing(String s) {
  try {
    return [for (final j in jsonDecode(s) as List) InkStroke.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

const _palette = [
  Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047),
  Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFFEC407A), Color(0xFF6D4C41), Color(0xFF212121),
];
const _sizes = [0.012, 0.025, 0.045];

class DrawingBoard extends StatefulWidget {
  final Widget? background;
  final List<InkStroke>? initial;
  const DrawingBoard({super.key, this.background, this.initial});
  @override
  State<DrawingBoard> createState() => DrawingBoardState();
}

class DrawingBoardState extends State<DrawingBoard> {
  late final List<InkStroke> strokes = [...?widget.initial];
  int _color = 4;
  int _size = 1;
  Offset? _lastNoteAt;

  bool get isEmpty => strokes.isEmpty;

  void clear() => setState(strokes.clear);

  void undo() {
    if (strokes.isEmpty) return;
    setState(strokes.removeLast);
    Audio.I.fx('tick');
  }

  void _start(Offset p, double s) {
    setState(() => strokes.add(InkStroke(_palette[_color], _sizes[_size], [Offset(p.dx / s, p.dy / s)])));
  }

  void _add(Offset p, double s) {
    if (strokes.isEmpty) return;
    setState(() => strokes.last.points.add(Offset(p.dx / s, p.dy / s)));
    if (_lastNoteAt == null || (_lastNoteAt! - p).distance > 70) {
      _lastNoteAt = p;
      Audio.I.note((7 - (p.dy / s * 8)).round().clamp(0, 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, box) {
          final s = min(box.maxWidth, box.maxHeight);
          return Center(
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(children: [
                  if (widget.background != null) Positioned.fill(child: IgnorePointer(child: widget.background!)),
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (d) => _start(d.localPosition, s),
                      onPanUpdate: (d) => _add(d.localPosition, s),
                      child: CustomPaint(painter: InkPainter(strokes)),
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 54,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
          for (var i = 0; i < _palette.length; i++)
            GestureDetector(
              onTap: () {
                setState(() => _color = i);
                Audio.I.fx('tick');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _color == i ? 52 : 42,
                height: _color == i ? 52 : 42,
                decoration: BoxDecoration(
                  color: _palette[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: _color == i ? Colors.black54 : Colors.white, width: 4),
                ),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (var i = 0; i < _sizes.length; i++)
            GestureDetector(
              onTap: () => setState(() => _size = i),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _size == i ? Colors.orange : Colors.white, width: 4),
                ),
                alignment: Alignment.center,
                child: CircleAvatar(radius: 4.0 + i * 7, backgroundColor: _palette[_color]),
              ),
            ),
          RoundBtn(icon: Icons.undo_rounded, semantic: 'Undo', onTap: undo, size: 56),
          RoundBtn(
              icon: Icons.delete_sweep_rounded,
              semantic: 'Clear',
              size: 56,
              color: const Color(0xFFFFCDD2),
              onTap: () {
                Audio.I.fx('whoosh');
                clear();
              }),
        ]),
      ),
    ]);
  }
}

class InkPainter extends CustomPainter {
  final List<InkStroke> strokes;
  InkPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    for (final st in strokes) {
      final p = Paint()
        ..color = st.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = st.width * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (st.points.length == 1) {
        canvas.drawCircle(st.points.first * s, st.width * s / 2, p..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(st.points.first.dx * s, st.points.first.dy * s);
      for (final q in st.points.skip(1)) {
        path.lineTo(q.dx * s, q.dy * s);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═════════════════════════════ Draw and Discover ═════════════════════════════

/// Colour a picture that belongs to a letter, then hear its name.
class DrawDiscoverScreen extends StatefulWidget {
  final LearnItem? item; // from the adventure; random letter if null
  final VoidCallback? onDone;
  const DrawDiscoverScreen({super.key, this.item, this.onDone});
  @override
  State<DrawDiscoverScreen> createState() => _DrawDiscoverScreenState();
}

class _DrawDiscoverScreenState extends State<DrawDiscoverScreen> {
  late LearnItem _item = widget.item ?? abc[Random().nextInt(26)];
  final _board = GlobalKey<DrawingBoardState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Audio.I.say([
          AppState.I.hindi ? 'रंग भरो!' : "Let's colour!",
          _item.en.contains(' for ') ? _item.en.split(' for ').last : _item.en,
        ]));
  }

  void _done() {
    final word = _item.en.contains(' for ') ? _item.en.split(' for ').last : _item.en;
    Audio.I.say([word, AppState.I.hindi ? 'बहुत सुंदर!' : 'What a beautiful picture!']);
    if (_board.currentState?.isEmpty == false) {
      AppState.I.update(() {
        AppState.I.drawings.insert(0, encodeDrawing(_board.currentState!.strokes));
        if (AppState.I.drawings.length > 12) AppState.I.drawings.removeLast();
      });
    }
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      celebrate(context);
      setState(() => _item = abc[Random().nextInt(26)]);
      _board.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      Expanded(
        child: DrawingBoard(
          key: _board,
          background: Stack(children: [
            Center(
              child: Opacity(
                opacity: 0.22,
                child: FittedBox(child: Text(_item.emoji, style: const TextStyle(fontSize: 300))),
              ),
            ),
            Positioned(
              left: 14,
              top: 8,
              child: Text(_item.label ?? '',
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: letterColor(_item.label ?? 'A'))),
            ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), backgroundColor: const Color(0xFF43A047)),
          onPressed: _done,
          icon: const Icon(Icons.check_rounded, size: 32),
          label: Text(AppState.I.hindi ? 'हो गया' : 'Done', style: const TextStyle(fontSize: 24)),
        ),
      ),
    ]);
    if (widget.onDone != null) return body; // embedded in the adventure
    return GameScaffold(id: 'drawdiscover', color: const Color(0xFFFFE0B2), title: 'Draw & Discover', child: body);
  }
}

// ═════════════════════════════ Free Drawing Studio ═════════════════════════════

class DrawingStudioScreen extends StatefulWidget {
  const DrawingStudioScreen({super.key});
  @override
  State<DrawingStudioScreen> createState() => _DrawingStudioScreenState();
}

class _DrawingStudioScreenState extends State<DrawingStudioScreen> {
  var _board = GlobalKey<DrawingBoardState>();
  List<InkStroke>? _initial;

  void _save() {
    final st = _board.currentState;
    if (st == null || st.isEmpty) return;
    AppState.I.update(() {
      AppState.I.drawings.insert(0, encodeDrawing(st.strokes));
      if (AppState.I.drawings.length > 12) AppState.I.drawings.removeLast();
    });
    celebrate(context, sticker: false, text: AppState.I.hindi ? 'सेव हो गया!' : 'Saved!');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) => GameScaffold(
        id: 'studio',
        color: const Color(0xFFB2EBF2),
        title: AppState.I.hindi ? 'चित्र स्टूडियो' : 'Drawing Studio',
        trailing: RoundBtn(icon: Icons.save_rounded, semantic: 'Save drawing', onTap: _save, color: const Color(0xFFC8E6C9)),
        child: Column(children: [
          Expanded(child: DrawingBoard(key: _board, initial: _initial)),
          if (AppState.I.drawings.isNotEmpty)
            SizedBox(
              height: 86,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(10, 0, 10, 8), children: [
                for (final d in AppState.I.drawings)
                  GestureDetector(
                    onTap: () => setState(() {
                      _initial = decodeDrawing(d);
                      _board = GlobalKey<DrawingBoardState>();
                    }),
                    child: Container(
                      width: 78,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(painter: InkPainter(decodeDrawing(d))),
                      ),
                    ),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════ Letter Rescue ═════════════════════════════

/// Golu lost a letter. Drag the right one to him. Distractors increase slowly.
class LetterRescueScreen extends StatefulWidget {
  const LetterRescueScreen({super.key});
  @override
  State<LetterRescueScreen> createState() => _LetterRescueScreenState();
}

class _LetterRescueScreenState extends State<LetterRescueScreen> {
  final _rnd = Random();
  late String _target;
  late List<String> _letters;
  late List<Offset> _spots;
  int _round = 0;
  Mood _mood = Mood.idle;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    const all = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    _target = all[_rnd.nextInt(26)];
    final distractors = min(5, 1 + _round ~/ 2);
    final set = <String>{_target};
    while (set.length < distractors + 1) {
      set.add(all[_rnd.nextInt(26)]);
    }
    _letters = set.toList()..shuffle(_rnd);
    _spots = [for (var i = 0; i < _letters.length; i++) Offset(0.12 + (i % 3) * 0.36 + _rnd.nextDouble() * 0.06, 0.08 + (i ~/ 3) * 0.42)];
    _saved = false;
    _mood = Mood.sleepy;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() => Audio.I.say([
        AppState.I.hindi ? 'गोलू का अक्षर $_target खो गया! उसे लाओ' : 'Oh no! Golu lost the letter $_target. Can you bring it to him?'
      ]);

  void _drop(String l) {
    if (l == _target) {
      AppState.I.recordLetter(l, true);
      HapticFeedback.mediumImpact();
      Audio.I.fx('chime');
      setState(() {
        _saved = true;
        _mood = Mood.happy;
        _round++;
      });
      if (_round % 3 == 0) {
        celebrate(context, text: AppState.I.hindi ? 'तुमने बचा लिया!' : 'You rescued it!');
      } else {
        Audio.I.say(['Thank you! $_target, ${soundOf(_target)}!']);
      }
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(_newRound);
      });
    } else {
      AppState.I.recordLetter(_target, false);
      Audio.I.fx('boing');
      Audio.I.say(['That is $l. Golu needs $_target']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'rescue',
      color: const Color(0xFFA5D6A7),
      hills: true,
      onSpeak: _ask,
      title: AppState.I.hindi ? 'अक्षर बचाओ' : 'Letter Rescue',
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return Stack(children: [
          // forest
          for (var i = 0; i < 5; i++)
            Positioned(
                left: w * (i * 0.22 - 0.03),
                top: h * (0.02 + (i % 2) * 0.05),
                child: const Opacity(opacity: 0.5, child: Text('🌳', style: TextStyle(fontSize: 70)))),
          for (var i = 0; i < _letters.length; i++)
            if (!(_saved && _letters[i] == _target))
              Positioned(
                left: _spots[i].dx * w - 10,
                top: _spots[i].dy * h * 0.55 + 20,
                child: Draggable<String>(
                  data: _letters[i],
                  feedback: Material(color: Colors.transparent, child: LetterBall(letter: _letters[i], size: 96)),
                  childWhenDragging: Opacity(opacity: 0.25, child: LetterBall(letter: _letters[i], size: 84)),
                  onDragStarted: () => Audio.I.fx('tick'),
                  child: LetterBall(letter: _letters[i], size: 84),
                ),
              ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: DragTarget<String>(
              onAcceptWithDetails: (d) => _drop(d.data),
              builder: (_, cand, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_saved ? '❤️ ' : '🔎 ', style: const TextStyle(fontSize: 26)),
                    LetterBall(letter: _target, size: 50),
                  ]),
                ),
                AnimatedScale(
                  scale: cand.isNotEmpty ? 1.15 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Mascot(kind: MascotKind.golu, mood: _mood, size: 150),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}

// ═════════════════════════════ Build the Letter ═════════════════════════════

/// Each stroke of a letter is a puzzle piece. Drag pieces onto the outline; they snap in place.
class BuildLetterScreen extends StatefulWidget {
  const BuildLetterScreen({super.key});
  @override
  State<BuildLetterScreen> createState() => _BuildLetterScreenState();
}

class _BuildLetterScreenState extends State<BuildLetterScreen> {
  static const _choices = ['A', 'B', 'D', 'E', 'F', 'H', 'I', 'K', 'M', 'N', 'P', 'R', 'T', 'X', 'Y', '4', 't', 'k'];
  final _rnd = Random();
  final _boardKey = GlobalKey();
  late String _glyph;
  late List<List<Offset>> _strokes;
  final Set<int> _placed = {};
  late List<int> _tray;

  @override
  void initState() {
    super.initState();
    _newLetter();
  }

  void _newLetter() {
    _glyph = _choices[_rnd.nextInt(_choices.length)];
    _strokes = strokes[_glyph]!;
    _placed.clear();
    _tray = List.generate(_strokes.length, (i) => i)..shuffle(_rnd);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Audio.I.say([AppState.I.hindi ? 'अक्षर $_glyph बनाओ' : "Let's build the letter $_glyph"]));
  }

  Rect _bounds(List<Offset> st) {
    var l = 1.0, t = 1.0, r = 0.0, b = 0.0;
    for (final p in st) {
      l = min(l, p.dx);
      t = min(t, p.dy);
      r = max(r, p.dx);
      b = max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  Widget _piece(int i, double s, {Color? color}) {
    final b = _bounds(_strokes[i]);
    final pad = s * 0.06;
    return SizedBox(
      width: b.width * s + pad * 2,
      height: b.height * s + pad * 2,
      child: CustomPaint(painter: _PiecePainter(_strokes[i], b, s, pad, color ?? letterColor(_glyph))),
    );
  }

  void _drop(int i, Offset globalTopLeft, double s) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final b = _bounds(_strokes[i]);
    final pad = s * 0.06;
    final center = box.globalToLocal(globalTopLeft + Offset(b.width * s / 2 + pad, b.height * s / 2 + pad));
    final want = b.center * s;
    if ((center - want).distance < s * 0.2) {
      HapticFeedback.mediumImpact();
      Audio.I.fx('pop');
      setState(() {
        _placed.add(i);
        _tray.remove(i);
      });
      if (_placed.length == _strokes.length) {
        AppState.I.recordLetter(_glyph, true);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          celebrate(context);
          Audio.I.say([_glyph]);
          Future.delayed(const Duration(milliseconds: 3500), () {
            if (mounted) setState(_newLetter);
          });
        });
      }
    } else {
      Audio.I.fx('boing');
      Audio.I.say([AppState.I.hindi ? 'सही जगह ढूँढो' : 'Almost! Find where it fits']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'buildletter',
      color: const Color(0xFFFFCCBC),
      title: AppState.I.hindi ? 'अक्षर बनाओ: $_glyph' : 'Build the letter $_glyph',
      child: LayoutBuilder(builder: (context, box) {
        final s = min(box.maxWidth - 32, box.maxHeight * 0.58);
        return Column(children: [
          const SizedBox(height: 6),
          DragTarget<int>(
            onAcceptWithDetails: (d) => _drop(d.data, d.offset, s),
            builder: (_, __, ___) => Container(
              key: _boardKey,
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: CustomPaint(painter: _OutlinePainter(_strokes, _placed, letterColor(_glyph))),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
                  for (final i in _tray)
                    Draggable<int>(
                      data: i,
                      feedback: _piece(i, s),
                      childWhenDragging: Opacity(opacity: 0.25, child: _piece(i, s * 0.55)),
                      onDragStarted: () => Audio.I.fx('tick'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: _piece(i, s * 0.55),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final List<Offset> st;
  final Rect b;
  final double s, pad;
  final Color color;
  _PiecePainter(this.st, this.b, this.s, this.pad, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    for (var i = 0; i < st.length; i++) {
      final q = Offset((st[i].dx - b.left) * s + pad, (st[i].dy - b.top) * s + pad);
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OutlinePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Set<int> placed;
  final Color color;
  _OutlinePainter(this.strokes, this.placed, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    for (var i = 0; i < strokes.length; i++) {
      final p = Path()..moveTo(strokes[i].first.dx * s, strokes[i].first.dy * s);
      for (final q in strokes[i].skip(1)) {
        p.lineTo(q.dx * s, q.dy * s);
      }
      canvas.drawPath(
          p,
          Paint()
            ..color = placed.contains(i) ? color : const Color(0xFFE0E0E0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.08
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
      if (!placed.contains(i)) {
        for (final m in p.computeMetrics()) {
          for (double d = 0; d < m.length; d += s * 0.04) {
            canvas.drawPath(
                m.extractPath(d, d + s * 0.02),
                Paint()
                  ..color = Colors.black26
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = s * 0.01);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═════════════════════════════ Magic Letter Garden ═════════════════════════════

const gardenPlants = {
  'A': '🍎', 'B': '🌸', 'C': '🌵', 'D': '🌼', 'E': '🍆', 'F': '🌻', 'G': '🍇', 'H': '🌺', 'I': '🪻', 'J': '🌷',
  'K': '🥝', 'L': '🍋', 'M': '🥭', 'N': '🥜', 'O': '🍊', 'P': '🍑', 'Q': '🌾', 'R': '🌹', 'S': '🍓', 'T': '🍅',
  'U': '🍄', 'V': '🥬', 'W': '🍉', 'X': '🎄', 'Y': '🌽', 'Z': '🥒',
};

/// Trace a letter to grow its plant. The garden is saved on the phone.
class MagicGardenScreen extends StatefulWidget {
  const MagicGardenScreen({super.key});
  @override
  State<MagicGardenScreen> createState() => _MagicGardenScreenState();
}

class _MagicGardenScreenState extends State<MagicGardenScreen> {
  String? _tracing;
  String? _grown;

  void _open(String l) {
    Audio.I.fx('pop');
    setState(() {
      _tracing = l;
      _grown = null;
    });
  }

  void _done(String l) {
    AppState.I.update(() => AppState.I.garden.add(l));
    setState(() => _grown = l);
    Audio.I.fx('yay');
    Audio.I.say([AppState.I.hindi ? 'पौधा उग गया!' : 'Your plant is growing!']);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      celebrate(context);
      setState(() => _tracing = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    final l = _tracing;
    return GameScaffold(
      id: 'garden',
      color: const Color(0xFFC5E1A5),
      hills: true,
      title: hi ? 'जादुई बगीचा' : 'Magic Letter Garden',
      child: l == null
          ? Column(children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(hi ? 'अक्षर चुनो और लिखो — पौधा उगेगा!' : 'Pick a letter and trace it to grow a plant!',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final c in gardenPlants.keys)
                      GestureDetector(
                        onTap: () => _open(c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D6E63),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF5D4037), width: 3),
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            if (AppState.I.garden.contains(c))
                              FittedBox(child: Text(gardenPlants[c]!, style: const TextStyle(fontSize: 40)))
                            else
                              const Text('🌱', style: TextStyle(fontSize: 22)),
                            Positioned(
                              left: 4,
                              top: 0,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ])
          : Column(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _grown == null
                      ? TracingCanvas(
                          glyphId: l,
                          strokes: strokes[l]!,
                          color: letterColor(l),
                          startWithDemo: !AppState.I.traced.contains(l),
                          onComplete: () => _done(l),
                        )
                      : Stack(children: [
                          LetterMagicView(
                              glyph: l,
                              strokes: strokes[l]!,
                              color: letterColor(l)),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.elasticOut,
                              builder: (_, v, __) => Transform.scale(
                                  scale: v,
                                  alignment: Alignment.bottomCenter,
                                  child: Text(gardenPlants[l]!, style: const TextStyle(fontSize: 110))),
                            ),
                          ),
                        ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RoundBtn(icon: Icons.grid_view_rounded, semantic: 'Back to garden', onTap: () => setState(() => _tracing = null)),
              ),
            ]),
    );
  }
}
