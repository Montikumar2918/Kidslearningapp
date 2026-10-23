import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

// ───────────────────────────── BUBBLES ─────────────────────────────

class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});
  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _Bubble {
  double x, y, r, speed, wobble;
  final LearnItem item;
  final Color color;
  _Bubble(this.x, this.y, this.r, this.speed, this.wobble, this.item, this.color);
}

class _Pop {
  final Offset at;
  final Color color;
  double t = 0;
  _Pop(this.at, this.color);
}

class _BubbleScreenState extends State<BubbleScreen> with SingleTickerProviderStateMixin {
  final _rnd = Random();
  final List<_Bubble> _bubbles = [];
  final List<_Pop> _pops = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  int _popped = 0;
  late final List<LearnItem> _pool;
  static const _cols = [Color(0xFF81D4FA), Color(0xFFF8BBD0), Color(0xFFC5E1A5), Color(0xFFFFE082), Color(0xFFCE93D8)];

  @override
  void initState() {
    super.initState();
    _pool = switch (AppState.I.age) {
      AgeMode.baby => [...animals, ...fruits],
      AgeMode.toddler => [...animals, ...fruits, ...abc],
      AgeMode.preschool => [...abc, ...numbers, ...swar],
    };
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _Bubble _make({bool start = false}) {
    final r = 52.0 + _rnd.nextDouble() * 30;
    return _Bubble(
      r + _rnd.nextDouble() * max(1, _size.width - 2 * r),
      start ? _size.height * (0.3 + _rnd.nextDouble() * 0.7) : _size.height + r,
      r,
      (AppState.I.calm ? 25 : 45) + _rnd.nextDouble() * 30,
      _rnd.nextDouble() * pi * 2,
      _pool[_rnd.nextInt(_pool.length)],
      _cols[_rnd.nextInt(_cols.length)],
    );
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    while (_bubbles.length < 6) {
      _bubbles.add(_make(start: _bubbles.length < 3 && _popped == 0));
    }
    for (final b in _bubbles) {
      b.y -= b.speed * dt;
      b.wobble += dt * 1.5;
    }
    _bubbles.removeWhere((b) => b.y < -b.r);
    for (final p in _pops) {
      p.t += dt * 2.5;
    }
    _pops.removeWhere((p) => p.t >= 1);
    setState(() {});
  }

  void _pop(_Bubble b) {
    HapticFeedback.mediumImpact();
    Audio.I.fx('pop');
    final hi = AppState.I.hindi;
    final snd = b.item.sound(hi);
    final word = b.item.label != null && b.item.count == 0 ? b.item.name(hi) : (b.item.label ?? b.item.name(hi));
    Future.delayed(const Duration(milliseconds: 180), () => Audio.I.say([word, if (snd != null) snd]));
    setState(() {
      _bubbles.remove(b);
      _pops.add(_Pop(Offset(b.x, b.y), b.color));
      _popped++;
    });
    if (_popped % 12 == 0) celebrate(context);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      id: 'bubbles',
      color: const Color(0xFF81D4FA),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('🫧 $_popped', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0277BD))),
      ),
      child: LayoutBuilder(builder: (context, box) {
        _size = box.biggest;
        return Stack(children: [
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _PopPainter(_pops)))),
          for (final b in _bubbles)
            Positioned(
              left: b.x - b.r + sin(b.wobble) * 12,
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
                      colors: [Colors.white.withValues(alpha: 0.95), b.color.withValues(alpha: 0.7)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: b.color.withValues(alpha: 0.4), blurRadius: 10)],
                  ),
                  alignment: Alignment.center,
                  child: b.item.label != null
                      ? Text(b.item.label!,
                          style: TextStyle(fontSize: b.r * 0.85, fontWeight: FontWeight.w900, color: darker(b.color)))
                      : Text(b.item.emoji, style: TextStyle(fontSize: b.r * 0.9)),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

