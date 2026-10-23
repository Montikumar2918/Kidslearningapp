import 'dart:math';
import 'dart:ui';

/// What happened after a touch event. The UI reacts to these (sounds, hints).
enum TraceEvent { none, started, wrongStart, onTrack, offTrack, wrongDirection, strokeDone, letterDone }

/// Child-friendly tracing validator. Pure Dart, no Flutter widgets, so it is unit-testable.
///
/// All coordinates are normalised (0..1) so the same letter works on any screen size.
/// Rules:
///  * strokes must be drawn in order (later strokes can't complete first);
///  * a stroke must start near its start point ([startRadius]);
///  * progress only moves forward along the stroke, a few points at a time
///    ([lookAhead]), so jumping or scribbling does not count;
///  * the finger must stay within [tolerance] of the path;
///  * a stroke is done when [completeAt] of it has been covered.
class TraceEngine {
  final List<List<Offset>> strokes;
  double tolerance;
  double startRadius;
  double completeAt;
  int lookAhead;

  int current = 0;
  int progress = 0; // index of furthest point reached on the current stroke
  bool _tracking = false;
  int offTrackEvents = 0;
  int wrongStarts = 0;

  TraceEngine(
    this.strokes, {
    this.tolerance = 0.12,
    this.startRadius = 0.14,
    this.completeAt = 0.9,
    this.lookAhead = 6,
  });

  /// Tolerances by age mode index (0 = 0–2, 1 = 2–4, 2 = 4–6).
  factory TraceEngine.forAge(List<List<Offset>> strokes, int ageIndex) {
    const tol = [0.17, 0.13, 0.1];
    const start = [0.2, 0.15, 0.12];
    const done = [0.85, 0.9, 0.92];
    final i = ageIndex.clamp(0, 2);
    return TraceEngine(strokes, tolerance: tol[i], startRadius: start[i], completeAt: done[i]);
  }

  bool get done => current >= strokes.length;
  bool get tracking => _tracking;

  /// 0..1 progress of the current stroke.
  double get strokeFraction {
    if (done) return 1;
    final n = strokes[current].length;
    return n <= 1 ? 1 : progress / (n - 1);
  }

  /// 0..1 progress of the whole letter.
  double get letterFraction {
    if (strokes.isEmpty) return 1;
    if (done) return 1;
    return (current + strokeFraction) / strokes.length;
  }

  /// Where the child should put their finger next.
  Offset? get nextPoint => done ? null : strokes[current][progress.clamp(0, strokes[current].length - 1)];

  void reset() {
    current = 0;
    progress = 0;
    _tracking = false;
    offTrackEvents = 0;
    wrongStarts = 0;
  }

  static double _d(Offset a, Offset b) => (a - b).distance;

  TraceEvent down(Offset p) {
    if (done) return TraceEvent.none;
    final pts = strokes[current];
    // Allow resuming from where the child stopped.
    if (_d(p, pts[progress]) <= startRadius) {
      _tracking = true;
      return TraceEvent.started;
    }
    _tracking = false;
    wrongStarts++;
    return TraceEvent.wrongStart;
  }

  TraceEvent move(Offset p) {
    if (done || !_tracking) return TraceEvent.none;
    final pts = strokes[current];
    var best = -1;
    final end = min(pts.length, progress + lookAhead + 1);
    for (var k = progress; k < end; k++) {
      if (_d(p, pts[k]) <= tolerance) best = k;
    }
    if (best >= 0) {
      if (best > progress) progress = best;
      if (pts.length <= 1 || progress / (pts.length - 1) >= completeAt) {
        current++;
        progress = 0;
        _tracking = false;
        return done ? TraceEvent.letterDone : TraceEvent.strokeDone;
      }
      return TraceEvent.onTrack;
    }
    // Not near the next part. Is the finger on the path but going backwards?
    var nearest = -1;
    var nd = double.infinity;
    for (var k = 0; k < pts.length; k++) {
      final d = _d(p, pts[k]);
      if (d < nd) {
        nd = d;
        nearest = k;
      }
    }
    if (nd <= tolerance && nearest < progress - 2) return TraceEvent.wrongDirection;
    offTrackEvents++;
    return TraceEvent.offTrack;
  }

  void up() => _tracking = false;
}
