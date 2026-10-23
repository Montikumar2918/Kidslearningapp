import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/settings.dart';

enum MascotKind { golu, chiku } // Golu the elephant, Chiku the bird
enum Mood { idle, happy, wave, sleepy }

/// Cartoon mascot drawn entirely in code. Blinks, waves, dances.
class Mascot extends StatefulWidget {
  final MascotKind kind;
  final Mood mood;
  final double size;
  final VoidCallback? onTap;
  const Mascot({super.key, required this.kind, this.mood = Mood.idle, this.size = 100, this.onTap});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  Timer? _blinkTimer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 1800 + _rnd.nextInt(3000)), () async {
      if (!mounted) return;
      await _blink.forward(from: 0);
      if (!mounted) return;
      await _blink.reverse();
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _loop.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = AppState.I.calm;
    return Semantics(
      label: widget.kind == MascotKind.golu ? 'Golu the elephant' : 'Chiku the bird',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _blink]),
          builder: (_, __) {
            final t = calm ? 0.0 : _loop.value;
            double dy = 0, rot = 0;
            if (!calm) {
              switch (widget.mood) {
                case Mood.happy:
                  dy = -(sin(t * 2 * pi).abs()) * widget.size * 0.14;
                  rot = sin(t * 4 * pi) * 0.06;
                case Mood.idle:
                  dy = sin(t * 2 * pi) * widget.size * 0.025;
                  rot = sin(t * 2 * pi) * 0.025;
                case Mood.wave:
                  rot = sin(t * 2 * pi) * 0.05;
                case Mood.sleepy:
                  dy = sin(t * 2 * pi) * widget.size * 0.01;
              }
            }
            final painter = widget.kind == MascotKind.golu
                ? GoluPainter(t: _loop.value, blink: _blink.value, mood: widget.mood)
                : ChikuPainter(t: _loop.value, blink: _blink.value, mood: widget.mood);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: rot,
                child: CustomPaint(size: Size.square(widget.size), painter: painter),
              ),
            );
          },
        ),
      ),
    );
  }
}

void _eyes(Canvas c, double u, Offset l, Offset r, double blink, Mood mood) {
  final dark = Paint()..color = const Color(0xFF3E2723);
  if (mood == Mood.sleepy) {
    final p = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u
      ..strokeCap = StrokeCap.round;
    for (final e in [l, r]) {
      c.drawArc(Rect.fromCenter(center: e, width: 9 * u, height: 6 * u), 0.2, pi - 0.4, false, p);
    }
    return;
  }
  if (mood == Mood.happy) {
    final p = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * u
      ..strokeCap = StrokeCap.round;
    for (final e in [l, r]) {
      c.drawArc(Rect.fromCenter(center: e.translate(0, 2 * u), width: 9 * u, height: 8 * u), pi + 0.3, pi - 0.6, false, p);
    }
    return;
  }
  final h = max(1.2 * u, 9 * u * (1 - blink));
  for (final e in [l, r]) {
    c.drawOval(Rect.fromCenter(center: e, width: 7 * u, height: h), dark);
    if (blink < 0.5) c.drawCircle(e.translate(1.4 * u, -2 * u), 1.5 * u, Paint()..color = Colors.white);
  }
}

void _zzz(Canvas c, double u, double t, Offset at) {
  for (var i = 0; i < 2; i++) {
    final p = (t + i * 0.5) % 1.0;
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
            fontSize: (10 + 6 * p) * u, fontWeight: FontWeight.w900, color: Colors.indigo.withValues(alpha: 1 - p)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at.translate(p * 8 * u, -p * 22 * u));
  }
}

class GoluPainter extends CustomPainter {
  final double t, blink;
  final Mood mood;
  GoluPainter({required this.t, required this.blink, required this.mood});

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    const skin = Color(0xFF9FB8C8);
    const skinDark = Color(0xFF7E9AAD);
    final flap = mood == Mood.wave || mood == Mood.happy ? sin(t * 2 * pi * 2) * 0.12 : sin(t * 2 * pi) * 0.04;

    // ears (flap)
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(50 * u + side * 27 * u, 46 * u);
      c.scale(1 + flap * side.sign * side, 1);
      c.drawCircle(Offset.zero, 21 * u, Paint()..color = skinDark);
      c.drawCircle(Offset(side * 2 * u, 0), 14 * u, Paint()..color = const Color(0xFFF8BBD0));
      c.restore();
    }
    // head
    final head = Rect.fromCenter(center: Offset(50 * u, 48 * u), width: 60 * u, height: 58 * u);
    c.drawOval(head.shift(Offset(0, 3 * u)), Paint()..color = Colors.black.withValues(alpha: 0.08));
    c.drawOval(head, Paint()..color = skin);
    // little cap
    final cap = Path()
      ..moveTo(40 * u, 22 * u)
      ..quadraticBezierTo(50 * u, 6 * u, 60 * u, 22 * u)
      ..close();
    c.drawPath(cap, Paint()..color = const Color(0xFFFF7043));
    c.drawCircle(Offset(50 * u, 11 * u), 4 * u, Paint()..color = const Color(0xFFFFCA28));

    // trunk
    final trunk = Path()..moveTo(50 * u, 60 * u);
    switch (mood) {
      case Mood.happy:
        trunk.quadraticBezierTo(36 * u, 62 * u, 30 * u, (44 - 6 * sin(t * 2 * pi * 2)) * u);
      case Mood.wave:
        final sw = sin(t * 2 * pi) * 14;
        trunk.quadraticBezierTo((50 + sw / 2) * u, 76 * u, (52 + sw) * u, 88 * u);
      case Mood.sleepy:
        trunk.quadraticBezierTo(50 * u, 80 * u, 46 * u, 92 * u);
      case Mood.idle:
        trunk.quadraticBezierTo(46 * u, 78 * u, 56 * u, 90 * u);
    }
    final tp = Paint()
      ..color = skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * u
      ..strokeCap = StrokeCap.round;
    c.drawPath(trunk, tp);
    c.drawPath(
        trunk,
        Paint()
          ..color = skinDark.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * u);

    // cheeks
    final pink = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.55);
    c.drawCircle(Offset(34 * u, 58 * u), 5.5 * u, pink);
    c.drawCircle(Offset(66 * u, 58 * u), 5.5 * u, pink);
    // smile beside trunk
    c.drawArc(
        Rect.fromCenter(center: Offset(50 * u, 62 * u), width: 26 * u, height: 14 * u),
        0.35,
        pi - 0.7,
        false,
        Paint()
          ..color = const Color(0xFF3E2723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * u
          ..strokeCap = StrokeCap.round);

    _eyes(c, u, Offset(40 * u, 44 * u), Offset(60 * u, 44 * u), blink, mood);
    if (mood == Mood.sleepy) _zzz(c, u, t, Offset(74 * u, 18 * u));
  }

  @override
  bool shouldRepaint(covariant GoluPainter o) => o.t != t || o.blink != blink || o.mood != mood;
}

