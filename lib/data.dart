import 'package:flutter/material.dart';

/// One thing a baby can see and tap.
class LearnItem {
  final String emoji; // big picture
  final String en; // English word
  final String hi; // Hindi word
  final String? label; // big text shown instead of/with emoji (letters, numbers)
  final String? soundEn; // e.g. animal sound
  final String? soundHi;
  final Color color;
  final int count; // for numbers: how many pictures to show

  const LearnItem({
    required this.emoji,
    required this.en,
    required this.hi,
    required this.color,
    this.label,
    this.soundEn,
    this.soundHi,
    this.count = 0,
  });
}

class Category {
  final String title;
  final String titleHi;
  final String emoji;
  final Color color;
  final List<LearnItem> items;
  const Category(this.title, this.titleHi, this.emoji, this.color, this.items);
}

const animals = [
  LearnItem(emoji: '🐄', en: 'Cow', hi: 'गाय', soundEn: 'Moo! Moo!', soundHi: 'मूँ! मूँ!', color: Color(0xFFFFE0B2)),
  LearnItem(emoji: '🐶', en: 'Dog', hi: 'कुत्ता', soundEn: 'Woof! Woof!', soundHi: 'भौं! भौं!', color: Color(0xFFFFF9C4)),
  LearnItem(emoji: '🐱', en: 'Cat', hi: 'बिल्ली', soundEn: 'Meow! Meow!', soundHi: 'म्याऊँ! म्याऊँ!', color: Color(0xFFE1F5FE)),
  LearnItem(emoji: '🦆', en: 'Duck', hi: 'बत्तख', soundEn: 'Quack! Quack!', soundHi: 'क्वैक! क्वैक!', color: Color(0xFFDCEDC8)),
  LearnItem(emoji: '🐐', en: 'Goat', hi: 'बकरी', soundEn: 'Maa! Maa!', soundHi: 'में! में!', color: Color(0xFFF3E5F5)),
  LearnItem(emoji: '🐓', en: 'Rooster', hi: 'मुर्गा', soundEn: 'Cock-a-doodle-doo!', soundHi: 'कुकड़ूँ कूँ!', color: Color(0xFFFFCCBC)),
  LearnItem(emoji: '🦁', en: 'Lion', hi: 'शेर', soundEn: 'Roar!', soundHi: 'दहाड़!', color: Color(0xFFFFECB3)),
  LearnItem(emoji: '🐘', en: 'Elephant', hi: 'हाथी', soundEn: 'Pawoo!', soundHi: 'पों पों!', color: Color(0xFFCFD8DC)),
  LearnItem(emoji: '🐒', en: 'Monkey', hi: 'बंदर', soundEn: 'Ooh ooh aah aah!', soundHi: 'ऊ ऊ आ आ!', color: Color(0xFFD7CCC8)),
  LearnItem(emoji: '🐦', en: 'Bird', hi: 'चिड़िया', soundEn: 'Tweet! Tweet!', soundHi: 'चीं! चीं!', color: Color(0xFFB2EBF2)),
  LearnItem(emoji: '🐸', en: 'Frog', hi: 'मेंढक', soundEn: 'Ribbit! Ribbit!', soundHi: 'टर्र! टर्र!', color: Color(0xFFC8E6C9)),
  LearnItem(emoji: '🐴', en: 'Horse', hi: 'घोड़ा', soundEn: 'Neigh!', soundHi: 'हिन हिन!', color: Color(0xFFFFE0B2)),
];

const fruits = [
  LearnItem(emoji: '🍎', en: 'Apple', hi: 'सेब', color: Color(0xFFFFCDD2)),
  LearnItem(emoji: '🍌', en: 'Banana', hi: 'केला', color: Color(0xFFFFF9C4)),
  LearnItem(emoji: '🥭', en: 'Mango', hi: 'आम', color: Color(0xFFFFE0B2)),
  LearnItem(emoji: '🍇', en: 'Grapes', hi: 'अंगूर', color: Color(0xFFE1BEE7)),
  LearnItem(emoji: '🍊', en: 'Orange', hi: 'संतरा', color: Color(0xFFFFE0B2)),
  LearnItem(emoji: '🍉', en: 'Watermelon', hi: 'तरबूज', color: Color(0xFFC8E6C9)),
  LearnItem(emoji: '🍓', en: 'Strawberry', hi: 'स्ट्रॉबेरी', color: Color(0xFFF8BBD0)),
  LearnItem(emoji: '🍐', en: 'Pear', hi: 'नाशपाती', color: Color(0xFFDCEDC8)),
  LearnItem(emoji: '🥕', en: 'Carrot', hi: 'गाजर', color: Color(0xFFFFCCBC)),
  LearnItem(emoji: '🍅', en: 'Tomato', hi: 'टमाटर', color: Color(0xFFFFCDD2)),
];

