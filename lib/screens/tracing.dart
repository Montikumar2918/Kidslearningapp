import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

class TraceSet {
  final String en, hi, emoji;
  final List<LearnItem> items;
  const TraceSet(this.en, this.hi, this.emoji, this.items);
}

final traceSets = [
  TraceSet('ABC', 'ABC', 'A', abc),
  TraceSet('abc', 'abc', 'a', abcSmall),
  TraceSet('123', '१२३', '1', numbers),
  TraceSet('अ आ इ', 'स्वर', 'अ', swar),
  TraceSet('क ख ग', 'व्यंजन', 'क', vyanjan),
];

class TracingMenuScreen extends StatelessWidget {
  const TracingMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'trace',
      title: hi ? 'क्या लिखें?' : 'What shall we write?',
      color: const Color(0xFF90CAF9),
      hills: true,
      child: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) => GridView.count(
          padding: const EdgeInsets.all(18),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final s in traceSets)
              GestureDetector(
                onTap: () {
                  Audio.I.fx('whoosh');
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => TraceScreen(set: s)));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF64B5F6), width: 5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s.emoji,
                        style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5))),
                    Text(hi ? s.hi : s.en, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('⭐ ${s.items.where((i) => AppState.I.traced.contains(i.label)).length}/${s.items.length}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Trace a letter with a finger. A glowing dot + hand shows where to go next,
/// the finger leaves a rainbow trail, and when ~80% of the letter is covered
/// the letter "comes alive" with its picture.
class TraceScreen extends StatefulWidget {
  final TraceSet set;
  const TraceScreen({super.key, required this.set});
  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _Mask {
  final String key;
  final int n;
  final List<int> targets; // cell indices (y*n+x) that belong to the letter, in reading order
  _Mask(this.key, this.n, this.targets);
}

class _TraceScreenState extends State<TraceScreen> with TickerProviderStateMixin {
  static const int _n = 26;
  int _i = 0;
  _Mask? _mask;
  bool _building = false;
  final Set<int> _visited = {};
  final List<List<Offset>> _strokes = [];
  bool _done = false;
  double _size = 0;
  int _lastCell = -1;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final AnimationController _alive = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  LearnItem get item => widget.set.items[_i];
  bool get hi => AppState.I.hindi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _intro());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _alive.dispose();
    super.dispose();
  }

  void _intro() => Audio.I.say([hi ? 'चलो लिखें' : "Let's write", item.label!]);

  static double _fontFactor(String l) {
    final dev = l.runes.any((r) => r >= 0x0900 && r <= 0x097F);
    if (l.length > 1 && !dev) return 0.55; // "10"
    if (dev && l.runes.length > 1) return 0.55; // conjuncts
    return dev ? 0.62 : 0.72;
  }

  static TextPainter _letterPainter(String l, double s, Paint fg) => TextPainter(
        text: TextSpan(
          text: l,
          style: TextStyle(fontSize: s * _fontFactor(l), fontWeight: FontWeight.w700, foreground: fg, height: 1.1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: s);

  static Offset _letterOffset(TextPainter tp, double s) => Offset((s - tp.width) / 2, (s - tp.height) / 2);

  Future<void> _buildMask(double s) async {
    final key = '${item.label}@${s.round()}';
    if (_mask?.key == key || _building) return;
    _building = true;
    try {
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final tp = _letterPainter(item.label!, s, Paint()..color = Colors.black);
      tp.paint(canvas, _letterOffset(tp, s));
      final w = s.round();
      final img = await rec.endRecording().toImage(w, w);
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      if (data == null) return;
      final bytes = data.buffer.asUint8List();
      final c = s / _n;
      final targets = <int>[];
      for (var y = 0; y < _n; y++) {
        for (var x = 0; x < _n; x++) {
          var hit = false;
          for (final o in const [Offset(0.5, 0.5), Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.25, 0.75), Offset(0.75, 0.75)]) {
            final px = ((x + o.dx) * c).floor().clamp(0, w - 1);
            final py = ((y + o.dy) * c).floor().clamp(0, w - 1);
            if (_alpha(bytes, w, px, py) > 60) {
              hit = true;
              break;
            }
          }
          if (hit) targets.add(y * _n + x);
        }
      }
      if (mounted) setState(() => _mask = _Mask(key, _n, targets));
    } catch (e) {
      debugPrint('mask failed: $e');
    } finally {
      _building = false;
    }
  }

  static int _alpha(Uint8List b, int w, int x, int y) => b[(y * w + x) * 4 + 3];

  int? get _guide {
    final m = _mask;
    if (m == null || _done) return null;
    final left = m.targets.where((t) => !_visited.contains(t));
    if (left.isEmpty) return null;
    if (_lastCell < 0) return left.first;
    final lx = _lastCell % _n, ly = _lastCell ~/ _n;
    int best = left.first;
    var bd = 1 << 30;
    for (final t in left) {
      final d = (t % _n - lx) * (t % _n - lx) + (t ~/ _n - ly) * (t ~/ _n - ly);
      if (d < bd) {
        bd = d;
        best = t;
      }
    }
    return best;
  }

  void _touch(Offset p) {
    final m = _mask;
    if (m == null || _done || _size == 0) return;
    final c = _size / _n;
    final cx = (p.dx / c).floor(), cy = (p.dy / c).floor();
    var newHits = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= _n || y >= _n) continue;
        final idx = y * _n + x;
        if (m.targets.contains(idx) && _visited.add(idx)) newHits++;
      }
    }
    if (newHits > 0) {
      _lastCell = cy * _n + cx;
      if (_visited.length % 6 == 0) Audio.I.note((_visited.length ~/ 6) % 8);
    }
    if (_visited.length >= m.targets.length * 0.8) _finish();
  }

  void _finish() {
    if (_done) return;
    setState(() => _done = true);
    HapticFeedback.mediumImpact();
    AppState.I.recordTraced(item.label!);
    if (!AppState.I.calm) _alive.forward(from: 0);
    Audio.I.fx('chime');
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      celebrate(context);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) Audio.I.say([item.name(hi)]);
      });
    });
  }

  void _reset() {
    setState(() {
      _visited.clear();
      _strokes.clear();
      _done = false;
      _lastCell = -1;
    });
    _alive.reset();
  }

  void _go(int d) {
    final n = widget.set.items.length;
    _i = (_i + d + n) % n;
    _reset();
    _mask = null;
    Audio.I.fx('whoosh');
    _intro();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'trace',
      color: item.color,
      onSpeak: _intro,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Mascot(kind: MascotKind.golu, mood: _done ? Mood.happy : Mood.idle, size: 60),
      ),
      child: Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final s = min(box.maxWidth, box.maxHeight) - 24;
            if (s <= 0) return const SizedBox();
            _size = s;
            _buildMask(s);
            return Center(
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: GestureDetector(
                    onPanStart: (d) {
                      if (_done) return;
                      setState(() => _strokes.add([d.localPosition]));
                      _touch(d.localPosition);
                    },
                    onPanUpdate: (d) {
                      if (_done || _strokes.isEmpty) return;
                      setState(() => _strokes.last.add(d.localPosition));
                      _touch(d.localPosition);
                    },
                    child: Stack(children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulse, _alive]),
                        builder: (_, __) => CustomPaint(
                          size: Size.square(s),
                          painter: _TracePainter(
                            letter: item.label!,
                            color: darker(item.color),
                            strokes: _strokes,
                            guide: _guide,
                            n: _n,
                            pulse: _pulse.value,
                            done: _done,
                            alive: _alive.value,
                          ),
                        ),
                      ),
                      if (_guide != null && !AppState.I.calm)
                        Builder(builder: (_) {
                          final g = _guide!;
                          final c = s / _n;
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            left: (g % _n + 0.5) * c,
                            top: (g ~/ _n + 0.5) * c,
                            child: const IgnorePointer(child: Text('👆', style: TextStyle(fontSize: 36))),
                          );
                        }),
                      if (_done)
                        Positioned(
                          right: 10,
                          bottom: 6,
                          child: AnimatedBuilder(
                            animation: _alive,
                            builder: (_, child) => Transform.scale(
                              scale: AppState.I.calm ? 1 : Curves.elasticOut.transform(_alive.value),
                              child: child,
                            ),
                            child: Text(item.emoji, style: TextStyle(fontSize: s * 0.24)),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RoundBtn(icon: Icons.arrow_back_rounded, semantic: 'Previous', onTap: () => _go(-1), size: 66),
            RoundBtn(icon: Icons.refresh_rounded, semantic: 'Try again', onTap: _reset, size: 66, color: const Color(0xFFFFF59D)),
            RoundBtn(icon: Icons.arrow_forward_rounded, semantic: 'Next', onTap: () => _go(1), size: 66),
          ]),
        ),
      ]),
    );
  }
}

