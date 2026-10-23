import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'data.dart';
import 'settings.dart';
import 'widgets.dart';

// ───────────────────────────── HOME ─────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Audio.I.say([Settings.I.hindi ? 'नमस्ते! चलो खेलें!' : "Hello! Let's play!"]));
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Audio.I.fx('pop');
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final hi = Settings.I.hindi;
    final cards = <Widget>[
      for (final c in categories)
        _CategoryCard(emoji: c.emoji, title: hi ? c.titleHi : c.title, color: c.color, onTap: () => _open(ExploreScreen(category: c))),
      _CategoryCard(emoji: '🫧', title: hi ? 'बुलबुले' : 'Bubbles', color: const Color(0xFF4FC3F7), onTap: () => _open(const BubbleScreen())),
      _CategoryCard(emoji: '🔎', title: hi ? 'ढूँढो' : 'Find It', color: const Color(0xFF9575CD), onTap: () => _open(const FindItScreen())),
    ];
    return Scaffold(
      body: SoftBackground(
        color: const Color(0xFFFFCC80),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(0, Settings.I.calm ? 0 : -6 * _float.value), child: child),
                  child: GestureDetector(
                    onTap: () => Audio.I.say([hi ? 'मैं हूँ भालू! नमस्ते!' : "I'm Teddy! Hello!"]),
                    child: const Text('🧸', style: TextStyle(fontSize: 56)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hi ? 'चलो सीखें!' : 'Kids Learning',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF6D4C41))),
                ),
                _LangToggle(hindi: hi),
                const SizedBox(width: 8),
                _ParentButton(),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final cols = box.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: cols,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: cards,
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji, title;
  final Color color;
  final VoidCallback onTap;
  const _CategoryCard({required this.emoji, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isText = emoji.runes.length == 1 && emoji.runes.first >= 0x0900 && emoji.runes.first <= 0x097F;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(32),
        elevation: 6,
        shadowColor: color.withValues(alpha: 0.6),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(emoji,
                      style: TextStyle(fontSize: 80, color: Colors.white, fontWeight: isText ? FontWeight.w900 : null)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, shadows: [
                    Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2)),
                  ])),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool hindi;
  const _LangToggle({required this.hindi});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Switch language',
      child: GestureDetector(
        onTap: () {
          Settings.I.update(() => Settings.I.hindi = !hindi);
          Audio.I.say([Settings.I.hindi ? 'हिंदी' : 'English']);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(hindi ? 'अ' : 'A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE64A19))),
        ),
      ),
    );
  }
}

/// Parent gate: a baby can't open settings – it needs a 3‑second press-and-hold.
class _ParentButton extends StatefulWidget {
  @override
  State<_ParentButton> createState() => _ParentButtonState();
}

class _ParentButtonState extends State<_ParentButton> {
  Timer? _t;
  double _progress = 0;

  void _start() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _progress += 50 / 3000);
      if (_progress >= 1) {
        _cancel();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentScreen()));
      }
    });
  }

  void _cancel() {
    _t?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Parents: press and hold for 3 seconds',
      child: GestureDetector(
        onLongPressStart: (_) => _start(),
        onLongPressEnd: (_) => _cancel(),
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Parents: press and hold the lock for 3 seconds'))),
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 48, height: 48, child: CircularProgressIndicator(value: _progress, strokeWidth: 4)),
          const Icon(Icons.lock_outline, color: Colors.black45, size: 28),
        ]),
      ),
    );
  }
}

// ──────────────────────── EXPLORE (one big item) ────────────────────────

class ExploreScreen extends StatefulWidget {
  final Category category;
  const ExploreScreen({super.key, required this.category});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  int _i = 0;
  int _counted = 0; // for numbers tap-to-count
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  LearnItem get item => widget.category.items[_i];
  bool get calm => Settings.I.calm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    Audio.I.stop();
    _bounce.dispose();
    _burst.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _speak() {
    final hi = Settings.I.hindi;
    final word = hi ? item.hi : item.en;
    final snd = hi ? item.soundHi : item.soundEn;
    if (item.count > 0) {
      Audio.I.say([item.label!, word]);
    } else {
      Audio.I.say([word, if (snd != null) snd]);
    }
  }

