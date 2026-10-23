import 'dart:math';

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/season.dart';
import '../core/settings.dart';
import 'mascot.dart';

// ───────────────────── Background with season effects ─────────────────────

/// Sky, hills and gentle seasonal particles (Diwali lights, Holi colours, rain,
/// snow, butterflies, balloons). If [color] is given, a soft tinted sky is used.
class SceneBackground extends StatefulWidget {
  final Color? color;
  final Widget child;
  final bool hills;
  const SceneBackground({super.key, this.color, required this.child, this.hills = true});

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  final Season _season = currentSeason();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<Color> _sky() {
    final c = widget.color;
    if (c != null) return [Color.lerp(c, Colors.white, 0.45)!, Color.lerp(c, Colors.white, 0.85)!];
    switch (_season) {
      case Season.diwali:
        return const [Color(0xFF5C6BC0), Color(0xFFFFCC80)];
      case Season.rain:
        return const [Color(0xFF90A4AE), Color(0xFFCFD8DC)];
      case Season.winter:
        return const [Color(0xFFB3E5FC), Color(0xFFF1F8E9)];
      case Season.holi:
        return const [Color(0xFFF8BBD0), Color(0xFFFFF9C4)];
      case Season.halloween:
        return const [Color(0xFF7E57C2), Color(0xFFFFCC80)];
      case Season.christmas:
        return const [Color(0xFF90CAF9), Color(0xFFF1F8E9)];
      case Season.school:
        return const [Color(0xFF80DEEA), Color(0xFFFFF9C4)];
      default:
        return const [Color(0xFF81D4FA), Color(0xFFE1F5FE)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final calm = AppState.I.calm;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _sky()),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _StaticScenePainter(_season, widget.hills, widget.color != null)),
          ),
        ),
        if (!calm)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => CustomPaint(painter: _ParticlePainter(_season, _c.value)),
                ),
              ),
            ),
          ),
        widget.child,
      ]),
    );
  }
}

class _StaticScenePainter extends CustomPainter {
  final Season season;
  final bool hills, tinted;
  _StaticScenePainter(this.season, this.hills, this.tinted);

