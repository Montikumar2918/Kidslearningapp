import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

// ───────────────────────────── FIND IT ─────────────────────────────

class FindItScreen extends StatefulWidget {
  const FindItScreen({super.key});
  @override
  State<FindItScreen> createState() => _FindItScreenState();
}

class _FindItScreenState extends State<FindItScreen> with TickerProviderStateMixin {
  final _rnd = Random();
  late List<LearnItem> _pool;
  late List<LearnItem> _choices;
  late LearnItem _target;
  int? _wrong;
  bool _done = false;
  int _right = 0;
  Mood _mood = Mood.idle;
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  int get _count => AppState.I.age == AgeMode.preschool ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _pool = [
      ...animals,
      ...fruits,
      ...vehicles,
      if (AppState.I.age != AgeMode.baby) ...colorsList,
      if (AppState.I.age == AgeMode.preschool) ...abc,
      if (AppState.I.age == AgeMode.preschool) ...shapes,
    ];
    _newRound();
  }

  @override
  void dispose() {
    _burst.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _newRound() {
    final list = [..._pool]..shuffle(_rnd);
    final picked = <LearnItem>[];
    for (final it in list) {
      if (picked.every((p) => p.en != it.en && p.emoji != it.emoji)) picked.add(it);
      if (picked.length == _count) break;
    }
    _choices = picked;
    _target = picked[_rnd.nextInt(picked.length)];
    _wrong = null;
    _done = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  String _question(bool hi) {
    if (colorsList.contains(_target)) return hi ? '${_target.hi} रंग कहाँ है?' : 'Where is ${_target.en}?';
    if (abc.contains(_target)) return hi ? '${_target.label} कहाँ है?' : 'Where is the letter ${_target.label}?';
    return hi ? '${_target.hi} कहाँ है?' : 'Where is the ${_target.en}?';
  }

  void _ask() => Audio.I.say([_question(AppState.I.hindi)]);

  String _nameOf(LearnItem it, bool hi) => abc.contains(it) ? it.label! : it.name(hi);

  void _pick(int i) {
    if (_done) return;
    final hi = AppState.I.hindi;
    if (_choices[i] == _target) {
      setState(() {
        _done = true;
        _mood = Mood.happy;
        _right++;
      });
      HapticFeedback.mediumImpact();
      Audio.I.fx('chime');
      if (!AppState.I.calm) _burst.forward(from: 0);
      if (_right % 4 == 0) {
        celebrate(context);
      } else {
        Audio.I.say([(hi ? praiseHi : praiseEn)[_rnd.nextInt(3)]]);
      }
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() {
          _mood = Mood.idle;
          _newRound();
        });
      });
    } else {
      setState(() => _wrong = i);
      if (!AppState.I.calm) _shake.forward(from: 0);
      Audio.I.fx('boing');
      final n = _nameOf(_choices[i], hi);
      Audio.I.say([hi ? 'यह $n है। फिर से ढूँढो!' : 'That is $n. Try again!']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'findit',
      color: const Color(0xFFD1C4E9),
      onSpeak: _ask,
      child: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TalkingMascot(kind: MascotKind.golu, mood: _mood, text: _question(hi), size: 78, onTap: _ask),
          ),
          Expanded(
            child: Flex(
              direction: _count == 3 && MediaQuery.of(context).size.width > 600 ? Axis.horizontal : Axis.vertical,
              children: [
                for (var i = 0; i < _choices.length; i++)
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_wrong == i ? sin(_shake.value * pi * 6) * 14 : 0, 0),
                        child: child,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: GestureDetector(
                          onTap: () => _pick(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: _done && _choices[i] == _target ? const Color(0xFFC8E6C9) : Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                  color: _done && _choices[i] == _target ? Colors.green : _choices[i].color, width: 7),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                            ),
                            alignment: Alignment.center,
                            child: AnimatedScale(
                              scale: _done && _choices[i] != _target ? 0.7 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: LayoutBuilder(
                                builder: (_, b) => ItemPicture(item: _choices[i], size: min(b.maxWidth, b.maxHeight) * 0.9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
        Positioned.fill(child: StarBurst(t: _burst)),
      ]),
    );
  }
}

// ───────────────────────────── CATCH IT ─────────────────────────────

class CatchScreen extends StatefulWidget {
  const CatchScreen({super.key});
  @override
  State<CatchScreen> createState() => _CatchScreenState();
}

class _Falling {
  double x, y, speed, spin;
  final LearnItem item;
  _Falling(this.x, this.y, this.speed, this.spin, this.item);
}

class _CatchScreenState extends State<CatchScreen> with TickerProviderStateMixin {
  final _rnd = Random();
  final List<_Falling> _items = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  double _basket = 0.5; // 0..1
  double _spawn = 0;
  int _caught = 0;
  double _squash = 0;
  static const _goal = 5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Audio.I.say([AppState.I.hindi ? 'टोकरी से फल पकड़ो!' : 'Catch the fruits with the basket!']));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    _spawn -= dt;
    if (_spawn <= 0 && _items.length < 3) {
      _spawn = 1.6 + _rnd.nextDouble();
      _items.add(_Falling(0.1 + _rnd.nextDouble() * 0.8, 0.12, (AppState.I.calm ? 0.09 : 0.14) + _rnd.nextDouble() * 0.05,
          _rnd.nextDouble() * 2 - 1, fruits[_rnd.nextInt(fruits.length)]));
    }
    final caught = <_Falling>[];
    for (final f in _items) {
      f.y += f.speed * dt;
      // basket zone near the bottom
      if (f.y > 0.8 && f.y < 0.9 && (f.x - _basket).abs() < 0.14) caught.add(f);
    }
    _items.removeWhere((f) => f.y > 1.05);
    for (final f in caught) {
      _items.remove(f);
      _onCatch(f.item);
    }
    _squash = max(0, _squash - dt * 4);
    setState(() {});
  }

  void _onCatch(LearnItem it) {
    HapticFeedback.lightImpact();
    Audio.I.fx('boing');
    _squash = 1;
    _caught++;
    Audio.I.say([it.name(AppState.I.hindi)]);
    if (_caught % _goal == 0) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) celebrate(context, text: AppState.I.hindi ? 'टोकरी भर गई!' : 'The basket is full!');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    final filled = _caught % _goal == 0 && _caught > 0 ? _goal : _caught % _goal;
    return GameScaffold(
      id: 'catch',
      color: const Color(0xFFC5E1A5),
      hills: true,
      title: hi ? 'फल पकड़ो!' : 'Catch the fruit!',
      child: LayoutBuilder(builder: (context, box) {
        _size = box.biggest;
        final w = box.maxWidth, h = box.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _basket = (d.localPosition.dx / w).clamp(0.08, 0.92),
          onTapDown: (d) => _basket = (d.localPosition.dx / w).clamp(0.08, 0.92),
          child: Stack(children: [
            // tree canopy
            Positioned(
              left: -20,
              right: -20,
              top: -10,
              height: h * 0.16,
              child: CustomPaint(painter: _CanopyPainter()),
            ),
            for (final f in _items)
              Positioned(
                left: f.x * w - 32,
                top: f.y * h - 32,
                child: Transform.rotate(
                  angle: f.spin * f.y * 4,
                  child: Text(f.item.emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
            Positioned(
              left: _basket * w - 60,
              top: h * 0.82,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(1 + _squash * 0.15, 1 - _squash * 0.15, 1),
                child: const SizedBox(
                  width: 120,
                  child: Text('🧺', textAlign: TextAlign.center, style: TextStyle(fontSize: 84)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * 0.17,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _goal; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(5),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled ? Colors.orange : Colors.white,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                  ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

class _CanopyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()..color = const Color(0xFF66BB6A);
    final g2 = Paint()..color = const Color(0xFF43A047);
    for (var i = 0; i < 7; i++) {
      final x = s.width * i / 6;
      canvas.drawCircle(Offset(x, s.height * 0.35), s.height * 0.55, i.isEven ? g : g2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ───────────────────────────── PUZZLE ─────────────────────────────

class PuzzleScreen extends StatefulWidget {
  /// letters = true → Alphabet Puzzle (build a big letter).
  final bool letters;
  const PuzzleScreen({super.key, this.letters = false});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final _rnd = Random();
  late LearnItem _item;
  late int _cols, _rows;
  final Set<int> _placed = {};
  late List<int> _tray;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  void _newPuzzle() {
    final pool = widget.letters ? abc : [...animals, ...fruits, ...vehicles];
    _item = pool[_rnd.nextInt(pool.length)];
    final four = AppState.I.age == AgeMode.preschool;
    _cols = 2;
    _rows = four ? 2 : 1;
    _placed.clear();
    _tray = List.generate(_cols * _rows, (i) => i)..shuffle(_rnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => Audio.I.say([AppState.I.hindi ? 'पहेली जोड़ो!' : 'Make the picture!']));
  }

  Widget _full(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(_item.color, Colors.white, 0.3)!, _item.color],
          ),
        ),
        alignment: Alignment.center,
        child: widget.letters
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_item.label!,
                    style: TextStyle(fontSize: min(w, h) * 0.62, fontWeight: FontWeight.w900, color: darker(_item.color))),
                Text(_item.emoji, style: TextStyle(fontSize: min(w, h) * 0.22)),
              ])
            : Text(_item.emoji, style: TextStyle(fontSize: min(w, h) * 0.72)),
      );

  Widget _piece(int idx, double w, double h, {double border = 3}) {
    final c = idx % _cols, r = idx ~/ _cols;
    final pw = w / _cols, ph = h / _rows;
    final ax = _cols == 1 ? 0.0 : -1 + 2 * c / (_cols - 1);
    final ay = _rows == 1 ? 0.0 : -1 + 2 * r / (_rows - 1);
    return Container(
      width: pw,
      height: ph,
      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: border)),
      child: ClipRect(
        child: OverflowBox(
          maxWidth: w,
          maxHeight: h,
          minWidth: w,
          minHeight: h,
          alignment: Alignment(ax, ay),
          child: _full(w, h),
        ),
      ),
    );
  }

  void _drop(int idx) {
    HapticFeedback.mediumImpact();
    Audio.I.fx('pop');
    setState(() {
      _placed.add(idx);
      _tray.remove(idx);
    });
    if (_placed.length == _cols * _rows) {
      final hi = AppState.I.hindi;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        celebrate(context);
        Future.delayed(const Duration(milliseconds: 1800), () {
          final snd = _item.sound(hi);
          if (widget.letters) AppState.I.recordLetter(_item.label!, true);
          Audio.I.say(widget.letters ? letterSoundPhrase(_item) : [_item.name(hi), if (snd != null) snd]);
        });
        Future.delayed(const Duration(milliseconds: 4200), () {
          if (mounted) setState(_newPuzzle);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: widget.letters ? 'abcpuzzle' : 'puzzle',
      color: const Color(0xFFFFCCBC),
      title: hi ? 'टुकड़े खींचो' : 'Drag the pieces',
      child: LayoutBuilder(builder: (context, box) {
        final w = min(box.maxWidth - 40, box.maxHeight * 0.5);
        final h = w;
        final pw = w / _cols, ph = h / _rows;
        return Column(children: [
          const SizedBox(height: 8),
          // board
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(children: [
                // faint hint picture
                Opacity(opacity: 0.18, child: _full(w, h)),
                for (var idx = 0; idx < _cols * _rows; idx++)
                  Positioned(
                    left: (idx % _cols) * pw,
                    top: (idx ~/ _cols) * ph,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (d) => d.data == idx,
                      onAcceptWithDetails: (d) => _drop(d.data),
                      builder: (_, cand, __) => _placed.contains(idx)
                          ? _piece(idx, w, h, border: 0)
                          : Container(
                              width: pw,
                              height: ph,
                              decoration: BoxDecoration(
                                border: Border.all(color: cand.isNotEmpty ? Colors.green : Colors.black26, width: 3),
                                color: cand.isNotEmpty ? Colors.green.withValues(alpha: 0.15) : null,
                              ),
                            ),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // tray
          Expanded(
            child: Center(
              child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
                for (final idx in _tray)
                  Draggable<int>(
                    data: idx,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(scale: 1.05, child: _piece(idx, w, h)),
                    ),
                    childWhenDragging: Opacity(opacity: 0.25, child: _piece(idx, w * 0.75, h * 0.75)),
                    onDragStarted: () => Audio.I.fx('tick'),
                    onDraggableCanceled: (_, __) => Audio.I.fx('boing'),
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: _piece(idx, w * 0.75, h * 0.75),
                    ),
                  ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}

// ───────────────────────────── CATERPILLAR / TRAIN ORDER ─────────────────────────────

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  final _rnd = Random();
  bool _train = false; // false = caterpillar with letters, true = train with numbers
  late List<String> _seq;
  late List<String> _tray;
  int _next = 0;
  String? _wrong;
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  static const _ballColors = [
    Color(0xFF66BB6A), Color(0xFF9CCC65), Color(0xFF26A69A), Color(0xFF7CB342), Color(0xFF43A047)
  ];
  static const _wagonColors = [
    Color(0xFFEF5350), Color(0xFF42A5F5), Color(0xFFFFCA28), Color(0xFFAB47BC), Color(0xFFFF7043)
  ];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  void _newRound() {
    _walk.reset();
    if (_train) {
      final start = 1 + _rnd.nextInt(6);
      _seq = [for (var i = 0; i < 5; i++) '${start + i}'];
    } else {
      final letters = AppState.I.hindi ? swar.map((e) => e.label!).take(11).toList() : abc.map((e) => e.label!).toList();
      final start = _rnd.nextInt(letters.length - 4);
      _seq = letters.sublist(start, start + 5);
    }
    _tray = [..._seq]..shuffle(_rnd);
    _next = 0;
    _wrong = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() {
    final hi = AppState.I.hindi;
    if (_next >= _seq.length) return;
    final v = _seq[_next];
    Audio.I.say([
      if (_next == 0) (_train ? (hi ? 'ट्रेन बनाओ!' : "Let's build the train!") : (hi ? 'इल्ली बनाओ!' : "Let's build the caterpillar!")),
      hi ? '$v ढूँढो' : 'Find $v',
    ]);
  }

  void _tap(String v) {
    if (_next >= _seq.length) return;
    if (v == _seq[_next]) {
      HapticFeedback.lightImpact();
      Audio.I.note(_next + 2);
      setState(() {
        _tray.remove(v);
        _next++;
        _wrong = null;
      });
      if (_next == _seq.length) {
        Audio.I.say([_seq.join(', ')]);
        if (!AppState.I.calm) _walk.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) celebrate(context);
        });
        Future.delayed(const Duration(milliseconds: 4200), () {
          if (!mounted) return;
          setState(() {
            _train = !_train;
            _newRound();
          });
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), _ask);
      }
    } else {
      setState(() => _wrong = v);
      Audio.I.fx('boing');
      final hi = AppState.I.hindi;
      Audio.I.say([hi ? 'यह $v है। ${_seq[_next]} ढूँढो' : 'That is $v. Find ${_seq[_next]}']);
    }
  }

  Widget _segment(int i, double s) {
    final filled = i < _next;
    final label = filled ? _seq[i] : '?';
    if (_train) {
      return Container(
        width: s * 1.15,
        height: s * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: filled ? _wagonColors[i % 5] : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: filled ? Colors.white : Colors.black26, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: s * 0.45, fontWeight: FontWeight.w900, color: filled ? Colors.white : Colors.black26)),
      );
    }
    return Container(
      width: s,
      height: s,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _ballColors[i % 5] : Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: filled ? Colors.white : Colors.black26, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: s * 0.45, fontWeight: FontWeight.w900, color: filled ? Colors.white : Colors.black26)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return GameScaffold(
      id: 'order',
      color: _train ? const Color(0xFFB3E5FC) : const Color(0xFFDCEDC8),
      hills: true,
      onSpeak: _ask,
      title: _train ? (hi ? '1 2 3 ट्रेन' : '1 2 3 Train') : (hi ? 'अ आ इ इल्ली' : 'A B C Caterpillar'),
      child: LayoutBuilder(builder: (context, box) {
        final s = min(box.maxWidth / 7.2, 70.0);
        return Column(children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _walk,
              builder: (_, child) {
                final v = _walk.value;
                final dx = v == 0 ? 0.0 : (v < 0.5 ? v * 2 : (1 - v) * 2) * box.maxWidth * 0.15;
                final dy = sin(v * pi * 10) * 6;
                return Transform.translate(offset: Offset(dx, dy), child: child);
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  if (_train) ...[
                    for (var i = _seq.length - 1; i >= 0; i--) _segment(i, s),
                    Text('🚂', style: TextStyle(fontSize: s * 1.3)),
                  ] else ...[
                    for (var i = _seq.length - 1; i >= 0; i--) _segment(i, s),
                    Container(
                      width: s * 1.2,
                      height: s * 1.2,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7CB342)),
                      alignment: Alignment.center,
                      child: Text(_next == _seq.length ? '😄' : '🙂', style: TextStyle(fontSize: s * 0.75)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center, children: [
                for (final v in _tray)
                  GestureDetector(
                    onTap: () => _tap(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      height: 90,
                      transform: Matrix4.translationValues(_wrong == v ? 8 : 0, 0, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _wrong == v ? Colors.orange : const Color(0xFF7CB342), width: 5),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: Text(v, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF33691E))),
                    ),
                  ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}
