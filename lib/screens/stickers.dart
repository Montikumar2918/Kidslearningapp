import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/settings.dart';
import '../widgets/common.dart';

class _Scene {
  final String en, hi;
  final List<Color> sky;
  final Color ground;
  final List<String> deco;
  const _Scene(this.en, this.hi, this.sky, this.ground, this.deco);
}

const _scenes = [
  _Scene('Farm', 'खेत', [Color(0xFF81D4FA), Color(0xFFE1F5FE)], Color(0xFF9CCC65), ['🏡', '🌳', '🌻']),
  _Scene('Jungle', 'जंगल', [Color(0xFFA5D6A7), Color(0xFFE8F5E9)], Color(0xFF558B2F), ['🌴', '🌿', '🍄']),
  _Scene('Sea', 'समुद्र', [Color(0xFF4FC3F7), Color(0xFF0277BD)], Color(0xFFFFE082), ['🪸', '🐚', '🌊']),
  _Scene('Space', 'आसमान', [Color(0xFF1A237E), Color(0xFF5C6BC0)], Color(0xFF9FA8DA), ['🌙', '🪐', '✨']),
];

/// Earned stickers can be dragged onto four scenes. Saved on the phone.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});
  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> {
  int _scene = 0;
  final GlobalKey _sceneKey = GlobalKey();

  /// Stickers earned but not yet placed (most recent last).
  List<String> get _available {
    final st = AppState.I;
    final earned = [for (var i = 0; i < st.stickers; i++) stickerPool[i % stickerPool.length]];
    for (final p in st.placed) {
      earned.remove(p.emoji);
    }
    return earned;
  }

  void _place(String emoji, Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final x = (local.dx / box.size.width).clamp(0.05, 0.95);
    final y = (local.dy / box.size.height).clamp(0.05, 0.95);
    HapticFeedback.mediumImpact();
    Audio.I.fx('pop');
    AppState.I.update(() => AppState.I.placed.add(PlacedSticker(emoji, x, y, _scene)));
  }

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final sc = _scenes[_scene];
        final avail = _available;
        return GameScaffold(
          id: 'stickers',
          color: const Color(0xFFFFF59D),
          title: hi ? 'मेरी स्टिकर बुक' : 'My Sticker Book',
          child: Column(children: [
            SizedBox(
              height: 60,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
                for (var i = 0; i < _scenes.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ChoiceChip(
                      label: Text('${_scenes[i].deco.first} ${hi ? _scenes[i].hi : _scenes[i].en}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      selected: _scene == i,
                      onSelected: (_) {
                        setState(() => _scene = i);
                        Audio.I.fx('whoosh');
                      },
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DragTarget<String>(
                  onAcceptWithDetails: (d) => _place(d.data, d.offset + const Offset(36, 36)),
                  builder: (_, __, ___) => ClipRRect(
                    key: _sceneKey,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sc.sky),
                      ),
                      child: LayoutBuilder(builder: (context, box) {
                        final w = box.maxWidth, h = box.maxHeight;
                        return Stack(children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: h * 0.25,
                            child: Container(
                              decoration: BoxDecoration(
                                color: sc.ground,
                                borderRadius: const BorderRadius.vertical(top: Radius.elliptical(300, 40)),
                              ),
                            ),
                          ),
                          for (var i = 0; i < sc.deco.length; i++)
                            Positioned(
                              left: w * (0.08 + i * 0.36),
                              top: i == 1 ? h * 0.1 : h * 0.62,
                              child: Opacity(opacity: 0.85, child: Text(sc.deco[i], style: const TextStyle(fontSize: 54))),
                            ),
                          for (final p in AppState.I.placed.where((p) => p.scene == _scene))
                            Positioned(
                              left: p.x * w - 30,
                              top: p.y * h - 30,
                              child: GestureDetector(
                                onTap: () => Audio.I.fx('boing'),
                                child: Text(p.emoji, style: const TextStyle(fontSize: 52)),
                              ),
                            ),
                          if (AppState.I.placed.where((p) => p.scene == _scene).isEmpty)
                            Center(
                              child: Text(hi ? 'स्टिकर यहाँ खींचो 👇' : 'Drag stickers here 👇',
                                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800,
                                      shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
                            ),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 110,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: avail.isEmpty
                  ? Center(
                      child: Text(hi ? 'खेलो और स्टिकर जीतो! 🎁' : 'Play games to win stickers! 🎁',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black54)))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(10),
                      children: [
                        for (final e in avail.reversed)
                          Draggable<String>(
                            data: e,
                            feedback: Material(color: Colors.transparent, child: Text(e, style: const TextStyle(fontSize: 64))),
                            childWhenDragging: Opacity(opacity: 0.3, child: _sticker(e)),
                            onDragStarted: () => Audio.I.fx('tick'),
                            child: _sticker(e),
                          ),
                      ],
                    ),
            ),
          ]),
        );
      },
    );
  }

  Widget _sticker(String e) => Container(
        width: 84,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFCA28), width: 3),
        ),
        alignment: Alignment.center,
        child: Text(e, style: const TextStyle(fontSize: 48)),
      );
}