  @override
  void paint(Canvas canvas, Size s) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: tinted ? 0.5 : 0.75);
    void cl(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, cloud);
      canvas.drawCircle(Offset(x + r * 0.9, y + r * 0.2), r * 0.8, cloud);
      canvas.drawCircle(Offset(x - r * 0.9, y + r * 0.25), r * 0.7, cloud);
    }

    if (!tinted) {
      // sun or moon
      if (season == Season.diwali) {
        canvas.drawCircle(Offset(s.width * 0.82, s.height * 0.08), 26, Paint()..color = const Color(0xFFFFF8E1));
      } else if (season != Season.rain) {
        canvas.drawCircle(Offset(s.width * 0.84, s.height * 0.07), 40,
            Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.35));
        canvas.drawCircle(Offset(s.width * 0.84, s.height * 0.07), 28, Paint()..color = const Color(0xFFFFEE58));
      }
    }
    cl(s.width * 0.18, s.height * 0.09, 24);
    cl(s.width * 0.6, s.height * 0.17, 18);
    if (!hills) return;
    final snowy = season == Season.winter || season == Season.christmas;
    final green = snowy ? const Color(0xFFF5F5F5) : const Color(0xFFA5D6A7);
    final green2 = snowy ? const Color(0xFFE0E0E0) : const Color(0xFF81C784);
    final h1 = Path()
      ..moveTo(0, s.height * 0.86)
      ..quadraticBezierTo(s.width * 0.3, s.height * 0.78, s.width * 0.6, s.height * 0.87)
      ..quadraticBezierTo(s.width * 0.85, s.height * 0.93, s.width, s.height * 0.84)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    final h2 = Path()
      ..moveTo(0, s.height * 0.93)
      ..quadraticBezierTo(s.width * 0.5, s.height * 0.86, s.width, s.height * 0.95)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(h1, Paint()..color = green.withValues(alpha: tinted ? 0.6 : 1));
    canvas.drawPath(h2, Paint()..color = green2.withValues(alpha: tinted ? 0.6 : 1));
    if (season == Season.halloween) {
      // smiling pumpkins on the hill
      for (var i = 0; i < 4; i++) {
        final c = Offset(s.width * (0.12 + i * 0.25), s.height * 0.95);
        canvas.drawOval(Rect.fromCenter(center: c, width: 40, height: 30), Paint()..color = const Color(0xFFFF8F00));
        canvas.drawRect(Rect.fromCenter(center: c.translate(0, -17), width: 5, height: 8), Paint()..color = const Color(0xFF558B2F));
        final face = Paint()..color = const Color(0xFF5D4037);
        canvas.drawCircle(c.translate(-7, -3), 2.5, face);
        canvas.drawCircle(c.translate(7, -3), 2.5, face);
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, 3), width: 16, height: 10), 0.2, pi - 0.4, false,
            face..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
    if (season == Season.christmas) {
      for (var i = 0; i < 3; i++) {
        final x = s.width * (0.15 + i * 0.35), y = s.height * 0.97;
        for (var k = 0; k < 3; k++) {
          final w = 46.0 - k * 12, top = y - 18 - k * 16;
          canvas.drawPath(
              Path()
                ..moveTo(x - w / 2, top + 20)
                ..lineTo(x, top - 4)
                ..lineTo(x + w / 2, top + 20)
                ..close(),
              Paint()..color = const Color(0xFF2E7D32));
        }
        drawStar(canvas, Offset(x, y - 70), 7, Paint()..color = const Color(0xFFFFD600));
      }
    }
    if (season == Season.diwali) {
      // diyas on the hill
      for (var i = 0; i < 6; i++) {
        final x = s.width * (0.08 + i * 0.17);
        final y = s.height * 0.955;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 22, height: 10), Paint()..color = const Color(0xFFBF360C));
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 10), width: 8, height: 14), Paint()..color = const Color(0xFFFFB300));
        canvas.drawCircle(Offset(x, y - 10), 12, Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.3));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaticScenePainter o) => false;
}

