import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_app/core/data.dart';
import 'package:kids_learning_app/core/season.dart';
import 'package:kids_learning_app/core/settings.dart';

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
}