  void _tap() {
    HapticFeedback.lightImpact();
    Audio.I.fx('chime');
    if (!calm) {
      _bounce.forward(from: 0);
      _burst.forward(from: 0);
    }
    Future.delayed(const Duration(milliseconds: 350), _speak);
  }

  void _countTap(int idx) {
    if (idx != _counted) return; // count in order, left to right
    HapticFeedback.selectionClick();
    setState(() => _counted++);
    final hi = Settings.I.hindi;
    Audio.I.say([hi ? numberWordsHi[_counted - 1] : numberWordsEn[_counted - 1]]);
    if (_counted == item.count) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Audio.I.fx('yay');
        if (!calm) _burst.forward(from: 0);
      });
    }
  }

  void _go(int d) {
    final n = widget.category.items.length;
    setState(() {
      _i = (_i + d + n) % n;
      _counted = 0;
    });
    Audio.I.fx('pop');
    Future.delayed(const Duration(milliseconds: 250), _speak);
  }

  Widget _picture(double size) {
    if (widget.category.items == shapes) {
      return SizedBox(width: size, height: size, child: CustomPaint(painter: ShapePainter(item.emoji, item.color)));
    }
    if (widget.category.items == colorsList) {
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
        child: Text('😊', style: TextStyle(fontSize: size * 0.3)),
      );
    }
    if (item.label != null && item.count == 0) {
      // letters: big letter + picture
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Text(item.label!,
            style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: _darker(item.color), height: 1.1)),
        Text(item.emoji, style: TextStyle(fontSize: size * 0.35)),
      ]);
    }
    return Text(item.emoji, style: TextStyle(fontSize: size * 0.7));
  }

  Color _darker(Color c) => HSLColor.fromColor(c).withLightness(0.4).withSaturation(0.7).toColor();

  Widget _counting(double w) {
    final n = item.count;
    final emojiSize = n <= 3 ? w * 0.22 : (n <= 6 ? w * 0.16 : w * 0.13);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(item.label!, style: TextStyle(fontSize: w * 0.3, fontWeight: FontWeight.w900, color: _darker(item.color))),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var k = 0; k < n; k++)
            GestureDetector(
              onTap: () => _countTap(k),
              child: AnimatedScale(
                scale: k < _counted ? 1.15 : 1,
                duration: const Duration(milliseconds: 250),
                child: AnimatedOpacity(
                  opacity: k < _counted ? 1 : 0.55,
                  duration: const Duration(milliseconds: 250),
                  child: Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
                ),
              ),
            ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final hi = Settings.I.hindi;
    final word = hi ? item.hi : item.en;
    final snd = hi ? item.soundHi : item.soundEn;
    return Scaffold(
      body: SoftBackground(
        color: item.color,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() > 200) _go(v < 0 ? 1 : -1);
            },
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  RoundBtn(icon: Icons.home_rounded, semantic: 'Home', onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text('${_i + 1} / ${widget.category.items.length}',
                      style: const TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  RoundBtn(icon: Icons.volume_up_rounded, semantic: 'Say again', onTap: _speak),
                ]),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, box) {
                  final size = min(box.maxWidth, box.maxHeight) * 0.85;
                  return Stack(alignment: Alignment.center, children: [
                    StarBurst(t: _burst),
                    if (item.count > 0)
                      _counting(box.maxWidth)
                    else
                      Semantics(
                        button: true,
                        label: word,
                        child: GestureDetector(
                          onTap: _tap,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_bounce, _idle]),
                            builder: (_, child) {
                              final b = sin(_bounce.value * pi) * 0.18;
                              final idle = calm ? 0.0 : _idle.value * 8;
                              return Transform.translate(
                                offset: Offset(0, -idle),
                                child: Transform.scale(scale: 1 + b, child: child),
                              );
                            },
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: calm ? 0 : 350),
                              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                              child: KeyedSubtree(key: ValueKey(_i), child: _picture(size)),
                            ),
                          ),
                        ),
                      ),
                  ]);
                }),
              ),
              Text(word,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _darker(item.color))),
              if (snd != null)
                Text(snd, style: const TextStyle(fontSize: 24, color: Colors.black54, fontWeight: FontWeight.w700)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  RoundBtn(icon: Icons.arrow_back_rounded, semantic: 'Previous', color: Colors.white, onTap: () => _go(-1)),
                  RoundBtn(icon: Icons.arrow_forward_rounded, semantic: 'Next', color: Colors.white, onTap: () => _go(1)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── BUBBLES ─────────────────────────────
// Pure cause-and-effect: tap a floating bubble, it pops and names an animal/fruit.

class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});
  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _Bubble {
  double x, y, r, speed, wobble;
  LearnItem item;
  Color color;
  _Bubble(this.x, this.y, this.r, this.speed, this.wobble, this.item, this.color);
}

