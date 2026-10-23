import 'dart:math';

import 'package:flutter/material.dart';

/// Soft, calm two-colour background used on every screen.
class SoftBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const SoftBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.55)!, Color.lerp(color, Colors.white, 0.85)!],
        ),
      ),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _CloudPainter())),
        child,
      ]),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void cloud(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, p);
      canvas.drawCircle(Offset(x + r * 0.9, y + r * 0.2), r * 0.8, p);
      canvas.drawCircle(Offset(x - r * 0.9, y + r * 0.25), r * 0.7, p);
    }

    cloud(s.width * 0.18, s.height * 0.08, 26);
    cloud(s.width * 0.82, s.height * 0.16, 20);
    cloud(s.width * 0.7, s.height * 0.92, 30);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Draws simple flat shapes for the Shapes category.
class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;
  ShapePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);
    final fill = Paint()..color = color;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final path = Path();
    switch (shape) {
      case 'circle':
        path.addOval(Rect.fromCircle(center: c, radius: s * 0.42));
      case 'square':
        path.addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: s * 0.78, height: s * 0.78), const Radius.circular(18)));
      case 'rectangle':
        path.addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: s * 0.9, height: s * 0.55), const Radius.circular(18)));
      case 'triangle':
        path
          ..moveTo(c.dx, c.dy - s * 0.42)
          ..lineTo(c.dx + s * 0.45, c.dy + s * 0.36)
          ..lineTo(c.dx - s * 0.45, c.dy + s * 0.36)
          ..close();
      case 'star':
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? s * 0.46 : s * 0.2;
          final a = -pi / 2 + i * pi / 5;
          final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
      case 'heart':
        final w = s * 0.85;
        path
          ..moveTo(c.dx, c.dy + w * 0.38)
          ..cubicTo(c.dx - w * 0.6, c.dy - w * 0.05, c.dx - w * 0.3, c.dy - w * 0.55, c.dx, c.dy - w * 0.2)
          ..cubicTo(c.dx + w * 0.3, c.dy - w * 0.55, c.dx + w * 0.6, c.dy - w * 0.05, c.dx, c.dy + w * 0.38)
          ..close();
    }
    canvas.drawPath(path.shift(const Offset(0, 8)), shadow);
    canvas.drawPath(path, fill);
    // friendly face
    final eye = Paint()..color = Colors.black87;
    canvas.drawCircle(c.translate(-s * 0.09, -s * 0.03), s * 0.03, eye);
    canvas.drawCircle(c.translate(s * 0.09, -s * 0.03), s * 0.03, eye);
    canvas.drawArc(Rect.fromCenter(center: c.translate(0, s * 0.04), width: s * 0.16, height: s * 0.12), 0.2,
        pi - 0.4, false, eye..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant ShapePainter old) => old.shape != shape || old.color != color;
}

/// Stars that burst out after a tap — gentle reward, no flashing.
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
      final o = c + Offset(cos(a) * d, sin(a) * d);
      _star(canvas, o, 14 * (1 - v * 0.5), p);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(c.dx + rr * cos(a), c.dy + rr * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.v != v;
}

/// Big round button used for home / next / previous.
class RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String semantic;
  const RoundBtn({super.key, required this.icon, required this.onTap, required this.semantic, this.color = Colors.white});

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
          onTap: onTap,
          child: SizedBox(width: 68, height: 68, child: Icon(icon, size: 38, color: Colors.black54)),
        ),
      ),
    );
  }
}