class _ParticlePainter extends CustomPainter {
  final Season season;
  final double t;
  _ParticlePainter(this.season, this.t);
  static final _r = Random(7);
  static final _seeds = List.generate(26, (_) => [_r.nextDouble(), _r.nextDouble(), _r.nextDouble()]);
  static const _holi = [Color(0xFFE91E63), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0)];

  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < _seeds.length; i++) {
      final sd = _seeds[i];
      final p = (t * (0.6 + sd[2]) + sd[1]) % 1.0;
      switch (season) {
        case Season.halloween:
          if (i % 3 == 0) {
            // friendly bats
            final o = Offset(((sd[0] + t * 0.4) % 1.0) * s.width, s.height * (0.1 + 0.3 * sd[1]) + sin(t * 30 + i) * 10);
            final flap = sin(t * 150 + i) * 6;
            final bat = Paint()..color = const Color(0xFF4A148C).withValues(alpha: 0.7);
            canvas.drawCircle(o, 6, bat);
            canvas.drawPath(
                Path()
                  ..moveTo(o.dx, o.dy)
                  ..quadraticBezierTo(o.dx - 12, o.dy - 8 - flap, o.dx - 20, o.dy + 2)
                  ..quadraticBezierTo(o.dx - 10, o.dy, o.dx, o.dy)
                  ..quadraticBezierTo(o.dx + 10, o.dy, o.dx + 20, o.dy + 2)
                  ..quadraticBezierTo(o.dx + 12, o.dy - 8 - flap, o.dx, o.dy)
                  ..close(),
                bat);
          } else if (i % 3 == 1) {
            final tw = 0.5 + 0.5 * sin((t * 5 + sd[1]) * 2 * pi);
            canvas.drawCircle(Offset(sd[0] * s.width, sd[1] * s.height * 0.5), 2 + tw * 2,
                Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.4 + 0.5 * tw));
          }
        case Season.christmas:
          final o = Offset(sd[0] * s.width + sin((p + sd[2]) * 2 * pi) * 18, p * s.height);
          canvas.drawCircle(o, 2.5 + sd[2] * 3, Paint()..color = Colors.white.withValues(alpha: 0.9));
          if (i % 4 == 0) {
            final tw = 0.5 + 0.5 * sin((t * 8 + sd[1]) * 2 * pi);
            canvas.drawCircle(Offset(sd[0] * s.width, 8 + 6 * sin(sd[0] * 12)), 5,
                Paint()..color = _holi[i % _holi.length].withValues(alpha: 0.4 + 0.6 * tw));
          }
        case Season.school:
          if (i % 3 != 0) continue;
          final o = Offset(sd[0] * s.width + sin((p + sd[2]) * 2 * pi) * 16, (1 - p) * s.height);
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(sd[2] * 2 - 1);
          canvas.drawRect(const Rect.fromLTWH(-4, -18, 8, 30), Paint()..color = const Color(0xFFFFCA28).withValues(alpha: 0.75));
          canvas.drawPath(
              Path()
                ..moveTo(-4, 12)
                ..lineTo(4, 12)
                ..lineTo(0, 20)
                ..close(),
              Paint()..color = const Color(0xFFFFE0B2));
          canvas.drawRect(const Rect.fromLTWH(-4, -22, 8, 5), Paint()..color = const Color(0xFFF48FB1));
          canvas.restore();
        case Season.winter:
          final o = Offset(sd[0] * s.width + sin((p + sd[2]) * 2 * pi) * 18, p * s.height);
          canvas.drawCircle(o, 2.5 + sd[2] * 3, Paint()..color = Colors.white.withValues(alpha: 0.9));
        case Season.rain:
          final o = Offset(sd[0] * s.width, ((t * 3 + sd[1]) % 1.0) * s.height);
          canvas.drawLine(o, o.translate(-2, 12),
              Paint()
                ..color = const Color(0xFF64B5F6).withValues(alpha: 0.6)
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round);
        case Season.diwali:
          final tw = 0.5 + 0.5 * sin((t * 6 + sd[1]) * 2 * pi);
          final o = Offset(sd[0] * s.width, sd[1] * s.height * 0.55);
          canvas.drawCircle(o, 2 + 2 * tw, Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.4 + 0.6 * tw));
        case Season.holi:
          final o = Offset(sd[0] * s.width + sin((p + sd[2]) * 2 * pi) * 20, (1 - p) * s.height);
          canvas.drawCircle(o, 6 + sd[2] * 10, Paint()..color = _holi[i % _holi.length].withValues(alpha: 0.25));
        case Season.birthday:
          if (i % 2 == 1) continue;
          final o = Offset(sd[0] * s.width, (1.1 - p * 1.2) * s.height);
          final col = _holi[i % _holi.length].withValues(alpha: 0.7);
          canvas.drawOval(Rect.fromCenter(center: o, width: 26, height: 32), Paint()..color = col);
          canvas.drawLine(o.translate(0, 16), o.translate(sin(p * 10) * 4, 46),
              Paint()
                ..color = Colors.black26
                ..strokeWidth = 1.2);
        case Season.summer:
        case Season.normal:
          if (i % 4 != 0) continue;
          final o = Offset(((sd[0] + t * 0.3) % 1.0) * s.width, s.height * (0.3 + 0.4 * sd[1]) + sin(t * 20 + i) * 14);
          final flap = sin(t * 120 + i).abs();
          final col = _holi[i % _holi.length].withValues(alpha: 0.6);
          canvas.drawOval(Rect.fromCenter(center: o.translate(-5, 0), width: 9 * flap + 2, height: 12), Paint()..color = col);
          canvas.drawOval(Rect.fromCenter(center: o.translate(5, 0), width: 9 * flap + 2, height: 12), Paint()..color = col);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter o) => o.t != t;
}

