import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

/// One big item at a time. Tap → bounce, stars, name and sound. Swipe for next.
class ExploreScreen extends StatefulWidget {
  final Category category;
  const ExploreScreen({super.key, required this.category});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  int _i = 0;
  int _counted = 0;
  int _taps = 0;
  Mood _mood = Mood.idle;
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  LearnItem get item => widget.category.items[_i];
  bool get calm => AppState.I.calm;
  bool get hi => AppState.I.hindi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _bounce.dispose();
    _burst.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _speak() {
    if (item.count > 0) {
      Audio.I.say([item.label!, item.name(hi)]);
    } else {
      final snd = item.sound(hi);
      Audio.I.say([item.name(hi), if (snd != null) snd]);
    }
  }

  void _happy() {
    setState(() => _mood = Mood.happy);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _mood = Mood.idle);
    });
  }

  void _tap() {
    HapticFeedback.lightImpact();
    Audio.I.fx('chime');
    if (!calm) {
      _bounce.forward(from: 0);
      _burst.forward(from: 0);
    }
    _happy();
    _taps++;
    Future.delayed(const Duration(milliseconds: 300), _speak);
    // Exploring 8 things in a row earns a sticker.
    if (_taps % 8 == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) celebrate(context);
      });
    }
  }

  void _countTap(int idx) {
    if (idx != _counted) return;
    HapticFeedback.selectionClick();
    Audio.I.note(_counted % 8);
    setState(() => _counted++);
    Audio.I.say([hi ? numberWordsHi[_counted - 1] : numberWordsEn[_counted - 1]]);
    if (_counted == item.count) {
      _happy();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) celebrate(context, sticker: item.count >= 3);
      });
    }
  }

  void _go(int d) {
    final n = widget.category.items.length;
    setState(() {
      _i = (_i + d + n) % n;
      _counted = 0;
    });
    Audio.I.fx('whoosh');
    Future.delayed(const Duration(milliseconds: 250), _speak);
  }

  Widget _counting(double w) {
    final n = item.count;
    final emojiSize = n <= 3 ? w * 0.2 : (n <= 6 ? w * 0.15 : w * 0.12);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(item.label!, style: TextStyle(fontSize: w * 0.26, fontWeight: FontWeight.w900, color: darker(item.color))),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (var k = 0; k < n; k++)
          GestureDetector(
            onTap: () => _countTap(k),
            child: AnimatedScale(
              scale: k < _counted ? 1.18 : 1,
              duration: const Duration(milliseconds: 250),
              child: Stack(alignment: Alignment.center, children: [
                AnimatedOpacity(
                  opacity: k < _counted ? 1 : 0.5,
                  duration: const Duration(milliseconds: 250),
                  child: Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
                ),
                if (k < _counted)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Text('${k + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      if (_counted == 0)
        Text(hi ? '👆 छू कर गिनो' : '👆 Tap to count',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black45)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final word = item.name(hi);
    final snd = item.sound(hi);
    return GameScaffold(
      id: widget.category.id,
      color: item.color == Colors.white ? const Color(0xFFE0E0E0) : item.color,
      onSpeak: _speak,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Mascot(kind: MascotKind.chiku, mood: _mood, size: 60),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() > 200) _go(v < 0 ? 1 : -1);
        },
        child: Column(children: [
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
                          final b = sin(_bounce.value * pi);
                          final idle = calm ? 0.0 : _idle.value * 8;
                          // squash & stretch
                          return Transform.translate(
                            offset: Offset(0, -idle - b * 30),
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.diagonal3Values(1 + b * 0.12, 1 + b * 0.18, 1),
                              child: child,
                            ),
                          );
                        },
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: calm ? 0 : 350),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: KeyedSubtree(key: ValueKey(_i), child: ItemPicture(item: item, size: size)),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
          Text(word,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: darker(item.color))),
          if (snd != null)
            Text(snd, style: const TextStyle(fontSize: 24, color: Colors.black54, fontWeight: FontWeight.w700)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              RoundBtn(icon: Icons.arrow_back_rounded, semantic: 'Previous', onTap: () => _go(-1), size: 70),
              Text('${_i + 1} / ${widget.category.items.length}',
                  style: const TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.w800)),
              RoundBtn(icon: Icons.arrow_forward_rounded, semantic: 'Next', onTap: () => _go(1), size: 70),
            ]),
          ),
        ]),
      ),
    );
  }
}
