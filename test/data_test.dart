import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_app/core/data.dart';
import 'package:kids_learning_app/core/season.dart';
import 'package:kids_learning_app/core/settings.dart';
import 'package:kids_learning_app/core/strokes.dart';
import 'package:kids_learning_app/core/audio.dart';

void main() {
  test('ABC has 26 letters, small letters match', () {
    expect(abc.length, 26);
    expect(abc.first.label, 'A');
    expect(abc.last.label, 'Z');
    expect(abcSmall.first.label, 'a');
  });

  test('Hindi varnamala lists are complete', () {
    expect(swar.length, 13);
    expect(vyanjan.length, 36);
    expect(swar.first.label, 'अ');
    expect(vyanjan.last.label, 'ज्ञ');
  });

  test('Numbers 1-10 show matching picture count', () {
    for (var i = 0; i < numbers.length; i++) {
      expect(numbers[i].count, i + 1);
    }
  });

  test('Every item has English and Hindi names', () {
    for (final c in learnCategories) {
      expect(c.items, isNotEmpty);
      for (final it in c.items) {
        expect(it.en.trim(), isNotEmpty);
        expect(it.hi.trim(), isNotEmpty);
      }
    }
  });

  test('Season themes by date', () {
    expect(currentSeason(DateTime(2026, 10, 25)), Season.diwali);
    expect(currentSeason(DateTime(2026, 3, 10)), Season.holi);
    expect(currentSeason(DateTime(2026, 1, 5)), Season.winter);
    expect(currentSeason(DateTime(2026, 8, 5)), Season.rain);
  });

  test('Placed sticker encodes and decodes', () {
    final p = PlacedSticker.decode(PlacedSticker('🦄', 0.25, 0.5, 2).encode())!;
    expect(p.emoji, '🦄');
    expect(p.x, 0.25);
    expect(p.scene, 2);
  });

  test('Every traceable letter and number has stroke data inside the box', () {
    for (final it in [...abc, ...abcSmall, ...numbers]) {
      final st = strokes[it.label];
      expect(st, isNotNull, reason: 'missing strokes for ${it.label}');
      for (final s in st!) {
        expect(s.length, greaterThan(1));
        for (final p in s) {
          expect(p.dx, inInclusiveRange(-0.01, 1.01));
          expect(p.dy, inInclusiveRange(-0.01, 1.01));
        }
      }
    }
  });

  test('Phonics phrases', () {
    expect(letterSoundPhrase(abc[1]), ['B says buh, buh', 'Ball']);
    expect(soundOf('m'), 'mmm');
  });

  test('Voice file names from phrases', () {
    expect(Audio.slug('B says buh, buh'), 'b_says_buh_buh');
    expect(Audio.slug('Well done!'), 'well_done');
  });
}