// ───────────────────────────── Buttons ─────────────────────────────

class RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String semantic;
  final double size;
  const RoundBtn(
      {super.key, required this.icon, required this.onTap, required this.semantic, this.color = Colors.white, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Audio.I.fx('tick');
            onTap();
          },
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.55, color: Colors.black54)),
        ),
      ),
    );
  }
}

/// Standard layout for every activity: home button, optional title + speaker,
/// and a mascot in the corner. Records that the activity was played.
class GameScaffold extends StatefulWidget {
  final String id;
  final String? title;
  final Color? color;
  final VoidCallback? onSpeak;
  final Widget child;
  final bool hills;
  final Widget? trailing;
  const GameScaffold(
      {super.key,
      required this.id,
      required this.child,
      this.title,
      this.color,
      this.onSpeak,
      this.hills = false,
      this.trailing});

  @override
  State<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends State<GameScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppState.I.recordPlay(widget.id));
  }

  @override
  void dispose() {
    Audio.I.stopSpeech();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !AppState.I.childLock,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _lockHint();
      },
      child: Scaffold(
      body: SceneBackground(
        color: widget.color,
        hills: widget.hills,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                HomeButton(onHome: () => Navigator.of(context).pop(), onLockedTap: _lockHint),
                const SizedBox(width: 8),
                Expanded(
                  child: widget.title == null
                      ? const SizedBox()
                      : Text(widget.title!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                ),
                const SizedBox(width: 8),
                if (widget.trailing != null) widget.trailing!,
                if (widget.onSpeak != null)
                  RoundBtn(icon: Icons.volume_up_rounded, semantic: 'Say again', onTap: widget.onSpeak!),
              ]),
            ),
            Expanded(child: widget.child),
          ]),
        ),
      ),
      ),
    );
  }

  void _lockHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Child lock: press and hold 🏠 to go home'),
        duration: Duration(seconds: 2),
      ));
  }
}