class _TracePainter extends CustomPainter {
  final String letter;
  final Color color;
  final List<List<Offset>> strokes;
  final int? guide;
  final int n;
  final double pulse, alive;
  final bool done;
  _TracePainter({
    required this.letter,
    required this.color,
    required this.strokes,
    required this.guide,
    required this.n,
    required this.pulse,
    required this.done,
    required this.alive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // dotted guide paper lines
    final line = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    for (var y = s * 0.2; y < s; y += s * 0.2) {
      canvas.drawLine(Offset(12, y), Offset(s - 12, y), line);
    }

    final fill = Paint()..color = done ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.13);
    final tpFill = _TraceScreenState._letterPainter(letter, s, fill);
    final off = _TraceScreenState._letterOffset(tpFill, s);
    canvas.save();
    if (done && alive > 0) {
      final sc = 1 + 0.08 * sin(alive * pi * 3) * (1 - alive);
      canvas.translate(s / 2, s / 2);
      canvas.scale(sc);
      canvas.translate(-s / 2, -s / 2);
    }
    tpFill.paint(canvas, off);
    if (!done) {
      final outline = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      _TraceScreenState._letterPainter(letter, s, outline).paint(canvas, off);
    }
    canvas.restore();

    if (!done) {
      // rainbow finger trail
      final c = s / n;
      var k = 0;
      for (final st in strokes) {
        for (var i = 1; i < st.length; i++) {
          final p = Paint()
            ..color = HSVColor.fromAHSV(0.85, (k * 6.0) % 360, 0.75, 0.95).toColor()
            ..strokeWidth = c * 1.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(st[i - 1], st[i], p);
          k++;
        }
        if (st.length == 1) {
          canvas.drawCircle(st.first, c * 0.75, Paint()..color = Colors.pinkAccent.withValues(alpha: 0.8));
        }
      }
      // guide dot
      final g = guide;
      if (g != null) {
        final center = Offset((g % n + 0.5) * c, (g ~/ n + 0.5) * c);
        canvas.drawCircle(center, c * (1.2 + 0.5 * pulse), Paint()..color = Colors.amber.withValues(alpha: 0.35));
        drawStar(canvas, center, c * 0.9, Paint()..color = Colors.amber);
      }
    } else {
      // sparkles around finished letter
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4 + alive * 2;
        drawStar(canvas, Offset(s / 2 + cos(a) * s * 0.4, s / 2 + sin(a) * s * 0.4), 10 + 6 * sin(alive * pi),
            Paint()..color = Colors.amber.withValues(alpha: 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter o) => true;
}