class _PopPainter extends CustomPainter {
  final List<_Pop> pops;
  _PopPainter(this.pops);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pops) {
      for (var i = 0; i < 10; i++) {
        final a = i * pi / 5;
        final d = 20 + p.t * 70;
        canvas.drawCircle(p.at + Offset(cos(a) * d, sin(a) * d), 7 * (1 - p.t),
            Paint()..color = p.color.withValues(alpha: 1 - p.t));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ───────────────────────────── PIANO ─────────────────────────────

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});
  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> with SingleTickerProviderStateMixin {
  static const _keyColors = [
    Color(0xFFEF5350), Color(0xFFFFA726), Color(0xFFFFEE58), Color(0xFF66BB6A),
    Color(0xFF26C6DA), Color(0xFF42A5F5), Color(0xFF7E57C2), Color(0xFFEC407A),
  ];
  static final _keyAnimals = [animals[0], animals[1], animals[2], animals[3], animals[6], animals[7], animals[9], animals[10]];
  int _last = -1;
  int? _down;
  int _plays = 0;
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  DateTime _lastTap = DateTime.now();

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  void _play(int i) {
    Audio.I.note(i);
    HapticFeedback.selectionClick();
    setState(() {
      _last = i;
      _down = i;
      _plays++;
    });
    if (!AppState.I.calm) _jump.forward(from: 0);
    _lastTap = DateTime.now();
    // Say the animal's name once the child pauses.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (DateTime.now().difference(_lastTap).inMilliseconds >= 850) {
        final a = _keyAnimals[_last];
        final hi = AppState.I.hindi;
        Audio.I.say([a.name(hi)]);
      }
    });
    if (_plays % 30 == 0) celebrate(context, text: AppState.I.hindi ? 'कितना सुंदर संगीत!' : 'Beautiful music!');
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'piano',
      color: const Color(0xFFE1BEE7),
      title: hi ? 'जानवर पियानो' : 'Animal Piano',
      child: Column(children: [
        Expanded(
          flex: 4,
          child: Center(
            child: AnimatedBuilder(
              animation: _jump,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -sin(_jump.value * pi) * 40),
                child: child,
              ),
              child: _last < 0
                  ? const Mascot(kind: MascotKind.chiku, mood: Mood.wave, size: 160)
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_keyAnimals[_last].emoji, style: const TextStyle(fontSize: 120)),
                      Text('♪ ${_keyAnimals[_last].name(hi)} ♪',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: darker(_keyColors[_last]))),
                    ]),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < 8; i++)
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _play(i),
                    onPointerUp: (_) => setState(() => _down = null),
                    onPointerCancel: (_) => setState(() => _down = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      margin: EdgeInsets.fromLTRB(3, _down == i ? 10 : 0, 3, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(_keyColors[i], Colors.white, 0.4)!, _keyColors[i]],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22), top: Radius.circular(8)),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          if (_down != i) BoxShadow(color: _keyColors[i].withValues(alpha: 0.6), offset: const Offset(0, 8)),
                        ],
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 14),
                      child: FittedBox(child: Text(_keyAnimals[i].emoji, style: const TextStyle(fontSize: 34))),
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

// ───────────────────────────── DOORBELL HOUSE ─────────────────────────────

class DoorbellScreen extends StatefulWidget {
  const DoorbellScreen({super.key});
  @override
  State<DoorbellScreen> createState() => _DoorbellScreenState();
}