/// Home button. With child lock on, it must be held for 1 second (a ring fills up),
/// so a toddler can't leave an activity by accident.
class HomeButton extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onLockedTap;
  const HomeButton({super.key, required this.onHome, required this.onLockedTap});
  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        Audio.I.fx('whoosh');
        widget.onHome();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.I.childLock) {
      return RoundBtn(icon: Icons.home_rounded, semantic: 'Home', onTap: widget.onHome);
    }
    return Semantics(
      button: true,
      label: 'Home (press and hold)',
      child: Listener(
        onPointerDown: (_) => _hold.forward(from: 0),
        onPointerUp: (_) {
          if (_hold.value < 1) {
            final quick = _hold.value < 0.3;
            _hold.reverse();
            if (quick) widget.onLockedTap();
          }
        },
        onPointerCancel: (_) => _hold.reverse(),
        child: AnimatedBuilder(
          animation: _hold,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.home_rounded, size: 34, color: Colors.black54),
            ),
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(value: _hold.value, strokeWidth: 5, color: Colors.orange),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────── Celebration ─────────────────────────────

/// Confetti + dancing Golu + praise + (optional) new sticker. Never blocks taps.
void celebrate(BuildContext context, {bool sticker = true, String? text}) {
  final hi = AppState.I.hindi;
  final praise = text ?? (hi ? praiseHi : praiseEn)[Random().nextInt(hi ? praiseHi.length : praiseEn.length)];
  final st = sticker ? AppState.I.earnSticker() : null;
  Audio.I.fx('yay');
  Future.delayed(const Duration(milliseconds: 450), () {
    Audio.I.say([praise, if (st != null) (hi ? 'नया स्टिकर!' : 'You got a sticker!')]);
  });
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _CelebrationView(text: praise, sticker: st, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _CelebrationView extends StatefulWidget {
  final String text;
  final String? sticker;
  final VoidCallback onDone;
  const _CelebrationView({required this.text, required this.sticker, required this.onDone});
  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = AppState.I.calm;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final v = _c.value;
          final appear = Curves.elasticOut.transform((v * 3).clamp(0.0, 1.0));
          final fade = v > 0.85 ? (1 - v) / 0.15 : 1.0;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Stack(children: [
              if (!calm) Positioned.fill(child: CustomPaint(painter: ConfettiPainter(v))),
              Align(
                alignment: const Alignment(0, 0.35),
                child: Transform.scale(
                  scale: calm ? 1 : appear,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 6))],
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(widget.text,
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                          if (widget.sticker != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(widget.sticker!, style: const TextStyle(fontSize: 44)),
                              const SizedBox(width: 6),
                              const Text('🎁', style: TextStyle(fontSize: 30)),
                            ]),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      const Mascot(kind: MascotKind.golu, mood: Mood.happy, size: 130),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double v;
  ConfettiPainter(this.v);
  static final _r = Random(3);
  static final _bits = List.generate(70, (_) => [_r.nextDouble(), _r.nextDouble(), _r.nextDouble(), _r.nextDouble()]);
  static const _cols = [
    Color(0xFFFF5252), Color(0xFFFFD740), Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFE040FB), Color(0xFFFF6E40)
  ];

  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < _bits.length; i++) {
      final b = _bits[i];
      final y = -30 + (v * (0.7 + b[1] * 0.6)) * (s.height + 60) * 1.1 - b[3] * 200;
      if (y < -20) continue;
      final x = b[0] * s.width + sin(v * 8 + b[2] * 6) * 26;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(v * 10 * (b[2] - 0.5));
      final p = Paint()..color = _cols[i % _cols.length];
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 5, p);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 14), p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter o) => o.v != v;
}

