import 'dart:math';

import 'package:flutter/material.dart';

import '../core/settings.dart';
import 'common.dart';

/// How a finished letter "comes alive". Data-driven: add an entry, no engine change.
enum MagicKind {
  orbit, // creatures fly around the letter
  runner, // something travels along the letter's own strokes
  grow, // something grows out of the letter, small things fall
  glow, // a firefly lights the traced path
  rain, // things gently fall around the letter
}

class LetterMagic {
  final MagicKind kind;
  final String main; // the star of the animation
  final String extra; // small helpers
  const LetterMagic(this.kind, this.main, [this.extra = '✨']);
}

const letterMagic = <String, LetterMagic>{
  'A': LetterMagic(MagicKind.grow, '🌳', '🍎'),
  'B': LetterMagic(MagicKind.orbit, '🦋', '🌸'),
  'C': LetterMagic(MagicKind.runner, '🐛', '🍃'),
  'D': LetterMagic(MagicKind.runner, '🦕', '🌿'),
  'E': LetterMagic(MagicKind.runner, '🚂', '💨'),
  'F': LetterMagic(MagicKind.glow, '🪲', '✨'),
  'G': LetterMagic(MagicKind.grow, '🍇', '🍃'),
  'H': LetterMagic(MagicKind.runner, '🐎', '💨'),
  'I': LetterMagic(MagicKind.rain, '🍦', '❄️'),
  'J': LetterMagic(MagicKind.orbit, '🪼', '🫧'),
  'K': LetterMagic(MagicKind.orbit, '🪁', '☁️'),
  'L': LetterMagic(MagicKind.runner, '🐞', '🍃'),
  'M': LetterMagic(MagicKind.grow, '🥭', '🍃'),
  'N': LetterMagic(MagicKind.grow, '🪺', '🥚'),
  'O': LetterMagic(MagicKind.orbit, '🐙', '🫧'),
  'P': LetterMagic(MagicKind.orbit, '🦜', '🪶'),
  'Q': LetterMagic(MagicKind.rain, '👑', '✨'),
  'R': LetterMagic(MagicKind.runner, '🐇', '🥕'),
  'S': LetterMagic(MagicKind.runner, '🐍', '✨'),
  'T': LetterMagic(MagicKind.runner, '🐯', '🐾'),
  'U': LetterMagic(MagicKind.rain, '☂️', '💧'),
  'V': LetterMagic(MagicKind.runner, '🚐', '💨'),
  'W': LetterMagic(MagicKind.rain, '🍉', '💧'),
  'X': LetterMagic(MagicKind.orbit, '🎵', '🎶'),
  'Y': LetterMagic(MagicKind.runner, '🪀', '✨'),
  'Z': LetterMagic(MagicKind.runner, '🦓', '🐾'),
  // numbers
  '1': LetterMagic(MagicKind.orbit, '⭐'),
  '2': LetterMagic(MagicKind.runner, '🦆', '💧'),
  '3': LetterMagic(MagicKind.orbit, '🎈'),
  '4': LetterMagic(MagicKind.runner, '🚗', '💨'),
  '5': LetterMagic(MagicKind.grow, '🖐️'),
  '6': LetterMagic(MagicKind.runner, '🐌', '✨'),
  '7': LetterMagic(MagicKind.rain, '🌈', '✨'),
  '8': LetterMagic(MagicKind.runner, '🐙', '🫧'),
  '9': LetterMagic(MagicKind.orbit, '🐝', '🌼'),
  '10': LetterMagic(MagicKind.rain, '🎉', '🎊'),
};

LetterMagic magicFor(String glyph) =>
    letterMagic[glyph] ?? letterMagic[glyph.toUpperCase()] ?? const LetterMagic(MagicKind.orbit, '⭐');

/// Plays the transformation over the finished letter (about 3 s, can loop).
class LetterMagicView extends StatefulWidget {
  final String glyph;
  final List<List<Offset>> strokes;
  final Color color;
  final bool loop;
  const LetterMagicView({super.key, required this.glyph, required this.strokes, required this.color, this.loop = false});

  @override
  State<LetterMagicView> createState() => _LetterMagicViewState();
}

class _LetterMagicViewState extends State<LetterMagicView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    if (AppState.I.calm) {
      _c.value = 1;
    } else if (widget.loop) {
      _c.repeat();
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = magicFor(widget.glyph);
    return LayoutBuilder(builder: (context, box) {
      final s = min(box.maxWidth, box.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: s,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              painter: _MagicPainter(widget.strokes, widget.color, m, _c.value),
            ),
          ),
        ),
      );
    });
  }
}

