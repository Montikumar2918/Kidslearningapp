import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../core/strokes.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

/// Stroke-order tracing: numbered start dots, arrows along each stroke, a
/// "ghost finger" that demonstrates, and a rainbow trail as the child follows.
/// [writing] = A–Z Writing Mode: goes through every letter with fewer hints.
class ArrowTraceScreen extends StatefulWidget {
  final List<LearnItem> items;
  final bool writing;
  final String id;
  const ArrowTraceScreen({super.key, required this.items, required this.id, this.writing = false});

  @override
  State<ArrowTraceScreen> createState() => _ArrowTraceScreenState();
}

class _ArrowTraceScreenState extends State<ArrowTraceScreen> with TickerProviderStateMixin {
  int _i = 0;
  int _stroke = 0;
  int _progress = 0; // index of the next point to reach in the current stroke
  bool _done = false;
  bool _hints = true;
  final List<Offset> _trail = [];
  Mood _mood = Mood.idle;
  late final AnimationController _ghost =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _alive = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  LearnItem get item => widget.items[_i];
  List<Stroke> get _strokes => strokes[item.label] ?? const [];
  bool get hi => AppState.I.hindi;

  @override
  void initState() {
    super.initState();
    _hints = !widget.writing;
    WidgetsBinding.instance.addPostFrameCallback((_) => _intro());
  }

  @override
  void dispose() {
    _ghost.dispose();
    _alive.dispose();
    super.dispose();
  }

  void _intro() {
    final l = item.label!;
    final isSmall = l.toLowerCase() == l && l.toUpperCase() != l;
    Audio.I.say([
      if (_i == 0 || !widget.writing) (hi ? 'चलो लिखें' : "Let's write"),
      isSmall ? 'small $l' : l,
      if (_strokes.length > 1) (hi ? 'हरे गोले 1 से शुरू करो' : 'Start at the green dot number 1'),
    ]);
  }

  void _touch(Offset p, double s) {
    if (_done || _stroke >= _strokes.length) return;
    final pts = _strokes[_stroke];
    final tol = s * 0.1;
    // Look a few points ahead; jump to the furthest one the finger is close to.
    var best = -1;
    for (var k = _progress; k < min(pts.length, _progress + 8); k++) {
      if ((pts[k] * s - p).distance < tol) best = k;
    }
    if (best >= 0) {
      setState(() {
        _progress = best + 1;
        _trail.add(p);
      });
      if (_progress % 6 == 0) Audio.I.note((_progress ~/ 6) % 8);
      if (_progress >= pts.length - 1) _strokeDone();
    }
  }

  void _strokeDone() {
    HapticFeedback.lightImpact();
    Audio.I.fx('chime');
    setState(() {
      _stroke++;
      _progress = 0;
    });
    if (_stroke >= _strokes.length) {
      _finish();
    } else {
      Audio.I.say([hi ? 'अब ${_stroke + 1}' : 'Now number ${_stroke + 1}']);
    }
  }