/// Little star burst on tap (gentle, no flashing).
class StarBurst extends StatelessWidget {
  final Animation<double> t;
  const StarBurst({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (_, __) => CustomPaint(painter: _BurstPainter(t.value), size: Size.infinite),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double v;
  _BurstPainter(this.v);
  static const _cols = [Colors.pinkAccent, Colors.amber, Colors.lightBlueAccent, Colors.lightGreen, Colors.purpleAccent];

  @override
  void paint(Canvas canvas, Size size) {
    if (v == 0 || v == 1) return;
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final d = 60 + v * size.shortestSide * 0.42;
      final p = Paint()..color = _cols[i % _cols.length].withValues(alpha: 1 - v);
      drawStar(canvas, c + Offset(cos(a) * d, sin(a) * d), 14 * (1 - v * 0.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.v != v;
}

void drawStar(Canvas canvas, Offset c, double r, Paint p) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * 0.45;
    final a = -pi / 2 + i * pi / 5;
    final pt = Offset(c.dx + rr * cos(a), c.dy + rr * sin(a));
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  canvas.drawPath(path..close(), p);
}

// ───────────────────────────── Shapes ─────────────────────────────

Path shapePath(String shape, Offset c, double s) {
  final path = Path();
  switch (shape) {
    case 'circle':
      path.addOval(Rect.fromCircle(center: c, radius: s * 0.42));
    case 'oval':
      path.addOval(Rect.fromCenter(center: c, width: s * 0.9, height: s * 0.6));
    case 'square':
      path.addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s * 0.78, height: s * 0.78), Radius.circular(s * 0.06)));
    case 'rectangle':
      path.addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s * 0.92, height: s * 0.56), Radius.circular(s * 0.06)));
    case 'triangle':
      path
        ..moveTo(c.dx, c.dy - s * 0.42)
        ..lineTo(c.dx + s * 0.46, c.dy + s * 0.36)
        ..lineTo(c.dx - s * 0.46, c.dy + s * 0.36)
        ..close();
    case 'diamond':
      path
        ..moveTo(c.dx, c.dy - s * 0.46)
        ..lineTo(c.dx + s * 0.34, c.dy)
        ..lineTo(c.dx, c.dy + s * 0.46)
        ..lineTo(c.dx - s * 0.34, c.dy)
        ..close();
    case 'star':
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? s * 0.47 : s * 0.21;
        final a = -pi / 2 + i * pi / 5;
        final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
    case 'heart':
      final w = s * 0.9;
      path
        ..moveTo(c.dx, c.dy + w * 0.4)
        ..cubicTo(c.dx - w * 0.62, c.dy - w * 0.05, c.dx - w * 0.3, c.dy - w * 0.58, c.dx, c.dy - w * 0.2)
        ..cubicTo(c.dx + w * 0.3, c.dy - w * 0.58, c.dx + w * 0.62, c.dy - w * 0.05, c.dx, c.dy + w * 0.4)
        ..close();
    default:
      path.addOval(Rect.fromCircle(center: c, radius: s * 0.4));
  }
  return path;
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;
  final bool face;
  ShapePainter(this.shape, this.color, {this.face = true});

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);
    final path = shapePath(shape, c, s);
    canvas.drawPath(
        path.shift(Offset(0, s * 0.03)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          ).createShader(Rect.fromCircle(center: c, radius: s / 2)));
    if (!face) return;
    final eye = Paint()..color = Colors.black87;
    canvas.drawCircle(c.translate(-s * 0.09, -s * 0.03), s * 0.03, eye);
    canvas.drawCircle(c.translate(s * 0.09, -s * 0.03), s * 0.03, eye);
    canvas.drawArc(
        Rect.fromCenter(center: c.translate(0, s * 0.04), width: s * 0.16, height: s * 0.12),
        0.2,
        pi - 0.4,
        false,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant ShapePainter old) => old.shape != shape || old.color != color;
}

// ───────────────────────────── Parent gate ─────────────────────────────

/// Simple maths question so only grown-ups get in. Returns true when solved.
Future<bool> parentGate(BuildContext context) async {
  final r = Random();
  final a = 3 + r.nextInt(7), b = 2 + r.nextInt(8);
  final answer = a + b;
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Grown-ups only'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('What is $a + $b ?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Answer'),
          onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v.trim()) == answer),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(int.tryParse(ctrl.text.trim()) == answer), child: const Text('OK')),
      ],
    ),
  );
  ctrl.dispose();
  if (ok != true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not quite — ask a grown-up 🙂')));
  }
  return ok == true;
}

/// Big picture of a LearnItem: emoji, letter or shape.
class ItemPicture extends StatelessWidget {
  final LearnItem item;
  final double size;
  final bool showLabel;
  const ItemPicture({super.key, required this.item, required this.size, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    if (shapes.contains(item)) {
      return SizedBox.square(dimension: size, child: CustomPaint(painter: ShapePainter(item.emoji, item.color)));
    }
    if (colorsList.contains(item)) {
      return Container(
        width: size * 0.85,
        height: size * 0.85,
        decoration: BoxDecoration(
          color: item.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 10),
          boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 4)],
        ),
        alignment: Alignment.center,
        child: Text(item.emoji, style: TextStyle(fontSize: size * 0.32)),
      );
    }
    if (showLabel && item.label != null && item.count == 0) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Text(item.label!,
            style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w900, color: darker(item.color), height: 1.15)),
        Text(item.emoji, style: TextStyle(fontSize: size * 0.32)),
      ]);
    }
    return Text(item.emoji, style: TextStyle(fontSize: size * 0.68));
  }
}

Color darker(Color c) => HSLColor.fromColor(c).withLightness(0.38).withSaturation(0.75).toColor();