class _MagicPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final LetterMagic m;
  final double t;
  _MagicPainter(this.strokes, this.color, this.m, this.t);

  static final Map<String, TextPainter> _cache = {};
  static TextPainter _emoji(String e, double size) {
    final key = '$e@${size.round()}';
    return _cache.putIfAbsent(
        key,
        () => TextPainter(text: TextSpan(text: e, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)
          ..layout());
  }

  void _drawEmoji(Canvas c, String e, Offset center, double size, {double angle = 0, double opacity = 1}) {
    final tp = _emoji(e, size);
    c.save();
    c.translate(center.dx, center.dy);
    if (angle != 0) c.rotate(angle);
    if (opacity < 1) {
      c.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)));
    }
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    if (opacity < 1) c.restore();
    c.restore();
  }

  List<Offset> get _all => [for (final s in strokes) ...s];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // the finished letter, gently pulsing
    final pulse = 1 + 0.04 * sin(t * pi * 6) * (1 - t);
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.scale(pulse);
    canvas.translate(-s / 2, -s / 2);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final st in strokes) {
      final p = Path()..moveTo(st.first.dx * s, st.first.dy * s);
      for (final q in st.skip(1)) {
        p.lineTo(q.dx * s, q.dy * s);
      }
      canvas.drawPath(p, pen);
    }
    canvas.restore();

    final pts = _all;
    if (pts.isEmpty) return;
    final center = Offset(s / 2, s / 2);

    switch (m.kind) {
      case MagicKind.orbit:
        for (var i = 0; i < 5; i++) {
          final a = t * 2 * pi * 1.5 + i * 2 * pi / 5;
          final r = s * (0.3 + 0.08 * sin(t * 8 + i));
          final p = center + Offset(cos(a) * r, sin(a) * r * 0.85);
          _drawEmoji(canvas, i.isEven ? m.main : m.extra, p, s * (i.isEven ? 0.12 : 0.07),
              angle: sin(t * 20 + i) * 0.3, opacity: min(1.0, t * 4));
        }
      case MagicKind.runner:
        final idx = ((t * 1.15).clamp(0.0, 1.0) * (pts.length - 1)).floor();
        // trail of small helpers behind the runner
        for (var k = 1; k <= 4; k++) {
          final j = idx - k * 4;
          if (j < 0) break;
          _drawEmoji(canvas, m.extra, pts[j] * s, s * 0.05, opacity: 1 - k * 0.2);
        }
        final here = pts[idx] * s;
        final ahead = pts[min(idx + 1, pts.length - 1)] * s;
        final flip = ahead.dx < here.dx;
        canvas.save();
        canvas.translate(here.dx, here.dy - s * 0.04);
        if (!flip) canvas.scale(-1, 1); // most emoji face left; flip to face travel direction
        _drawEmoji(canvas, m.main, Offset.zero, s * 0.14);
        canvas.restore();
      case MagicKind.grow:
        final g = Curves.elasticOut.transform((t * 1.6).clamp(0.0, 1.0));
        _drawEmoji(canvas, m.main, center.translate(0, -s * 0.02), s * 0.42 * g, opacity: 0.9);
        for (var i = 0; i < 6; i++) {
          final f = ((t - 0.35 - i * 0.07) * 2.2).clamp(0.0, 1.0);
          if (f <= 0) continue;
          final x = s * (0.18 + i * 0.13);
          _drawEmoji(canvas, m.extra, Offset(x, s * (0.25 + f * 0.6)), s * 0.07, angle: f * 4);
        }
      case MagicKind.glow:
        final idx = ((t * 1.1).clamp(0.0, 1.0) * (pts.length - 1)).floor();
        for (var j = 0; j <= idx; j++) {
          canvas.drawCircle(pts[j] * s, s * 0.035,
              Paint()..color = const Color(0xFFFFF176).withValues(alpha: 0.18 + 0.3 * (j / max(1, idx))));
        }
        final p = pts[idx] * s;
        canvas.drawCircle(p, s * 0.09, Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.45));
        _drawEmoji(canvas, m.main, p.translate(0, -s * 0.03), s * 0.11);
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 + t * 6;
          drawStar(canvas, p + Offset(cos(a), sin(a)) * s * 0.12, s * 0.015, Paint()..color = Colors.amber);
        }
      case MagicKind.rain:
        _drawEmoji(canvas, m.main, center.translate(s * 0.3, -s * 0.32), s * 0.16 * min(1, t * 3));
        for (var i = 0; i < 10; i++) {
          final f = ((t * 1.4 + i * 0.1) % 1.0);
          final x = s * (0.08 + (i * 0.37 % 1.0) * 0.84);
          _drawEmoji(canvas, i.isEven ? m.extra : m.main, Offset(x, s * f), s * (i.isEven ? 0.05 : 0.08),
              opacity: 1 - f * 0.6);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MagicPainter o) => o.t != t;
}
