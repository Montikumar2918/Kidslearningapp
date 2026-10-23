import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

/// Every 5 stickers = 1 present. Tap the present 3 times to unwrap a toy.
/// Toys live on the Toy Shelf and bounce + play a note when tapped.
class ToyRoomScreen extends StatefulWidget {
  const ToyRoomScreen({super.key});
  @override
  State<ToyRoomScreen> createState() => _ToyRoomScreenState();
}

class _ToyRoomScreenState extends State<ToyRoomScreen> with TickerProviderStateMixin {
  int _taps = 0;
  String? _revealed;
  int? _bounce;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _shake.dispose();
    _open.dispose();
    super.dispose();
  }

  void _tapPresent() {
    if (AppState.I.presents == 0 || _revealed != null) return;
    HapticFeedback.mediumImpact();
    _taps++;
    if (_taps < 3) {
      Audio.I.fx('boing');
      if (!AppState.I.calm) _shake.forward(from: 0);
      Audio.I.say([_taps == 1 ? 'Shake shake!' : 'One more time!']);
      setState(() {});
      return;
    }
    final toy = AppState.I.openPresent(Random().nextInt(100));
    setState(() {
      _revealed = toy;
      _taps = 0;
    });
    Audio.I.fx('yay');
    _open.forward(from: 0);
    Audio.I.say([AppState.I.hindi ? 'नया खिलौना!' : 'A new toy for you!']);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _revealed = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final toNext = 5 - s.stickers % 5;
        return GameScaffold(
          id: 'toys',
          color: const Color(0xFFF8BBD0),
          title: hi ? 'खिलौना घर' : 'Toy Room',
          child: Column(children: [
            Expanded(
              flex: 5,
              child: Center(
                child: _revealed != null
                    ? AnimatedBuilder(
                        animation: _open,
                        builder: (_, child) => Transform.scale(
                          scale: Curves.elasticOut.transform(_open.value),
                          child: Transform.rotate(angle: (1 - _open.value) * 2, child: child),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_revealed!, style: const TextStyle(fontSize: 150)),
                          const Text('✨ 🎉 ✨', style: TextStyle(fontSize: 40)),
                        ]),
                      )
                    : s.presents > 0
                        ? GestureDetector(
                            onTap: _tapPresent,
                            child: AnimatedBuilder(
                              animation: _shake,
                              builder: (_, child) =>
                                  Transform.rotate(angle: sin(_shake.value * pi * 4) * 0.15, child: child),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                CustomPaint(size: const Size(190, 190), painter: _PresentPainter(_taps)),
                                const SizedBox(height: 10),
                                Text(hi ? '🎁 x${s.presents}  — छूओ!' : '🎁 x${s.presents}  — tap to open!',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                              ]),
                            ),
                          )
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            const Mascot(kind: MascotKind.golu, mood: Mood.wave, size: 140),
                            const SizedBox(height: 10),
                            Text(hi ? '$toNext स्टिकर और = 🎁' : '$toNext more stickers = 🎁',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                          ]),
              ),
            ),
            // shelf
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7CCC8),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 6),
                ),
                child: s.toys.isEmpty
                    ? Center(
                        child: Text(hi ? 'खिलौने यहाँ आएँगे' : 'Your toys will live here',
                            style: const TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.w700)))
                    : GridView.count(
                        crossAxisCount: 5,
                        children: [
                          for (var i = 0; i < s.toys.length; i++)
                            GestureDetector(
                              onTap: () {
                                setState(() => _bounce = i);
                                Audio.I.note(i % 8);
                                Future.delayed(const Duration(milliseconds: 400), () {
                                  if (mounted) setState(() => _bounce = null);
                                });
                              },
                              child: AnimatedSlide(
                                offset: Offset(0, _bounce == i ? -0.3 : 0),
                                duration: const Duration(milliseconds: 200),
                                child: FittedBox(child: Text(s.toys[i], style: const TextStyle(fontSize: 44))),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _PresentPainter extends CustomPainter {
  final int taps;
  _PresentPainter(this.taps);
  @override
  void paint(Canvas canvas, Size s) {
    final box = Rect.fromLTWH(s.width * 0.1, s.height * 0.35, s.width * 0.8, s.height * 0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(12)), Paint()..color = const Color(0xFFE53935));
    final lidLift = taps * 6.0;
    final lid = Rect.fromLTWH(s.width * 0.04, s.height * 0.24 - lidLift, s.width * 0.92, s.height * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(10)), Paint()..color = const Color(0xFFEF5350));
    final ribbon = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawRect(Rect.fromLTWH(s.width * 0.44, box.top, s.width * 0.12, box.height), ribbon);
    canvas.drawRect(Rect.fromLTWH(s.width * 0.44, lid.top, s.width * 0.12, lid.height), ribbon);
    // bow
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width * 0.38, lid.top - 12), width: 50, height: 30), ribbon);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width * 0.62, lid.top - 12), width: 50, height: 30), ribbon);
    canvas.drawCircle(Offset(s.width * 0.5, lid.top - 10), 12, Paint()..color = const Color(0xFFFFA000));
  }

  @override
  bool shouldRepaint(covariant _PresentPainter o) => o.taps != taps;
}