const vehicles = [
  LearnItem(emoji: '🚗', en: 'Car', hi: 'गाड़ी', soundEn: 'Beep beep!', soundHi: 'पीं पीं!', color: Color(0xFFFFCDD2)),
  LearnItem(emoji: '🚌', en: 'Bus', hi: 'बस', soundEn: 'Honk honk!', soundHi: 'पों पों!', color: Color(0xFFFFF9C4)),
  LearnItem(emoji: '🚂', en: 'Train', hi: 'रेलगाड़ी', soundEn: 'Choo choo!', soundHi: 'छुक छुक!', color: Color(0xFFD7CCC8)),
  LearnItem(emoji: '✈️', en: 'Aeroplane', hi: 'हवाई जहाज़', soundEn: 'Zoom!', soundHi: 'सूँ!', color: Color(0xFFB3E5FC)),
  LearnItem(emoji: '🚲', en: 'Cycle', hi: 'साइकिल', soundEn: 'Tring tring!', soundHi: 'ट्रिन ट्रिन!', color: Color(0xFFC8E6C9)),
  LearnItem(emoji: '🛺', en: 'Auto', hi: 'ऑटो', soundEn: 'Brr brr!', soundHi: 'भर्र भर्र!', color: Color(0xFFFFECB3)),
  LearnItem(emoji: '🚒', en: 'Fire truck', hi: 'दमकल', soundEn: 'Nee naw!', soundHi: 'टूँ टूँ!', color: Color(0xFFFFCCBC)),
  LearnItem(emoji: '⛵', en: 'Boat', hi: 'नाव', soundEn: 'Splash!', soundHi: 'छप छप!', color: Color(0xFFB2EBF2)),
];

const colorsList = [
  LearnItem(emoji: '🔴', en: 'Red', hi: 'लाल', color: Color(0xFFEF5350)),
  LearnItem(emoji: '🔵', en: 'Blue', hi: 'नीला', color: Color(0xFF42A5F5)),
  LearnItem(emoji: '🟡', en: 'Yellow', hi: 'पीला', color: Color(0xFFFFEE58)),
  LearnItem(emoji: '🟢', en: 'Green', hi: 'हरा', color: Color(0xFF66BB6A)),
  LearnItem(emoji: '🟠', en: 'Orange', hi: 'नारंगी', color: Color(0xFFFFA726)),
  LearnItem(emoji: '🟣', en: 'Purple', hi: 'बैंगनी', color: Color(0xFFAB47BC)),
  LearnItem(emoji: '🩷', en: 'Pink', hi: 'गुलाबी', color: Color(0xFFF48FB1)),
  LearnItem(emoji: '🟤', en: 'Brown', hi: 'भूरा', color: Color(0xFF8D6E63)),
];

/// Shapes are drawn with a painter; emoji field holds the shape key.
const shapes = [
  LearnItem(emoji: 'circle', en: 'Circle', hi: 'गोला', color: Color(0xFFEF5350)),
  LearnItem(emoji: 'square', en: 'Square', hi: 'वर्ग', color: Color(0xFF42A5F5)),
  LearnItem(emoji: 'triangle', en: 'Triangle', hi: 'त्रिभुज', color: Color(0xFF66BB6A)),
  LearnItem(emoji: 'star', en: 'Star', hi: 'तारा', color: Color(0xFFFFCA28)),
  LearnItem(emoji: 'heart', en: 'Heart', hi: 'दिल', color: Color(0xFFEC407A)),
  LearnItem(emoji: 'rectangle', en: 'Rectangle', hi: 'आयत', color: Color(0xFFAB47BC)),
];

