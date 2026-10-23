import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/settings.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import 'home.dart';
import 'letter_games.dart';
import 'toys.dart';

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final fav = s.plays.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        String nameOf(String id) {
          for (final a in allActivities) {
            if (a.id == id) return '${a.emoji} ${a.en}';
          }
          for (final g in letterGames) {
            if (g.id == id) return '${g.emoji} ${g.en}';
          }
          return id == 'stickers' ? '📒 Sticker book' : id;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Parent Zone'), backgroundColor: const Color(0xFFFFE0B2)),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            _h('Teacher Mode'),
            SwitchListTile(
              secondary: const Text('🍎', style: TextStyle(fontSize: 26)),
              title: const Text('Teacher Mode'),
              subtitle: const Text('Unlocks every activity for any age, for classroom or guided use'),
              value: s.teacher,
              onChanged: (v) => s.update(() => s.teacher = v),
            ),
            ListTile(
              leading: const Text('📋', style: TextStyle(fontSize: 26)),
              title: const Text('Report Card'),
              subtitle: const Text('Letter-by-letter progress, accuracy and what to practise next'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportCardScreen())),
            ),
            _h('Child lock'),
            SwitchListTile(
              secondary: const Text('🔒', style: TextStyle(fontSize: 26)),
              title: const Text('Child lock'),
              subtitle: const Text('Back button is blocked and the 🏠 button must be held for 1 second'),
              value: s.childLock,
              onChanged: (v) => s.update(() => s.childLock = v),
            ),
            _h('Child\'s age'),
            SegmentedButton<AgeMode>(
              segments: const [
                ButtonSegment(value: AgeMode.baby, label: Text('0–2'), icon: Text('👶')),
                ButtonSegment(value: AgeMode.toddler, label: Text('2–3'), icon: Text('🧒')),
                ButtonSegment(value: AgeMode.preschool, label: Text('3–5'), icon: Text('🎒')),
              ],
              selected: {s.age},
              onSelectionChanged: (v) => s.update(() => s.age = v.first),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                  '0–2: tapping, sounds, bubbles, piano, drawing.  2–3: adds Find It, Catch, Puzzle, Tracing.  3–5: adds ordering games and harder puzzles.',
                  style: TextStyle(color: Colors.black54)),
            ),
            _h('Sound & language'),
            SwitchListTile(
              title: const Text('Hindi (हिंदी)'),
              value: s.hindi,
              onChanged: (v) => s.update(() => s.hindi = v),
            ),
            SwitchListTile(
              title: const Text('Background music'),
              value: s.music,
              onChanged: (v) {
                s.update(() => s.music = v);
                Audio.I.refreshMusic();
              },
            ),
            SwitchListTile(
              title: const Text('Mute all sound'),
              value: s.muted,
              onChanged: (v) {
                s.update(() => s.muted = v);
                if (v) Audio.I.pauseAll();
                Audio.I.refreshMusic();
              },
            ),
            SwitchListTile(
              title: const Text('Calm mode'),
              subtitle: const Text('Less movement, no confetti or floating effects'),
              value: s.calm,
              onChanged: (v) => s.update(() => s.calm = v),
            ),
            if (!Audio.I.hindiVoiceOk)
              const Card(
                color: Color(0xFFFFF3E0),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Hindi voice not found on this phone. Install it: Settings → System → Languages → '
                      'Text-to-speech → Google → Install voice data → Hindi.'),
                ),
              ),
            _h('Screen time'),
            Wrap(spacing: 8, children: [
              for (final m in [0, 10, 15, 20, 30])
                ChoiceChip(
                  label: Text(m == 0 ? 'Off' : '$m min'),
                  selected: s.limitMinutes == m,
                  onSelected: (_) => s.update(() {
                    s.limitMinutes = m;
                    s.sessionStart = DateTime.now();
                  }),
                ),
            ]),
            const Text('When time is up, Golu yawns and asks to rest. A grown-up can continue.',
                style: TextStyle(color: Colors.black54)),
            _h('Birthday theme'),
            ListTile(
              leading: const Text('🎂', style: TextStyle(fontSize: 28)),
              title: Text(s.birthdayMonth == null ? 'Set child\'s birthday' : 'Birthday: ${s.birthdayDay}/${s.birthdayMonth}'),
              subtitle: const Text('Balloons and a birthday greeting on that day'),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 6),
                  lastDate: now,
                  initialDate: now,
                );
                if (d != null) {
                  s.update(() {
                    s.birthdayMonth = d.month;
                    s.birthdayDay = d.day;
                  });
                }
              },
            ),
            _h('Game groups'),
            SwitchListTile(
              secondary: const Text('✍️', style: TextStyle(fontSize: 24)),
              title: const Text('Tracing games'),
              value: !s.disabledGames.contains('group:tracing'),
              onChanged: (v) => s.update(() => v ? s.disabledGames.remove('group:tracing') : s.disabledGames.add('group:tracing')),
            ),
            SwitchListTile(
              secondary: const Text('🔊', style: TextStyle(fontSize: 24)),
              title: const Text('Phonics games'),
              value: !s.disabledGames.contains('group:phonics'),
              onChanged: (v) => s.update(() => v ? s.disabledGames.remove('group:phonics') : s.disabledGames.add('group:phonics')),
            ),
            SwitchListTile(
              secondary: const Text('🎮', style: TextStyle(fontSize: 24)),
              title: const Text('Letter mini-games'),
              value: !s.disabledGames.contains('group:games'),
              onChanged: (v) => s.update(() => v ? s.disabledGames.remove('group:games') : s.disabledGames.add('group:games')),
            ),
            _h('Activities on the map'),
            for (final a in allActivities)
              CheckboxListTile(
                dense: true,
                secondary: Text(a.emoji, style: const TextStyle(fontSize: 24)),
                title: Text('${a.en}  (${['0–2', '2–3', '3–5'][a.minAge.index]}+)'),
                value: !s.disabledGames.contains(a.id),
                onChanged: (v) => s.update(() {
                  if (v == true) {
                    s.disabledGames.remove(a.id);
                  } else {
                    s.disabledGames.add(a.id);
                  }
                }),
              ),
            _h('ABC Land games'),
            for (final g in letterGames)
              CheckboxListTile(
                dense: true,
                secondary: Text(g.emoji, style: const TextStyle(fontSize: 24)),
                title: Text('${g.en}  (${['0–2', '2–3', '3–5'][g.minAge.index]}+, ${g.group})'),
                value: !s.disabledGames.contains(g.id),
                onChanged: (v) => s.update(() {
                  if (v == true) {
                    s.disabledGames.remove(g.id);
                  } else {
                    s.disabledGames.add(g.id);
                  }
                }),
              ),
            _h('Progress (saved only on this phone)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _stat('⏱️', '${s.totalMinutes}', 'minutes'),
                    _stat('🎁', '${s.stickers}', 'stickers'),
                    _stat('✏️', '${s.traced.length}', 'letters traced'),
                    _stat('🧸', '${s.toys.length}', 'toys'),
                  ]),
                  const SizedBox(height: 12),
                  if (fav.isNotEmpty) ...[
                    const Text('Favourite activities', style: TextStyle(fontWeight: FontWeight.bold)),
                    for (final e in fav.take(4)) Text('${nameOf(e.key)} — ${e.value} times'),
                  ],
                  if (s.traced.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Traced', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final l in (s.traced.toList()..sort())) Chip(label: Text(l, style: const TextStyle(fontSize: 18))),
                    ]),
                  ],
                ]),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              label: const Text('Reset progress', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset progress?'),
                    content: const Text('Stickers, traced letters and play history will be cleared.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
                    ],
                  ),
                );
                if (ok == true) s.resetProgress();
              },
            ),
            const Divider(height: 32),
            const ListTile(
              leading: Icon(Icons.child_care),
              title: Text('Tips for 0–2 years'),
              subtitle: Text('Play together for short sessions (5–10 minutes). Name things you see in real life too — '
                  'screens work best as a shared activity, not a replacement for play and talk.'),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy'),
              subtitle: Text('Works fully offline. No internet permission, no ads, no accounts. '
                  'Settings and progress stay only on this phone.'),
            ),
            const ListTile(leading: Icon(Icons.info_outline), title: Text('Kids Learning App'), subtitle: Text('Version 4.0.0')),
          ]),
        );
      },
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
      );

  Widget _stat(String e, String v, String l) => Expanded(
        child: Column(children: [
          Text(e, style: const TextStyle(fontSize: 26)),
          Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(l, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ]),
      );
}

/// Shown when the screen-time limit is reached.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hi = AppState.I.hindi;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF283593), Color(0xFF7986CB)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌙  ⭐  ✨', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 20),
                const Mascot(kind: MascotKind.golu, mood: Mood.sleepy, size: 200),
                const SizedBox(height: 20),
                Text(hi ? 'आराम का समय!' : 'Time to rest!',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text(hi ? 'चलो बाहर खेलें 🌳' : "Let's play outside 🌳",
                    style: const TextStyle(fontSize: 24, color: Colors.white70)),
                const SizedBox(height: 40),
                TextButton.icon(
                  icon: const Icon(Icons.lock_outline, color: Colors.white70),
                  label: const Text('Grown-up: continue', style: TextStyle(color: Colors.white70)),
                  onPressed: () async {
                    if (await parentGate(context) && context.mounted) {
                      AppState.I.sessionStart = DateTime.now();
                      Audio.I.refreshMusic();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
