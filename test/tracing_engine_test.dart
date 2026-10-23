import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_app/core/strokes.dart';
import 'package:kids_learning_app/core/tracing_engine.dart';

bool trace(TraceEngine e, List<List<Offset>> paths) {
  for (final p in paths) {
    e.down(p.first);
    for (final q in p.skip(1)) {
      e.move(q);
    }
    e.up();
  }
  return e.done;
}

void main() {
  final letters = strokes.keys.toList();

  test('a careful child tracing every stroke completes every letter', () {
    for (final l in letters) {
      expect(trace(TraceEngine(strokes[l]!), strokes[l]!), isTrue, reason: l);
    }
  });

  test('a slightly wobbly trace (offset within tolerance) still passes', () {
    for (final l in letters) {
      final wobbly = [for (final s in strokes[l]!) [for (final p in s) p + const Offset(0.05, 0.04)]];
      expect(trace(TraceEngine(strokes[l]!), wobbly), isTrue, reason: l);
    }
  });

  test('drawing strokes backwards does not complete the letter', () {
    for (final l in letters) {
      final rev = [for (final s in strokes[l]!) s.reversed.toList()];
      expect(trace(TraceEngine(strokes[l]!), rev), isFalse, reason: l);
    }
  });

  test('strokes in the wrong order do not complete multi-stroke letters', () {
    for (final l in letters.where((l) => strokes[l]!.length > 1)) {
      expect(trace(TraceEngine(strokes[l]!), strokes[l]!.reversed.toList()), isFalse, reason: l);
    }
  });

  test('random scribbles do not complete multi-stroke letters', () {
    final rnd = Random(42);
    for (final l in ['A', 'B', 'E', 'H', 'M', 'k', '4']) {
      final scribble = [
        for (var i = 0; i < strokes[l]!.length; i++) [for (var k = 0; k < 60; k++) Offset(rnd.nextDouble(), rnd.nextDouble())]
      ];
      expect(trace(TraceEngine(strokes[l]!), scribble), isFalse, reason: l);
    }
  });

  test('starting far from the green dot is reported, not accepted', () {
    final e = TraceEngine(strokes['T']!);
    expect(e.down(const Offset(0.5, 0.9)), TraceEvent.wrongStart);
    expect(e.move(const Offset(0.6, 0.12)), TraceEvent.none);
  });

  test('going off the path gives an offTrack event and progress stays', () {
    final e = TraceEngine(strokes['L']!);
    e.down(strokes['L']!.first.first);
    e.move(strokes['L']!.first[3]);
    final before = e.progress;
    expect(e.move(const Offset(0.9, 0.1)), TraceEvent.offTrack);
    expect(e.progress, before);
  });

  test('age modes are more forgiving for younger children', () {
    expect(TraceEngine.forAge(strokes['A']!, 0).tolerance, greaterThan(TraceEngine.forAge(strokes['A']!, 2).tolerance));
  });
}
