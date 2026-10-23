import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/settings.dart';
import '../core/tracing_engine.dart';
import 'common.dart';

/// Reusable tracing area.
///  * Demo mode: a guide dot walks along each real stroke in order, lighting it up,
///    pausing between strokes, with a short spoken instruction.
///  * Child mode: the child draws; the [TraceEngine] checks start point, order,
///    direction and coverage. Off-track → the next segment glows (never a red cross).
class TracingCanvas extends StatefulWidget {
  final String glyphId; // used for stats, e.g. 'B' or 'b'
  final List<List<Offset>> strokes;
  final Color color;
  final bool startWithDemo;
  final VoidCallback? onComplete;
  final ValueChanged<int>? onStrokeDone;
  const TracingCanvas({
    super.key,
    required this.glyphId,
    required this.strokes,
    required this.color,
    this.startWithDemo = true,
    this.onComplete,
    this.onStrokeDone,
  });

  @override
  State<TracingCanvas> createState() => TracingCanvasState();
}

class TracingCanvasState extends State<TracingCanvas> with TickerProviderStateMixin {
  late TraceEngine _engine;
  late final AnimationController _demo;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  final List<List<Offset>> _ink = []; // child's strokes in normalised coords
  bool _demoing = false;
  DateTime _hintUntil = DateTime(2000);
  DateTime _lastOffTrackVoice = DateTime(2000);
  int _lastNote = 0;

  static const _strokeMs = 1300, _pauseMs = 450;

  bool get demoing => _demoing;
  double get progress => _engine.letterFraction;

