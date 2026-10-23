import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/season.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import 'explore.dart';
import 'games_a.dart';
import 'games_b.dart';
import 'parent.dart';
import 'stickers.dart';
import 'tracing.dart';

/// Everything a child can open from the map.
class Activity {
  final String id, en, hi, emoji;
  final Color color;
  final AgeMode minAge;
  final Widget Function() build;
  const Activity(this.id, this.en, this.hi, this.emoji, this.color, this.minAge, this.build);
}

Category _cat(String id) => learnCategories.firstWhere((c) => c.id == id);

final List<Activity> allActivities = [
  Activity('animals', 'Animals', 'जानवर', '🐄', const Color(0xFFFFB74D), AgeMode.baby, () => ExploreScreen(category: _cat('animals'))),
  Activity('bubbles', 'Bubbles', 'बुलबुले', '🫧', const Color(0xFF4FC3F7), AgeMode.baby, () => const BubbleScreen()),
  Activity('piano', 'Piano', 'पियानो', '🎹', const Color(0xFFBA68C8), AgeMode.baby, () => const PianoScreen()),
  Activity('fruits', 'Fruits', 'फल', '🍎', const Color(0xFFE57373), AgeMode.baby, () => ExploreScreen(category: _cat('fruits'))),
  Activity('doorbell', 'Who is it?', 'कौन है?', '🚪', const Color(0xFFFF8A65), AgeMode.baby, () => const DoorbellScreen()),
  Activity('draw', 'Magic Draw', 'जादू ड्रॉ', '🖍️', const Color(0xFF4DD0E1), AgeMode.baby, () => const FreeDrawScreen()),
  Activity('colors', 'Colors', 'रंग', '🎨', const Color(0xFFF06292), AgeMode.baby, () => ExploreScreen(category: _cat('colors'))),
  Activity('vehicles', 'Vehicles', 'गाड़ियाँ', '🚗', const Color(0xFF81C784), AgeMode.baby, () => ExploreScreen(category: _cat('vehicles'))),
  Activity('splash', 'Color Fill', 'रंग भरो', '🖌️', const Color(0xFFFFB74D), AgeMode.baby, () => const ColorSplashScreen()),
  Activity('shapes', 'Shapes', 'आकार', '⭐', const Color(0xFFFFCA28), AgeMode.baby, () => ExploreScreen(category: _cat('shapes'))),
  Activity('abc', 'ABC', 'ABC', '🔤', const Color(0xFF64B5F6), AgeMode.baby, () => ExploreScreen(category: _cat('abc'))),
  Activity('numbers', '123', 'गिनती', '🔢', const Color(0xFF4DB6AC), AgeMode.baby, () => ExploreScreen(category: _cat('numbers'))),
  Activity('swar', 'अ आ इ', 'स्वर', 'अ', const Color(0xFFBA68C8), AgeMode.baby, () => ExploreScreen(category: _cat('swar'))),
  Activity('findit', 'Find It', 'ढूँढो', '🔎', const Color(0xFF9575CD), AgeMode.toddler, () => const FindItScreen()),
  Activity('catch', 'Catch It', 'पकड़ो', '🧺', const Color(0xFF8BC34A), AgeMode.toddler, () => const CatchScreen()),
  Activity('puzzle', 'Puzzle', 'पहेली', '🧩', const Color(0xFFFF7043), AgeMode.toddler, () => const PuzzleScreen()),
  Activity('trace', 'Tracing', 'लिखो', '✏️', const Color(0xFF42A5F5), AgeMode.toddler, () => const TracingMenuScreen()),
  Activity('vyanjan', 'क ख ग', 'व्यंजन', 'क', const Color(0xFF9575CD), AgeMode.toddler, () => ExploreScreen(category: _cat('vyanjan'))),
  Activity('order', 'Caterpillar', 'इल्ली ट्रेन', '🐛', const Color(0xFF9CCC65), AgeMode.preschool, () => const OrderScreen()),
];

