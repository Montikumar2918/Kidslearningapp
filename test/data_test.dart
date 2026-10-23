import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_app/data.dart';

void main() {
  test('ABC has 26 letters in order', () {
    expect(abc.length, 26);
    expect(abc.first.label, 'A');
    expect(abc.last.label, 'Z');
  });

  test('Hindi swar has 13 letters', () {
    expect(swar.length, 13);
    expect(swar.first.label, 'अ');
  });

  test('Numbers 1-10 show matching picture count', () {
    for (var i = 0; i < numbers.length; i++) {
      expect(numbers[i].count, i + 1);
    }
  });

  test('Every category has items with English and Hindi names', () {
    for (final c in categories) {
      expect(c.items, isNotEmpty);
      for (final it in c.items) {
        expect(it.en.trim(), isNotEmpty);
        expect(it.hi.trim(), isNotEmpty);
      }
    }
  });
}