// ═════════════════════════════ Report Card (Teacher Mode) ═════════════════════════════

class ReportCardScreen extends StatelessWidget {
  const ReportCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    var right = 0, wrong = 0;
    for (final v in s.letterStats.values) {
      right += v[0];
      wrong += v[1];
    }
    final total = right + wrong;
    final needPractice = [
      for (final l in letters)
        if ((s.letterStats[l]?[1] ?? 0) > 0 &&
            (s.letterStats[l]![0] / (s.letterStats[l]![0] + s.letterStats[l]![1])) < 0.7)
          l
    ];
    final tracedCaps = letters.where(s.traced.contains).length;
    final tracedSmall = letters.where((l) => s.traced.contains(l.toLowerCase())).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Card'), backgroundColor: const Color(0xFFC5E1A5)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          _tile('🎯', total == 0 ? '–' : '${(right * 100 / total).round()}%', 'letter accuracy'),
          _tile('✍️', '$tracedCaps/26', 'ABC traced'),
          _tile('✏️', '$tracedSmall/26', 'abc traced'),
          _tile('⏱️', '${s.totalMinutes}', 'minutes'),
        ]),
        const SizedBox(height: 16),
        const Text('Letters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Text('Green = strong, yellow = learning, red = needs practice, grey = not tried yet.  ✓ = traced',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final l in letters)
              Builder(builder: (_) {
                final v = s.letterStats[l];
                final n = v == null ? 0 : v[0] + v[1];
                final acc = n == 0 ? -1.0 : v![0] / n;
                final c = acc < 0
                    ? Colors.grey.shade300
                    : acc >= 0.8
                        ? const Color(0xFFA5D6A7)
                        : acc >= 0.5
                            ? const Color(0xFFFFF59D)
                            : const Color(0xFFEF9A9A);
                return Container(
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$l${s.traced.contains(l) ? '✓' : ''}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text(n == 0 ? '' : '${(acc * 100).round()}%', style: const TextStyle(fontSize: 11)),
                  ]),
                );
              }),
          ],
        ),
        const SizedBox(height: 16),
        if (needPractice.isNotEmpty) ...[
          const Text('Practise next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(needPractice.join('  '), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.red)),
          const SizedBox(height: 16),
        ],
        const Text('Hindi traced', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(
            s.traced.where((l) => l.runes.any((r) => r >= 0x0900 && r <= 0x097F)).join('  ').ifEmpty('None yet'),
            style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 16),
        Text('Stickers: ${s.stickers}    Toys: ${s.toys.length}', style: const TextStyle(fontSize: 16)),
      ]),
    );
  }

  Widget _tile(String e, String v, String l) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text(e, style: const TextStyle(fontSize: 24)),
              Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ),
        ),
      );
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