List<Activity> visibleActivities() => allActivities
    .where((a) => a.minAge.index <= AppState.I.age.index && !AppState.I.disabledGames.contains(a.id))
    .toList();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  Mood _golu = Mood.wave;
  Mood _chiku = Mood.idle;
  late String _bubble;

  @override
  void initState() {
    super.initState();
    _bubble = seasonGreeting(currentSeason(), AppState.I.hindi);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Audio.I.refreshMusic();
      Audio.I.say([_bubble]);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _golu = Mood.idle);
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _open(Activity a) async {
    Audio.I.fx('whoosh');
    HapticFeedback.lightImpact();
    final hi = AppState.I.hindi;
    Audio.I.say([hi ? a.hi : a.en]);
    await Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: AppState.I.calm ? 0 : 450),
      pageBuilder: (_, __, ___) => a.build(),
      transitionsBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    ));
    if (mounted) setState(() => _chiku = Mood.happy);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _chiku = Mood.idle);
    });
  }

  void _tapMascot(MascotKind k) {
    final hi = AppState.I.hindi;
    setState(() {
      if (k == MascotKind.golu) {
        _golu = Mood.happy;
        _bubble = hi ? 'मैं हूँ गोलू हाथी!' : "I'm Golu the elephant!";
      } else {
        _chiku = Mood.happy;
        _bubble = hi ? 'मैं हूँ चीकू चिड़िया!' : "I'm Chiku the bird! Tweet!";
      }
    });
    Audio.I.fx('boing');
    Audio.I.say([_bubble]);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _golu = Mood.idle;
          _chiku = Mood.idle;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final hi = AppState.I.hindi;
        final acts = visibleActivities();
        return Scaffold(
          body: SceneBackground(
            hills: false,
            child: SafeArea(
              child: Column(children: [
                _topBar(hi),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    Mascot(kind: MascotKind.golu, mood: _golu, size: 92, onTap: () => _tapMascot(MascotKind.golu)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Text(_bubble,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5D4037))),
                      ),
                    ),
                    Mascot(kind: MascotKind.chiku, mood: _chiku, size: 80, onTap: () => _tapMascot(MascotKind.chiku)),
                  ]),
                ),
                Expanded(child: _map(acts, hi)),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(bool hi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Row(children: [
        Text(hi ? 'चलो सीखें' : 'Kids Learning',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
        const Spacer(),
        _pill(
          child: Text(hi ? 'अ' : 'A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE64A19))),
          label: 'Switch language',
          onTap: () {
            AppState.I.update(() => AppState.I.hindi = !hi);
            Audio.I.say([AppState.I.hindi ? 'हिंदी' : 'English']);
            setState(() => _bubble = seasonGreeting(currentSeason(), AppState.I.hindi));
          },
        ),
        const SizedBox(width: 8),
        _pill(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('📒', style: TextStyle(fontSize: 22)),
            if (AppState.I.unplacedStickers > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                child: Text('${AppState.I.unplacedStickers}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ]),
          label: 'Sticker book',
          onTap: () {
            Audio.I.fx('whoosh');
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StickerBookScreen()));
          },
        ),
        const SizedBox(width: 8),
        _pill(
          child: const Icon(Icons.lock_outline, color: Colors.black45),
          label: 'Parents',
          onTap: () async {
            if (await parentGate(context) && mounted) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentScreen()));
            }
          },
        ),
      ]),
    );
  }

  Widget _pill({required Widget child, required String label, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: child,
        ),
      ),
    );
  }

  /// A winding path with round "stops" — like a little world map.
  Widget _map(List<Activity> acts, bool hi) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      const gap = 150.0;
      final stopSize = min(120.0, w * 0.3);
      final height = acts.length * gap + 120;
      final points = <Offset>[
        for (var i = 0; i < acts.length; i++)
          Offset(w * (0.5 + 0.28 * sin(i * 1.15)), 80 + i * gap),
      ];
      return SingleChildScrollView(
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter(points, currentSeason()))),
            for (var i = 0; i < acts.length; i++)
              Positioned(
                left: points[i].dx - stopSize / 2,
                top: points[i].dy - stopSize / 2,
                child: AnimatedBuilder(
                  animation: _bob,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, AppState.I.calm ? 0 : sin((_bob.value + i * 0.13) * 2 * pi) * 5),
                    child: child,
                  ),
                  child: _Stop(activity: acts[i], size: stopSize, hindi: hi, onTap: () => _open(acts[i])),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _Stop extends StatelessWidget {
  final Activity activity;
  final double size;
  final bool hindi;
  final VoidCallback onTap;
  const _Stop({required this.activity, required this.size, required this.hindi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLetter = activity.emoji.runes.first >= 0x0900 && activity.emoji.runes.first <= 0x097F;
    return Semantics(
      button: true,
      label: hindi ? activity.hi : activity.en,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size + 30,
          child: Column(children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [Color.lerp(activity.color, Colors.white, 0.35)!, activity.color],
                ),
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: [BoxShadow(color: activity.color.withValues(alpha: 0.55), blurRadius: 14, offset: const Offset(0, 7))],
              ),
              alignment: Alignment.center,
              child: Text(activity.emoji,
                  style: TextStyle(
                      fontSize: size * 0.45,
                      color: Colors.white,
                      fontWeight: isLetter ? FontWeight.w900 : null,
                      shadows: isLetter ? const [Shadow(color: Colors.black26, blurRadius: 4)] : null)),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text(hindi ? activity.hi : activity.en,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darker(activity.color))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<Offset> pts;
  final Season season;
  _MapPainter(this.pts, this.season);

  @override
  void paint(Canvas canvas, Size s) {
    // grassy islands under the stops
    final grass = Paint()..color = (season == Season.winter ? Colors.white : const Color(0xFFA5D6A7)).withValues(alpha: 0.7);
    for (final p in pts) {
      canvas.drawOval(Rect.fromCenter(center: p.translate(0, 58), width: 150, height: 34), grass);
    }
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFE0B2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.round);
    // dashes
    final dash = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 28) {
        canvas.drawPath(m.extractPath(d, d + 12), dash);
      }
    }
    // decorations
    final deco = season == Season.winter
        ? ['⛄', '🌲']
        : season == Season.diwali
            ? ['🪔', '🌼']
            : ['🌳', '🌷', '🍄', '🌻'];
    for (var i = 0; i < pts.length; i++) {
      final left = pts[i].dx > s.width / 2;
      final tp = TextPainter(
          text: TextSpan(text: deco[i % deco.length], style: const TextStyle(fontSize: 30)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(left ? 14 : s.width - 50, pts[i].dy + 20));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => o.pts.length != pts.length;
}