  @override
  void initState() {
    super.initState();
    _engine = TraceEngine.forAge(widget.strokes, AppState.I.teacher ? 1 : AppState.I.age.index);
    _demo = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.strokes.length * (_strokeMs + _pauseMs)))
      ..addListener(_onDemoTick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _demoing = false);
          Audio.I.say([AppState.I.hindi ? 'अब तुम्हारी बारी!' : 'Now you try! Start at the green dot.']);
        }
      });
    if (widget.startWithDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) => replayDemo(countAsHint: false));
    }
  }

  @override
  void didUpdateWidget(covariant TracingCanvas old) {
    super.didUpdateWidget(old);
    if (old.glyphId != widget.glyphId) {
      _engine = TraceEngine.forAge(widget.strokes, AppState.I.teacher ? 1 : AppState.I.age.index);
      _demo.duration = Duration(milliseconds: widget.strokes.length * (_strokeMs + _pauseMs));
      _ink.clear();
      _demo.reset();
      _demoing = false;
      if (widget.startWithDemo) replayDemo(countAsHint: false);
    }
  }

  @override
  void dispose() {
    _demo.dispose();
    _pulse.dispose();
    super.dispose();
  }

  int _demoStroke = -1;
  void _onDemoTick() {
    final ms = _demo.value * _demo.duration!.inMilliseconds;
    final i = (ms / (_strokeMs + _pauseMs)).floor();
    if (i != _demoStroke && i < widget.strokes.length) {
      _demoStroke = i;
      Audio.I.note(i + 2);
    }
  }

  /// Plays the stroke-by-stroke demonstration. [countAsHint] records it for the learning model.
  void replayDemo({bool countAsHint = true}) {
    if (countAsHint) AppState.I.recordDemo(widget.glyphId);
    _demoStroke = -1;
    setState(() => _demoing = true);
    Audio.I.say([
      AppState.I.hindi ? 'देखो, ऐसे लिखते हैं' : 'Watch me!',
      if (widget.strokes.length > 1) (AppState.I.hindi ? '${widget.strokes.length} लाइनें' : '${widget.strokes.length} lines'),
    ]);
    _demo.forward(from: 0);
  }

  void reset() {
    setState(() {
      _engine.reset();
      _ink.clear();
    });
  }

  Offset _norm(Offset p, double s) => Offset(p.dx / s, p.dy / s);

  void _down(Offset p, double s) {
    if (_demoing || _engine.done) return;
    final n = _norm(p, s);
    final ev = _engine.down(n);
    setState(() => _ink.add([n]));
    if (ev == TraceEvent.wrongStart) {
      _hintUntil = DateTime.now().add(const Duration(milliseconds: 1500));
      if (DateTime.now().difference(_lastOffTrackVoice).inMilliseconds > 3000) {
        _lastOffTrackVoice = DateTime.now();
        Audio.I.say([AppState.I.hindi ? 'हरे गोले से शुरू करो' : 'Start at the green dot']);
      }
    }
  }

  void _move(Offset p, double s) {
    if (_demoing || _engine.done || _ink.isEmpty) return;
    final n = _norm(p, s);
    final ev = _engine.move(n);
    setState(() => _ink.last.add(n));
    switch (ev) {
      case TraceEvent.onTrack:
        final step = (_engine.strokeFraction * 6).floor();
        if (step != _lastNote) {
          _lastNote = step;
          Audio.I.note(step);
        }
      case TraceEvent.strokeDone:
        HapticFeedback.lightImpact();
        Audio.I.fx('chime');
        widget.onStrokeDone?.call(_engine.current);
        Audio.I.say([AppState.I.hindi ? 'शाबाश! अगली लाइन' : 'Great! Next line']);
      case TraceEvent.letterDone:
        HapticFeedback.mediumImpact();
        Audio.I.fx('chime');
        AppState.I.recordTraced(widget.glyphId);
        AppState.I.recordLetter(widget.glyphId, true);
        widget.onComplete?.call();
      case TraceEvent.offTrack:
      case TraceEvent.wrongDirection:
        _hintUntil = DateTime.now().add(const Duration(milliseconds: 1200));
        if (_engine.offTrackEvents % 25 == 1) AppState.I.recordOffTrack(widget.glyphId);
        if (DateTime.now().difference(_lastOffTrackVoice).inMilliseconds > 4000) {
          _lastOffTrackVoice = DateTime.now();
          Audio.I.say([
            ev == TraceEvent.wrongDirection
                ? (AppState.I.hindi ? 'तीर की तरफ़ चलो' : 'Follow the arrows')
                : (AppState.I.hindi ? 'चमकती लाइन पर चलो' : 'Follow the glowing line')
          ]);
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = min(box.maxWidth, box.maxHeight);
      return Center(
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Listener(
              onPointerDown: (e) => _down(e.localPosition, s),
              onPointerMove: (e) => _move(e.localPosition, s),
              onPointerUp: (_) => _engine.up(),
              onPointerCancel: (_) => _engine.up(),
              child: AnimatedBuilder(
                animation: Listenable.merge([_demo, _pulse]),
                builder: (_, __) => CustomPaint(
                  size: Size.square(s),
                  painter: _CanvasPainter(
                    strokes: widget.strokes,
                    color: widget.color,
                    current: _engine.current,
                    progress: _engine.progress,
                    ink: _ink,
                    demoing: _demoing,
                    demoMs: _demo.value * (_demo.duration?.inMilliseconds ?? 1),
                    pulse: _pulse.value,
                    hint: DateTime.now().isBefore(_hintUntil),
                    calm: AppState.I.calm,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes, ink;
  final Color color;
  final int current, progress;
  final bool demoing, hint, calm;
  final double demoMs, pulse;
  _CanvasPainter({
    required this.strokes,
    required this.ink,
    required this.color,
    required this.current,
    required this.progress,
    required this.demoing,
    required this.demoMs,
    required this.pulse,
    required this.hint,
    required this.calm,
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

  void _arrows(Canvas c, Path path, double s, Paint p) {
    for (final m in path.computeMetrics()) {
      for (double d = s * 0.06; d < m.length - s * 0.03; d += s * 0.12) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        final dir = t.vector / t.vector.distance;
        final nrm = Offset(-dir.dy, dir.dx);
        final tip = t.position + dir * s * 0.022, back = t.position - dir * s * 0.018;
        c.drawPath(
            Path()
              ..moveTo(back.dx + nrm.dx * s * 0.022, back.dy + nrm.dy * s * 0.022)
              ..lineTo(tip.dx, tip.dy)
              ..lineTo(back.dx - nrm.dx * s * 0.022, back.dy - nrm.dy * s * 0.022),
            p);
      }
    }
  }

  void _startDot(Canvas c, Offset at, int n, double s, bool active) {
    c.drawCircle(at, s * (active ? 0.05 : 0.034),
        Paint()..color = active ? const Color(0xFF43A047) : Colors.grey.withValues(alpha: 0.55));
    final tp = TextPainter(
      text: TextSpan(
          text: '$n',
          style: TextStyle(fontSize: s * (active ? 0.055 : 0.04), color: Colors.white, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final lines = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.22)
      ..strokeWidth = 2;
    for (final y in [0.12, 0.45, 0.88]) {
      canvas.drawLine(Offset(10, y * s), Offset(s - 10, y * s), lines);
    }
    final road = Paint()
      ..color = const Color(0xFFEDEDED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dots = Paint()
      ..color = Colors.grey.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final st in strokes) {
      canvas.drawPath(_path(st, s), road);
      for (var i = 0; i < st.length; i += 3) {
        canvas.drawCircle(st[i] * s, s * 0.008, dots);
      }
    }

    if (demoing) {
      // light up strokes one by one, guide dot travels along the real path
      const per = 1300.0 + 450.0;
      for (var i = 0; i < strokes.length; i++) {
        final local = demoMs - i * per;
        if (local <= 0) {
          _startDot(canvas, strokes[i].first * s, i + 1, s, false);
          continue;
        }
        final f = (local / 1300.0).clamp(0.0, 1.0);
        final upto = (f * (strokes[i].length - 1)).round() + 1;
        pen.color = color.withValues(alpha: 0.85);
        canvas.drawPath(_path(strokes[i], s, 0, upto), pen);
        if (f < 1) {
          _startDot(canvas, strokes[i].first * s, i + 1, s, true);
          _arrows(canvas, _path(strokes[i], s, upto - 1), s,
              Paint()
                ..color = const Color(0xFFFF7043)
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * 0.012
                ..strokeCap = StrokeCap.round);
          final g = strokes[i][upto - 1] * s;
          canvas.drawCircle(g, s * 0.055, Paint()..color = Colors.amber.withValues(alpha: 0.35));
          canvas.drawCircle(g, s * 0.03, Paint()..color = Colors.amber);
        }
      }
      return;
    }

    // completed strokes and progress
    for (var i = 0; i < strokes.length && i < current; i++) {
      pen.color = color;
      canvas.drawPath(_path(strokes[i], s), pen);
    }
    if (current < strokes.length) {
      final st = strokes[current];
      if (progress > 0) {
        pen.color = color;
        canvas.drawPath(_path(st, s, 0, progress + 1), pen);
      }
      // the next segment glows when the child needs help
      final glowFrom = progress;
      final glowTo = min(st.length, progress + (hint ? 14 : 6));
      canvas.drawPath(
          _path(st, s, glowFrom, glowTo),
          Paint()
            ..color = Colors.amber.withValues(alpha: hint ? 0.55 + 0.35 * pulse : 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * (hint ? 0.12 : 0.09)
            ..strokeCap = StrokeCap.round);
      _arrows(canvas, _path(st, s, progress), s,
          Paint()
            ..color = const Color(0xFFFF7043)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.012
            ..strokeCap = StrokeCap.round);
      for (var i = strokes.length - 1; i > current; i--) {
        _startDot(canvas, strokes[i].first * s, i + 1, s, false);
      }
      if (progress == 0) _startDot(canvas, st.first * s, current + 1, s, true);
      final nxt = st[progress.clamp(0, st.length - 1)] * s;
      final r = s * (0.04 + (calm ? 0 : 0.012 * pulse));
      drawStar(canvas, nxt, r, Paint()..color = Colors.amber);
    }

    // child's own finger trail (rainbow)
    var k = 0;
    for (final st in ink) {
      for (var i = 1; i < st.length; i++) {
        canvas.drawLine(
            st[i - 1] * s,
            st[i] * s,
            Paint()
              ..color = HSVColor.fromAHSV(0.55, (k * 5.0) % 360, 0.7, 0.95).toColor()
              ..strokeWidth = s * 0.03
              ..strokeCap = StrokeCap.round);
        k++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter o) => true;
}