const _abc = [
  ['A', 'Apple', '🍎'], ['B', 'Ball', '⚽'], ['C', 'Cat', '🐱'], ['D', 'Dog', '🐶'],
  ['E', 'Elephant', '🐘'], ['F', 'Fish', '🐟'], ['G', 'Grapes', '🍇'], ['H', 'Hat', '🎩'],
  ['I', 'Ice cream', '🍦'], ['J', 'Jug', '🏺'], ['K', 'Kite', '🪁'], ['L', 'Lion', '🦁'],
  ['M', 'Mango', '🥭'], ['N', 'Nest', '🪺'], ['O', 'Orange', '🍊'], ['P', 'Parrot', '🦜'],
  ['Q', 'Queen', '👸'], ['R', 'Rabbit', '🐰'], ['S', 'Sun', '☀️'], ['T', 'Tiger', '🐯'],
  ['U', 'Umbrella', '☂️'], ['V', 'Van', '🚐'], ['W', 'Watch', '⌚'], ['X', 'Xylophone', '🎹'],
  ['Y', 'Yak', '🐃'], ['Z', 'Zebra', '🦓'],
];

const _swar = [
  ['अ', 'अनार', '🍎'], ['आ', 'आम', '🥭'], ['इ', 'इमली', '🫛'], ['ई', 'ईख', '🎋'],
  ['उ', 'उल्लू', '🦉'], ['ऊ', 'ऊन', '🧶'], ['ऋ', 'ऋषि', '🧘'], ['ए', 'एड़ी', '🦶'],
  ['ऐ', 'ऐनक', '👓'], ['ओ', 'ओखली', '🥣'], ['औ', 'औरत', '👩'], ['अं', 'अंगूर', '🍇'],
  ['अः', 'अः', '😮'],
];

const _pastels = [
  Color(0xFFFFCDD2), Color(0xFFFFF9C4), Color(0xFFC8E6C9), Color(0xFFB3E5FC),
  Color(0xFFE1BEE7), Color(0xFFFFE0B2),
];

final abc = [
  for (var i = 0; i < _abc.length; i++)
    LearnItem(
      label: _abc[i][0],
      en: '${_abc[i][0]} for ${_abc[i][1]}',
      hi: '${_abc[i][0]} for ${_abc[i][1]}',
      emoji: _abc[i][2],
      color: _pastels[i % _pastels.length],
    ),
];

final swar = [
  for (var i = 0; i < _swar.length; i++)
    LearnItem(
      label: _swar[i][0],
      en: i == _swar.length - 1 ? 'अः' : '${_swar[i][0]} से ${_swar[i][1]}',
      hi: i == _swar.length - 1 ? 'अः' : '${_swar[i][0]} से ${_swar[i][1]}',
      emoji: _swar[i][2],
      color: _pastels[i % _pastels.length],
    ),
];

const _numEn = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];
const _numHi = ['एक', 'दो', 'तीन', 'चार', 'पाँच', 'छह', 'सात', 'आठ', 'नौ', 'दस'];
const _numPics = ['🍎', '🐤', '⭐', '🎈', '🍌', '🐟', '🌸', '🚗', '🍓', '🦋'];

final numbers = [
  for (var i = 0; i < 10; i++)
    LearnItem(
      label: '${i + 1}',
      en: _numEn[i],
      hi: _numHi[i],
      emoji: _numPics[i],
      count: i + 1,
      color: _pastels[i % _pastels.length],
    ),
];

const numberWordsEn = _numEn;
const numberWordsHi = _numHi;

final categories = [
  const Category('Animals', 'जानवर', '🐄', Color(0xFFFFB74D), animals),
  const Category('Fruits', 'फल', '🍎', Color(0xFFE57373), fruits),
  Category('ABC', 'ABC', '🔤', const Color(0xFF64B5F6), abc),
  Category('अ आ इ', 'स्वर', 'अ', const Color(0xFFBA68C8), swar),
  Category('123', 'गिनती', '🔢', const Color(0xFF4DB6AC), numbers),
  const Category('Colors', 'रंग', '🎨', Color(0xFFF06292), colorsList),
  const Category('Shapes', 'आकार', '⭐', Color(0xFFFFD54F), shapes),
  const Category('Vehicles', 'गाड़ियाँ', '🚗', Color(0xFF81C784), vehicles),
];