class ChikuPainter extends CustomPainter {
  final double t, blink;
  final Mood mood;
  ChikuPainter({required this.t, required this.blink, required this.mood});

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    const body = Color(0xFFFFD54F);
    const wing = Color(0xFFFFB300);
    const orange = Color(0xFFFF8F00);

    // feet
    final foot = Paint()
      ..color = orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * u
      ..strokeCap = StrokeCap.round;
    for (final x in [42.0, 58.0]) {
      c.drawLine(Offset(x * u, 84 * u), Offset(x * u, 94 * u), foot);
      c.drawLine(Offset(x * u, 94 * u), Offset((x - 4) * u, 97 * u), foot);
      c.drawLine(Offset(x * u, 94 * u), Offset((x + 4) * u, 97 * u), foot);
    }
    // tuft
    for (var i = -1; i <= 1; i++) {
      c.save();
      c.translate(50 * u + i * 5 * u, 24 * u);
      c.rotate(i * 0.4);
      c.drawOval(Rect.fromCenter(center: Offset(0, -6 * u), width: 6 * u, height: 14 * u), Paint()..color = orange);
      c.restore();
    }
    // body
    final r = Rect.fromCenter(center: Offset(50 * u, 56 * u), width: 64 * u, height: 62 * u);
    c.drawOval(r.shift(Offset(0, 3 * u)), Paint()..color = Colors.black.withValues(alpha: 0.08));
    c.drawOval(r, Paint()..color = body);
    c.drawOval(Rect.fromCenter(center: Offset(50 * u, 68 * u), width: 38 * u, height: 30 * u),
        Paint()..color = const Color(0xFFFFF59D));

    // wings
    double left = 0, right = 0;
    switch (mood) {
      case Mood.happy:
        left = -0.4 - 0.7 * sin(t * 2 * pi * 2).abs();
        right = -left;
      case Mood.wave:
        left = -1.2 - 0.5 * sin(t * 2 * pi * 2);
        right = 0.15;
      case Mood.sleepy:
        left = 0.1;
        right = -0.1;
      case Mood.idle:
        left = -0.15 - 0.1 * sin(t * 2 * pi);
        right = -left;
    }
    for (final w in [(-1.0, left), (1.0, right)]) {
      c.save();
      c.translate(50 * u + w.$1 * 28 * u, 58 * u);
      c.rotate(w.$2);
      c.drawOval(Rect.fromCenter(center: Offset(w.$1 * 4 * u, 6 * u), width: 14 * u, height: 26 * u),
          Paint()..color = wing);
      c.restore();
    }

    // cheeks
    final pink = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.55);
    c.drawCircle(Offset(34 * u, 56 * u), 5 * u, pink);
    c.drawCircle(Offset(66 * u, 56 * u), 5 * u, pink);

    // beak
    final open = mood == Mood.happy ? 3 * u * (0.5 + 0.5 * sin(t * 2 * pi * 2)) : 0.0;
    final top = Path()
      ..moveTo(44 * u, 53 * u)
      ..lineTo(56 * u, 53 * u)
      ..lineTo(50 * u, 60 * u)
      ..close();
    final bottom = Path()
      ..moveTo(46 * u, 55 * u + open)
      ..lineTo(54 * u, 55 * u + open)
      ..lineTo(50 * u, 61 * u + open)
      ..close();
    c.drawPath(bottom, Paint()..color = const Color(0xFFE65100));
    c.drawPath(top, Paint()..color = orange);

    _eyes(c, u, Offset(40 * u, 46 * u), Offset(60 * u, 46 * u), blink, mood);
    if (mood == Mood.sleepy) _zzz(c, u, t, Offset(72 * u, 20 * u));
  }

  @override
  bool shouldRepaint(covariant ChikuPainter o) => o.t != t || o.blink != blink || o.mood != mood;
}

/// Mascot with a speech bubble.
class TalkingMascot extends StatelessWidget {
  final MascotKind kind;
  final Mood mood;
  final String text;
  final double size;
  final VoidCallback? onTap;
  const TalkingMascot(
      {super.key, required this.kind, required this.text, this.mood = Mood.idle, this.size = 80, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Mascot(kind: kind, mood: mood, size: size, onTap: onTap),
      if (text.isNotEmpty)
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Text(text,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5D4037))),
          ),
        ),
    ]);
  }
}