class _BubbleScreenState extends State<BubbleScreen> with SingleTickerProviderStateMixin {
  final _rnd = Random();
  final List<_Bubble> _bubbles = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  final _pool = [...animals, ...fruits];
  static const _cols = [Color(0xFF81D4FA), Color(0xFFF8BBD0), Color(0xFFC5E1A5), Color(0xFFFFE082), Color(0xFFCE93D8)];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    Audio.I.stop();
    super.dispose();
  }

  _Bubble _make({bool start = false}) {
    final r = 55.0 + _rnd.nextDouble() * 30;
    return _Bubble(
      r + _rnd.nextDouble() * max(1, _size.width - 2 * r),
      start ? _rnd.nextDouble() * _size.height : _size.height + r,
      r,
      (Settings.I.calm ? 25 : 45) + _rnd.nextDouble() * 30,
      _rnd.nextDouble() * pi * 2,
      _pool[_rnd.nextInt(_pool.length)],
      _cols[_rnd.nextInt(_cols.length)],
    );
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (_size == Size.zero || dt > 0.2) return;
    while (_bubbles.length < 5) {
      _bubbles.add(_make(start: _bubbles.isEmpty));
    }
    for (final b in _bubbles) {
      b.y -= b.speed * dt;
      b.wobble += dt * 1.5;
    }
    _bubbles.removeWhere((b) => b.y < -b.r);
    setState(() {});
  }

  void _pop(_Bubble b) {
    HapticFeedback.mediumImpact();
    Audio.I.fx('pop');
    final hi = Settings.I.hindi;
    final snd = hi ? b.item.soundHi : b.item.soundEn;
    Future.delayed(const Duration(milliseconds: 200),
        () => Audio.I.say([hi ? b.item.hi : b.item.en, if (snd != null) snd]));
    setState(() => _bubbles.remove(b));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        color: const Color(0xFF81D4FA),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            _size = box.biggest;
            return Stack(children: [
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
                          colors: [Colors.white.withValues(alpha: 0.9), b.color.withValues(alpha: 0.75)],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(b.item.emoji, style: TextStyle(fontSize: b.r * 0.9)),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                top: 16,
                child: RoundBtn(icon: Icons.home_rounded, semantic: 'Home', onTap: () => Navigator.of(context).pop()),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

// ───────────────────────────── FIND IT ─────────────────────────────
// Two big pictures, "Where is the cow?" — no losing, wrong tap just wiggles.

class FindItScreen extends StatefulWidget {
  const FindItScreen({super.key});
  @override
  State<FindItScreen> createState() => _FindItScreenState();
}

class _FindItScreenState extends State<FindItScreen> with TickerProviderStateMixin {
  final _rnd = Random();
  final _pool = [...animals, ...fruits, ...vehicles];
  late List<LearnItem> _choices;
  late LearnItem _target;
  int? _wrong;
  bool _done = false;
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _burst.dispose();
    Audio.I.stop();
    super.dispose();
  }

  void _newRound() {
    final a = _pool[_rnd.nextInt(_pool.length)];
    LearnItem b;
    do {
      b = _pool[_rnd.nextInt(_pool.length)];
    } while (b.en == a.en);
    _choices = [a, b]..shuffle(_rnd);
    _target = a;
    _wrong = null;
    _done = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  void _ask() {
    final hi = Settings.I.hindi;
    Audio.I.say([hi ? '${_target.hi} कहाँ है?' : 'Where is the ${_target.en}?']);
  }

  void _pick(int i) {
    if (_done) return;
    final hi = Settings.I.hindi;
    if (_choices[i] == _target) {
      setState(() => _done = true);
      HapticFeedback.mediumImpact();
      Audio.I.fx('yay');
      if (!Settings.I.calm) _burst.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), () => Audio.I.say([hi ? 'बहुत अच्छा!' : 'Yay! Well done!']));
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(_newRound);
      });
    } else {
      setState(() => _wrong = i);
      Audio.I.say([hi ? 'यह ${_choices[i].hi} है। फिर से ढूँढो!' : 'That is a ${_choices[i].en}. Try again!']);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = Settings.I.hindi;
    return Scaffold(
      body: SoftBackground(
        color: const Color(0xFFB39DDB),
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  RoundBtn(icon: Icons.home_rounded, semantic: 'Home', onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  RoundBtn(icon: Icons.volume_up_rounded, semantic: 'Say again', onTap: _ask),
                ]),
              ),
              Text(hi ? '${_target.hi} कहाँ है?' : 'Where is the ${_target.en}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF4527A0))),
              Expanded(
                child: Column(children: [
                  for (var i = 0; i < _choices.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () => _pick(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            transform: Matrix4.translationValues(_wrong == i ? 12 : 0, 0, 0),
                            decoration: BoxDecoration(
                              color: _done && _choices[i] == _target ? const Color(0xFFC8E6C9) : _choices[i].color,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                  color: _done && _choices[i] == _target ? Colors.green : Colors.white, width: 6),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(_choices[i].emoji, style: const TextStyle(fontSize: 120)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ]),
            Positioned.fill(child: StarBurst(t: _burst)),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────── PARENTS ─────────────────────────────

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Settings.I,
      builder: (context, _) {
        final s = Settings.I;
        return Scaffold(
          appBar: AppBar(title: const Text('Parents')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            SwitchListTile(
              title: const Text('Hindi words (हिंदी)'),
              subtitle: const Text('Speak and show names in Hindi'),
              value: s.hindi,
              onChanged: (v) => s.update(() => s.hindi = v),
            ),
            SwitchListTile(
              title: const Text('Calm mode'),
              subtitle: const Text('Less movement and no sparkle effects'),
              value: s.calm,
              onChanged: (v) => s.update(() => s.calm = v),
            ),
            SwitchListTile(
              title: const Text('Mute all sound'),
              value: s.muted,
              onChanged: (v) {
                s.update(() => s.muted = v);
                Audio.I.muted = v;
                if (v) Audio.I.stop();
              },
            ),
            if (!Audio.I.hindiVoiceOk)
              const Card(
                color: Color(0xFFFFF3E0),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                      'Hindi voice not found on this phone. Install it: Settings → System → Languages → Text-to-speech → Google → Install voice data → Hindi.'),
                ),
              ),
            const Divider(height: 32),
            const ListTile(
              leading: Icon(Icons.child_care),
              title: Text('Made for 0–2 years'),
              subtitle: Text(
                  'Use together with your child for short sessions (5–10 minutes). Name things you see in real life too — '
                  'screens work best as a shared activity, not a replacement for play and talk.'),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy'),
              subtitle: Text('Works fully offline. No internet, no ads, no accounts, no data collected or stored.'),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Kids Learning App'),
              subtitle: Text('Version 1.0.0'),
            ),
          ]),
        );
      },
    );
  }
}