class _DoorbellScreenState extends State<DoorbellScreen> {
  late List<LearnItem> _guests;
  final Set<int> _open = {};
  final Set<int> _seen = {};
  static const _doorColors = [
    Color(0xFFE57373), Color(0xFF64B5F6), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFFBA68C8), Color(0xFF4DB6AC)
  ];

  @override
  void initState() {
    super.initState();
    _guests = ([...animals]..shuffle()).take(6).toList();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Audio.I.say([AppState.I.hindi ? 'घंटी बजाओ! कौन है?' : 'Ring the bell! Who is it?']));
  }

  void _ring(int i) {
    if (_open.contains(i)) {
      setState(() => _open.remove(i));
      Audio.I.fx('whoosh');
      return;
    }
    HapticFeedback.mediumImpact();
    Audio.I.fx('ring');
    final hi = AppState.I.hindi;
    final g = _guests[i];
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _open.add(i);
        _seen.add(i);
      });
      Audio.I.fx('boing');
      final snd = g.sound(hi);
      Audio.I.say([
        hi ? 'दरवाज़ा नंबर ${i + 1}' : 'Door number ${i + 1}',
        hi ? 'यह ${g.hi} है!' : "It's a ${g.en}!",
        if (snd != null) snd,
      ]);
      if (_seen.length == 6) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          celebrate(context, text: hi ? 'सब दोस्त मिल गए!' : 'You met all the friends!');
          setState(() {
            _open.clear();
            _seen.clear();
            _guests = ([...animals]..shuffle()).take(6).toList();
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'doorbell',
      color: const Color(0xFFFFCCBC),
      hills: true,
      title: hi ? 'कौन है?' : 'Who is it?',
      child: LayoutBuilder(builder: (context, box) {
        final w = min(box.maxWidth - 24, box.maxHeight * 0.72);
        return Center(
          child: SizedBox(
            width: w,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // roof
              CustomPaint(size: Size(w, w * 0.28), painter: _RoofPainter()),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  border: Border(
                      left: BorderSide(color: Color(0xFF8D6E63), width: 6),
                      right: BorderSide(color: Color(0xFF8D6E63), width: 6),
                      bottom: BorderSide(color: Color(0xFF8D6E63), width: 6)),
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                  children: [for (var i = 0; i < 6; i++) _door(i)],
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _door(int i) {
    final open = _open.contains(i);
    return GestureDetector(
      onTap: () => _ring(i),
      child: Column(children: [
        Expanded(
          child: Stack(children: [
            // inside: the guest
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 4),
                ),
                alignment: Alignment.center,
                child: AnimatedScale(
                  scale: open ? 1 : 0.3,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: FittedBox(child: Text(_guests[i].emoji, style: const TextStyle(fontSize: 60))),
                ),
              ),
            ),
            // the door panel swings open
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: open ? 1 : 0),
                duration: Duration(milliseconds: AppState.I.calm ? 0 : 450),
                curve: Curves.easeOut,
                builder: (_, v, child) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(-v * 1.35),
                  child: child,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_doorColors[i], Color.lerp(_doorColors[i], Colors.black, 0.15)!]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Stack(children: [
                    Align(
                      alignment: const Alignment(0, -0.45),
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const Align(
                        alignment: Alignment(0.7, 0.15),
                        child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFFFD54F))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        const Text('🔔', style: TextStyle(fontSize: 28)),
      ]),
    );
  }
}

class _RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final roof = Path()
      ..moveTo(-8, s.height)
      ..lineTo(s.width / 2, 0)
      ..lineTo(s.width + 8, s.height)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFD84315));
    for (var i = 1; i < 4; i++) {
      final y = s.height * i / 4;
      final half = s.width / 2 * i / 4 + 4;
      canvas.drawLine(Offset(s.width / 2 - half, y), Offset(s.width / 2 + half, y),
          Paint()
            ..color = const Color(0xFFBF360C)
            ..strokeWidth = 3);
    }
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.55), s.height * 0.18, Paint()..color = const Color(0xFFFFF59D));
    canvas.drawCircle(
        Offset(s.width / 2, s.height * 0.55),
        s.height * 0.18,
        Paint()
          ..color = const Color(0xFF8D6E63)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────────── MAGIC DRAW (0–2) ─────────────────────────────

class FreeDrawScreen extends StatefulWidget {
  const FreeDrawScreen({super.key});
  @override
  State<FreeDrawScreen> createState() => _FreeDrawScreenState();
}

class _Dot {
  final Offset p;
  final Color c;
  final double r;
  final bool star;
  _Dot(this.p, this.c, this.r, this.star);
}

class _FreeDrawScreenState extends State<FreeDrawScreen> {
  final List<_Dot> _dots = [];
  double _hue = 0;
  Offset? _lastNoteAt;
  final _rnd = Random();
  int _brush = 0; // 0 rainbow, 1 stars, 2 bubbles

  void _add(Offset p, Size s) {
    _hue = (_hue + 4) % 360;
    final c = HSVColor.fromAHSV(1, _hue, 0.7, 0.98).toColor();
    setState(() {
      if (_brush == 0) {
        _dots.add(_Dot(p, c, 16, false));
      } else if (_brush == 1) {
        _dots.add(_Dot(p + Offset(_rnd.nextDouble() * 30 - 15, _rnd.nextDouble() * 30 - 15), c, 10 + _rnd.nextDouble() * 12, true));
      } else {
        _dots.add(_Dot(p, c.withValues(alpha: 0.45), 10 + _rnd.nextDouble() * 24, false));
      }
      if (_dots.length > 2500) _dots.removeRange(0, 200);
    });
    if (_lastNoteAt == null || (_lastNoteAt! - p).distance > 60) {
      _lastNoteAt = p;
      Audio.I.note((7 - (p.dy / s.height * 8).clamp(0, 7)).round());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'draw',
      color: const Color(0xFFB2EBF2),
      title: hi ? 'उंगली से रंगो!' : 'Draw with your finger!',
      child: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LayoutBuilder(builder: (context, box) {
                return GestureDetector(
                  onPanStart: (d) => _add(d.localPosition, box.biggest),
                  onPanUpdate: (d) => _add(d.localPosition, box.biggest),
                  onTapDown: (d) {
                    Audio.I.fx('pop');
                    for (var i = 0; i < 8; i++) {
                      _add(d.localPosition + Offset(cos(i * pi / 4) * 22, sin(i * pi / 4) * 22), box.biggest);
                    }
                  },
                  child: CustomPaint(size: box.biggest, painter: _DrawPainter(_dots)),
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final b in [(0, '🌈'), (1, '⭐'), (2, '🫧')])
              GestureDetector(
                onTap: () {
                  setState(() => _brush = b.$1);
                  Audio.I.fx('tick');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _brush == b.$1 ? Colors.orange : Colors.white, width: 5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  alignment: Alignment.center,
                  child: Text(b.$2, style: const TextStyle(fontSize: 34)),
                ),
              ),
            RoundBtn(
              icon: Icons.delete_sweep_rounded,
              semantic: 'Clear',
              size: 70,
              color: const Color(0xFFFFCDD2),
              onTap: () {
                Audio.I.fx('whoosh');
                setState(_dots.clear);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DrawPainter extends CustomPainter {
  final List<_Dot> dots;
  _DrawPainter(this.dots);
  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final p = Paint()..color = d.c;
      if (d.star) {
        drawStar(canvas, d.p, d.r, p);
      } else {
        canvas.drawCircle(d.p, d.r, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ───────────────────────────── COLOR FILL ─────────────────────────────

class _Region {
  final Path Function(Size s) path;
  final Color start;
  const _Region(this.path, [this.start = Colors.white]);
}

class _Picture {
  final String en, hi;
  final List<_Region> regions;
  const _Picture(this.en, this.hi, this.regions);
}

Rect _r(Size s, double l, double t, double w, double h) => Rect.fromLTWH(l * s.width, t * s.height, w * s.width, h * s.height);
Path _oval(Size s, double l, double t, double w, double h) => Path()..addOval(_r(s, l, t, w, h));
Path _rect(Size s, double l, double t, double w, double h, [double rad = 8]) =>
    Path()..addRRect(RRect.fromRectAndRadius(_r(s, l, t, w, h), Radius.circular(rad)));
Path _poly(Size s, List<List<double>> pts) {
  final p = Path()..moveTo(pts[0][0] * s.width, pts[0][1] * s.height);
  for (final q in pts.skip(1)) {
    p.lineTo(q[0] * s.width, q[1] * s.height);
  }
  return p..close();
}

Path _petal(Size s, double a) {
  final c = Offset(0.5 * s.width, 0.32 * s.height);
  final m = Matrix4.translationValues(c.dx, c.dy, 0)..multiply(Matrix4.rotationZ(a));
  final base = Path()
    ..addOval(Rect.fromCenter(center: Offset(0, -0.14 * s.height), width: 0.17 * s.width, height: 0.17 * s.height));
  return base.transform(m.storage);
}

final _pictures = [
  _Picture('House', 'घर', [
    _Region((s) => _rect(s, 0, 0.82, 1, 0.18, 0), Colors.white), // grass
    _Region((s) => _oval(s, 0.76, 0.04, 0.18, 0.15)), // sun
    _Region((s) => _rect(s, 0.2, 0.42, 0.6, 0.42, 4)), // wall
    _Region((s) => _poly(s, [[0.12, 0.44], [0.5, 0.14], [0.88, 0.44]])), // roof
    _Region((s) => _rect(s, 0.43, 0.6, 0.15, 0.24, 6)), // door
    _Region((s) => _rect(s, 0.26, 0.5, 0.12, 0.11, 4)), // window
    _Region((s) => _rect(s, 0.62, 0.5, 0.12, 0.11, 4)), // window
  ]),
  _Picture('Fish', 'मछली', [
    _Region((s) => _poly(s, [[0.66, 0.5], [0.95, 0.28], [0.95, 0.72]])), // tail
    _Region((s) => _oval(s, 0.08, 0.28, 0.66, 0.44)), // body
    _Region((s) => _poly(s, [[0.32, 0.32], [0.46, 0.14], [0.55, 0.33]])), // top fin
    _Region((s) => _oval(s, 0.18, 0.4, 0.1, 0.1)), // eye
    _Region((s) => _oval(s, 0.06, 0.12, 0.08, 0.08)), // bubble
    _Region((s) => _oval(s, 0.14, 0.02, 0.06, 0.06)), // bubble
    _Region((s) => _rect(s, 0, 0.84, 1, 0.16, 0)), // sand
  ]),
  _Picture('Flower', 'फूल', [
    _Region((s) => _rect(s, 0.47, 0.42, 0.06, 0.38, 3)), // stem
    _Region((s) => _oval(s, 0.24, 0.52, 0.22, 0.1)), // leaf
    _Region((s) => _oval(s, 0.54, 0.6, 0.22, 0.1)), // leaf
    for (var i = 0; i < 6; i++) _Region((s) => _petal(s, i * pi / 3)),
    _Region((s) => _oval(s, 0.4, 0.22, 0.2, 0.2)), // centre
    _Region((s) => _poly(s, [[0.3, 0.78], [0.7, 0.78], [0.64, 0.98], [0.36, 0.98]])), // pot
  ]),
  _Picture('Car', 'गाड़ी', [
    _Region((s) => _rect(s, 0, 0.82, 1, 0.18, 0)), // road
    _Region((s) => _poly(s, [[0.26, 0.48], [0.36, 0.28], [0.66, 0.28], [0.76, 0.48]])), // cabin
    _Region((s) => _rect(s, 0.08, 0.46, 0.84, 0.24, 20)), // body
    _Region((s) => _poly(s, [[0.34, 0.46], [0.4, 0.33], [0.49, 0.33], [0.49, 0.46]])), // window
    _Region((s) => _poly(s, [[0.53, 0.46], [0.53, 0.33], [0.63, 0.33], [0.69, 0.46]])), // window
    _Region((s) => _oval(s, 0.18, 0.6, 0.18, 0.18)), // wheel
    _Region((s) => _oval(s, 0.64, 0.6, 0.18, 0.18)), // wheel
    _Region((s) => _oval(s, 0.86, 0.5, 0.06, 0.06)), // light
  ]),
];

class ColorSplashScreen extends StatefulWidget {
  const ColorSplashScreen({super.key});
  @override
  State<ColorSplashScreen> createState() => _ColorSplashScreenState();
}

class _ColorSplashScreenState extends State<ColorSplashScreen> {
  int _pic = 0;
  int _color = 0;
  late List<Color> _fills;
  bool _celebrated = false;

  _Picture get pic => _pictures[_pic];

  @override
  void initState() {
    super.initState();
    _resetFills();
  }

  void _resetFills() {
    _fills = [for (final r in pic.regions) r.start];
    _celebrated = false;
  }

  void _tap(Offset p, Size s) {
    for (var i = pic.regions.length - 1; i >= 0; i--) {
      if (pic.regions[i].path(s).contains(p)) {
        HapticFeedback.lightImpact();
        Audio.I.fx('splash');
        setState(() => _fills[i] = colorsList[_color].color);
        if (!_celebrated && !_fills.contains(Colors.white)) {
          _celebrated = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) celebrate(context, text: AppState.I.hindi ? 'कितना सुंदर!' : 'So beautiful!');
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'splash',
      color: const Color(0xFFFFE0B2),
      title: hi ? pic.hi : pic.en,
      onSpeak: () => Audio.I.say([hi ? pic.hi : pic.en]),
      child: Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(builder: (context, box) {
                  return GestureDetector(
                    onTapDown: (d) => _tap(d.localPosition, box.biggest),
                    child: CustomPaint(size: box.biggest, painter: _FillPainter(pic, _fills)),
                  );
                }),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            children: [
              for (var i = 0; i < colorsList.length; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _color = i);
                    Audio.I.say([colorsList[i].name(hi)]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _color == i ? 64 : 54,
                    height: _color == i ? 64 : 54,
                    decoration: BoxDecoration(
                      color: colorsList[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == i ? Colors.black54 : Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RoundBtn(
                icon: Icons.refresh_rounded,
                semantic: 'Clear',
                onTap: () => setState(_resetFills),
                color: const Color(0xFFFFF59D)),
            RoundBtn(
              icon: Icons.arrow_forward_rounded,
              semantic: 'Next picture',
              onTap: () {
                setState(() {
                  _pic = (_pic + 1) % _pictures.length;
                  _resetFills();
                });
                Audio.I.fx('whoosh');
                Audio.I.say([hi ? pic.hi : pic.en]);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _FillPainter extends CustomPainter {
  final _Picture pic;
  final List<Color> fills;
  _FillPainter(this.pic, this.fills);

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < pic.regions.length; i++) {
      final p = pic.regions[i].path(size);
      canvas.drawPath(p, Paint()..color = fills[i]);
      canvas.drawPath(p, outline);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