  void _finish() {
    setState(() {
      _done = true;
      _mood = Mood.happy;
    });
    AppState.I.recordTraced(item.label!);
    AppState.I.recordLetter(item.label!, true);
    if (!AppState.I.calm) _alive.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      celebrate(context, sticker: !widget.writing || (_i + 1) % 5 == 0);
      Future.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) Audio.I.say([item.name(hi)]);
      });
      if (widget.writing) {
        Future.delayed(const Duration(milliseconds: 4200), () {
          if (mounted && _done) _go(1);
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _stroke = 0;
      _progress = 0;
      _done = false;
      _trail.clear();
      _mood = Mood.idle;
    });
    _alive.reset();
  }

  void _go(int d) {
    final n = widget.items.length;
    _i = (_i + d + n) % n;
    _reset();
    Audio.I.fx('whoosh');
    _intro();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: widget.id,
      color: item.color,
      onSpeak: _intro,
      title: widget.writing ? (hi ? 'A–Z लिखो' : 'A–Z Writing') : null,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Mascot(kind: MascotKind.golu, mood: _mood, size: 58),
      ),
      child: Column(children: [
        if (widget.writing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (_i + (_done ? 1 : 0)) / widget.items.length, minHeight: 10),
            ),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final s = min(box.maxWidth, box.maxHeight) - 24;
            if (s <= 0) return const SizedBox();
            return Center(
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: GestureDetector(
                    onPanStart: (d) => _touch(d.localPosition, s),
                    onPanUpdate: (d) => _touch(d.localPosition, s),
                    child: Stack(children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_ghost, _alive]),
                        builder: (_, __) => CustomPaint(
                          size: Size.square(s),
                          painter: _ArrowPainter(
                            strokes: _strokes,
                            current: _stroke,
                            progress: _progress,
                            ghost: AppState.I.calm ? -1 : _ghost.value,
                            hints: _hints,
                            done: _done,
                            alive: _alive.value,
                            color: darker(item.color),
                            trail: _trail,
                          ),
                        ),
                      ),
                      if (_done)
                        Positioned(
                          right: 12,
                          bottom: 8,
                          child: AnimatedBuilder(
                            animation: _alive,
                            builder: (_, child) => Transform.scale(
                              scale: AppState.I.calm ? 1 : Curves.elasticOut.transform(_alive.value),
                              child: child,
                            ),
                            child: Text(item.emoji, style: TextStyle(fontSize: s * 0.22)),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RoundBtn(icon: Icons.arrow_back_rounded, semantic: 'Previous', onTap: () => _go(-1), size: 62),
            RoundBtn(icon: Icons.refresh_rounded, semantic: 'Try again', onTap: _reset, size: 62, color: const Color(0xFFFFF59D)),
            RoundBtn(
              icon: _hints ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              semantic: 'Hints on or off',
              size: 62,
              color: const Color(0xFFE1F5FE),
              onTap: () => setState(() => _hints = !_hints),
            ),
            RoundBtn(icon: Icons.arrow_forward_rounded, semantic: 'Next', onTap: () => _go(1), size: 62),
          ]),
        ),
      ]),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final List<Stroke> strokes;
  final int current, progress;
  final double ghost, alive;
  final bool hints, done;
  final Color color;
  final List<Offset> trail;
  _ArrowPainter({
    required this.strokes,
    required this.current,
    required this.progress,
    required this.ghost,
    required this.hints,
    required this.done,
    required this.alive,
    required this.color,
    required this.trail,
  });

  Path _path(List<Offset> pts, double s, [int from = 0, int? to]) {
    final end = min(to ?? pts.length, pts.length);
    final p = Path();
    if (from >= end) return p;
    p.moveTo(pts[from].dx * s, pts[from].dy * s);
    for (var i = from + 1; i < end; i++) {
      p.lineTo(pts[i].dx * s, pts[i].dy * s);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // writing lines (top, middle, baseline)
    final guide = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.25)
      ..strokeWidth = 2;
    for (final y in [0.12, 0.45, 0.88]) {
      canvas.drawLine(Offset(10, y * s), Offset(s - 10, y * s), guide);
    }

    final road = Paint()
      ..color = hints ? const Color(0xFFE0E0E0) : const Color(0xFFF2F2F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1) grey "roads" for all strokes
    for (final st in strokes) {
      canvas.drawPath(_path(st, s), road);
    }
    // 2) dashed centre line on roads (hint)
    if (hints && !done) {
      final dash = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..strokeCap = StrokeCap.round;
      for (final st in strokes) {
        for (final m in _path(st, s).computeMetrics()) {
          for (double d = 0; d < m.length; d += s * 0.04) {
            canvas.drawPath(m.extractPath(d, d + s * 0.018), dash);
          }
        }
      }
    }
    // 3) finished strokes + progress of current stroke in colour
    for (var i = 0; i < strokes.length; i++) {
      final hue = (i * 70.0 + 200) % 360;
      ink.color = done ? color : HSVColor.fromAHSV(1, hue, 0.7, 0.95).toColor();
      if (i < current || done) {
        canvas.drawPath(_path(strokes[i], s), ink);
      } else if (i == current && progress > 0) {
        canvas.drawPath(_path(strokes[i], s, 0, progress + 1), ink);
      }
    }

    if (!done && current < strokes.length) {
      final st = strokes[current];
      // 4) arrows along the remaining part of the current stroke
      if (hints) {
        final arrow = Paint()
          ..color = const Color(0xFFFF7043)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        for (final m in _path(st, s, progress).computeMetrics()) {
          for (double d = s * 0.06; d < m.length - s * 0.03; d += s * 0.11) {
            final tan = m.getTangentForOffset(d);
            if (tan == null) continue;
            final dir = tan.vector / tan.vector.distance;
            final nrm = Offset(-dir.dy, dir.dx);
            final tip = tan.position + dir * s * 0.022;
            final back = tan.position - dir * s * 0.018;
            canvas.drawPath(
                Path()
                  ..moveTo(back.dx + nrm.dx * s * 0.022, back.dy + nrm.dy * s * 0.022)
                  ..lineTo(tip.dx, tip.dy)
                  ..lineTo(back.dx - nrm.dx * s * 0.022, back.dy - nrm.dy * s * 0.022),
                arrow);
          }
        }
        // numbered start dots for the current and following strokes
        for (var i = strokes.length - 1; i >= current; i--) {
          final p0 = strokes[i].first * s;
          final isCur = i == current;
          if (isCur && progress > 0) continue;
          canvas.drawCircle(p0, s * (isCur ? 0.05 : 0.035),
              Paint()..color = isCur ? const Color(0xFF43A047) : Colors.grey.withValues(alpha: 0.6));
          final tp = TextPainter(
            text: TextSpan(
                text: '${i + 1}',
                style: TextStyle(fontSize: s * (isCur ? 0.055 : 0.04), color: Colors.white, fontWeight: FontWeight.w900)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, p0 - Offset(tp.width / 2, tp.height / 2));
        }
      }
      // 5) ghost finger demonstrates the rest of the current stroke
      if (hints && ghost >= 0) {
        final idx = (progress + (st.length - progress) * ghost).floor().clamp(0, st.length - 1);
        final gp = st[idx] * s;
        canvas.drawCircle(gp, s * 0.035, Paint()..color = Colors.amber.withValues(alpha: 0.8 * (1 - ghost * 0.6)));
      }
      // 6) the next target point
      final nxt = st[progress.clamp(0, st.length - 1)] * s;
      canvas.drawCircle(nxt, s * 0.045, Paint()..color = Colors.amber.withValues(alpha: 0.35));
      drawStar(canvas, nxt, s * 0.03, Paint()..color = Colors.amber);
    }

    if (done) {
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4 + alive * 2;
        drawStar(canvas, Offset(s / 2 + cos(a) * s * 0.42, s / 2 + sin(a) * s * 0.42), 10 + 6 * sin(alive * pi),
            Paint()..color = Colors.amber);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter o) => true;
}
