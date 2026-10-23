import 'package:flutter/material.dart';

/// One thing a child can see, hear, tap or trace.
class LearnItem {
  final String emoji; // picture (or shape key for shapes)
  final String en; // English name / phrase
  final String hi; // Hindi name / phrase
  final String? label; // big letter or number
  final String? soundEn; // animal / vehicle sound
  final String? soundHi;
  final Color color;
  final int count; // numbers: how many pictures

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

  String name(bool hindi) => hindi ? hi : en;
  String? sound(bool hindi) => hindi ? soundHi : soundEn;
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
  LearnItem(emoji: '🐑', en: 'Sheep', hi: 'भेड़', soundEn: 'Baa! Baa!', soundHi: 'बा! बा!', color: Color(0xFFF5F5F5)),
  LearnItem(emoji: '🦉', en: 'Owl', hi: 'उल्लू', soundEn: 'Hoot! Hoot!', soundHi: 'हू! हू!', color: Color(0xFFD7CCC8)),
  LearnItem(emoji: '🐷', en: 'Pig', hi: 'सुअर', soundEn: 'Oink! Oink!', soundHi: 'ओइंक! ओइंक!', color: Color(0xFFF8BBD0)),
  LearnItem(emoji: '🐝', en: 'Bee', hi: 'मधुमक्खी', soundEn: 'Buzz! Buzz!', soundHi: 'भिन भिन!', color: Color(0xFFFFF59D)),
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
  LearnItem(emoji: '🍍', en: 'Pineapple', hi: 'अनानास', color: Color(0xFFFFF59D)),
  LearnItem(emoji: '🥕', en: 'Carrot', hi: 'गाजर', color: Color(0xFFFFCCBC)),
  LearnItem(emoji: '🍅', en: 'Tomato', hi: 'टमाटर', color: Color(0xFFFFCDD2)),
  LearnItem(emoji: '🌽', en: 'Corn', hi: 'भुट्टा', color: Color(0xFFFFF9C4)),
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
  LearnItem(emoji: '🚁', en: 'Helicopter', hi: 'हेलीकॉप्टर', soundEn: 'Whirr whirr!', soundHi: 'घर्र घर्र!', color: Color(0xFFE1F5FE)),
  LearnItem(emoji: '🚜', en: 'Tractor', hi: 'ट्रैक्टर', soundEn: 'Putt putt!', soundHi: 'भट भट!', color: Color(0xFFDCEDC8)),
];

const colorsList = [
  LearnItem(emoji: '🍎', en: 'Red', hi: 'लाल', color: Color(0xFFEF5350)),
  LearnItem(emoji: '🐳', en: 'Blue', hi: 'नीला', color: Color(0xFF42A5F5)),
  LearnItem(emoji: '🍌', en: 'Yellow', hi: 'पीला', color: Color(0xFFFFEE58)),
  LearnItem(emoji: '🐸', en: 'Green', hi: 'हरा', color: Color(0xFF66BB6A)),
  LearnItem(emoji: '🍊', en: 'Orange', hi: 'नारंगी', color: Color(0xFFFFA726)),
  LearnItem(emoji: '🍇', en: 'Purple', hi: 'बैंगनी', color: Color(0xFFAB47BC)),
  LearnItem(emoji: '🌸', en: 'Pink', hi: 'गुलाबी', color: Color(0xFFF48FB1)),
  LearnItem(emoji: '🐻', en: 'Brown', hi: 'भूरा', color: Color(0xFF8D6E63)),
  LearnItem(emoji: '☁️', en: 'White', hi: 'सफ़ेद', color: Color(0xFFFFFFFF)),
  LearnItem(emoji: '🐈‍⬛', en: 'Black', hi: 'काला', color: Color(0xFF424242)),
];

/// Shapes are drawn by ShapePainter; `emoji` holds the shape key.
const shapes = [
  LearnItem(emoji: 'circle', en: 'Circle', hi: 'गोला', color: Color(0xFFEF5350)),
  LearnItem(emoji: 'square', en: 'Square', hi: 'वर्ग', color: Color(0xFF42A5F5)),
  LearnItem(emoji: 'triangle', en: 'Triangle', hi: 'त्रिभुज', color: Color(0xFF66BB6A)),
  LearnItem(emoji: 'star', en: 'Star', hi: 'तारा', color: Color(0xFFFFCA28)),
  LearnItem(emoji: 'heart', en: 'Heart', hi: 'दिल', color: Color(0xFFEC407A)),
  LearnItem(emoji: 'rectangle', en: 'Rectangle', hi: 'आयत', color: Color(0xFFAB47BC)),
  LearnItem(emoji: 'oval', en: 'Oval', hi: 'अंडाकार', color: Color(0xFF26A69A)),
  LearnItem(emoji: 'diamond', en: 'Diamond', hi: 'हीरा', color: Color(0xFF5C6BC0)),
];

const pastels = [
  Color(0xFFFFCDD2), Color(0xFFFFF9C4), Color(0xFFC8E6C9), Color(0xFFB3E5FC),
  Color(0xFFE1BEE7), Color(0xFFFFE0B2),
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

/// [letter, word, picture]; word '' = letter has no common starting word.
const _swar = [
  ['अ', 'अनार', '🍎'], ['आ', 'आम', '🥭'], ['इ', 'इमली', '🫛'], ['ई', 'ईख', '🎋'],
  ['उ', 'उल्लू', '🦉'], ['ऊ', 'ऊन', '🧶'], ['ऋ', 'ऋषि', '🧘'], ['ए', 'एड़ी', '🦶'],
  ['ऐ', 'ऐनक', '👓'], ['ओ', 'ओखली', '🥣'], ['औ', 'औरत', '👩'], ['अं', 'अंगूर', '🍇'],
  ['अः', '', '😮'],
];

const _vyanjan = [
  ['क', 'कबूतर', '🕊️'], ['ख', 'खरगोश', '🐰'], ['ग', 'गमला', '🪴'], ['घ', 'घड़ी', '⏰'],
  ['ङ', '', '🙂'], ['च', 'चम्मच', '🥄'], ['छ', 'छतरी', '☂️'], ['ज', 'जहाज़', '🚢'],
  ['झ', 'झंडा', '🚩'], ['ञ', '', '🙂'], ['ट', 'टमाटर', '🍅'], ['ठ', 'ठेला', '🛒'],
  ['ड', 'डमरू', '🥁'], ['ढ', 'ढोल', '🪘'], ['ण', '', '🙂'], ['त', 'तितली', '🦋'],
  ['थ', 'थाली', '🍽️'], ['द', 'दरवाज़ा', '🚪'], ['ध', 'धनुष', '🏹'], ['न', 'नल', '🚰'],
  ['प', 'पतंग', '🪁'], ['फ', 'फल', '🍎'], ['ब', 'बतख', '🦆'], ['भ', 'भालू', '🐻'],
  ['म', 'मछली', '🐟'], ['य', 'यान', '🚀'], ['र', 'रेल', '🚂'], ['ल', 'लट्टू', '🪀'],
  ['व', 'वन', '🌳'], ['श', 'शेर', '🦁'], ['ष', 'षट्कोण', '⬡'], ['स', 'सेब', '🍎'],
  ['ह', 'हाथी', '🐘'], ['क्ष', 'क्षत्रिय', '⚔️'], ['त्र', 'त्रिशूल', '🔱'], ['ज्ञ', 'ज्ञानी', '📚'],
];

List<LearnItem> _hindiItems(List<List<String>> src) => [
      for (var i = 0; i < src.length; i++)
        LearnItem(
          label: src[i][0],
          en: src[i][1].isEmpty ? src[i][0] : '${src[i][0]} से ${src[i][1]}',
          hi: src[i][1].isEmpty ? src[i][0] : '${src[i][0]} से ${src[i][1]}',
          emoji: src[i][2],
          color: pastels[i % pastels.length],
        ),
    ];

final abc = [
  for (var i = 0; i < _abc.length; i++)
    LearnItem(
      label: _abc[i][0],
      en: '${_abc[i][0]} for ${_abc[i][1]}',
      hi: '${_abc[i][0]} for ${_abc[i][1]}',
      emoji: _abc[i][2],
      color: pastels[i % pastels.length],
    ),
];

final abcSmall = [
  for (var i = 0; i < _abc.length; i++)
    LearnItem(
      label: _abc[i][0].toLowerCase(),
      en: 'small ${_abc[i][0].toLowerCase()} for ${_abc[i][1]}',
      hi: 'small ${_abc[i][0].toLowerCase()} for ${_abc[i][1]}',
      emoji: _abc[i][2],
      color: pastels[(i + 2) % pastels.length],
    ),
];

final swar = _hindiItems(_swar);
final vyanjan = _hindiItems(_vyanjan);

const numberWordsEn = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];
const numberWordsHi = ['एक', 'दो', 'तीन', 'चार', 'पाँच', 'छह', 'सात', 'आठ', 'नौ', 'दस'];
const _numPics = ['🍎', '🐤', '⭐', '🎈', '🍌', '🐟', '🌸', '🚗', '🍓', '🦋'];

final numbers = [
  for (var i = 0; i < 10; i++)
    LearnItem(
      label: '${i + 1}',
      en: numberWordsEn[i],
      hi: numberWordsHi[i],
      emoji: _numPics[i],
      count: i + 1,
      color: pastels[i % pastels.length],
    ),
];

class Category {
  final String id, title, titleHi, emoji;
  final Color color;
  final List<LearnItem> items;
  const Category(this.id, this.title, this.titleHi, this.emoji, this.color, this.items);
}

final learnCategories = [
  const Category('animals', 'Animals', 'जानवर', '🐄', Color(0xFFFFB74D), animals),
  const Category('fruits', 'Fruits', 'फल', '🍎', Color(0xFFE57373), fruits),
  const Category('vehicles', 'Vehicles', 'गाड़ियाँ', '🚗', Color(0xFF81C784), vehicles),
  const Category('colors', 'Colors', 'रंग', '🎨', Color(0xFFF06292), colorsList),
  const Category('shapes', 'Shapes', 'आकार', '⭐', Color(0xFFFFCA28), shapes),
  Category('abc', 'ABC', 'ABC', '🔤', const Color(0xFF64B5F6), abc),
  Category('swar', 'अ आ इ', 'स्वर', 'अ', const Color(0xFFBA68C8), swar),
  Category('vyanjan', 'क ख ग', 'व्यंजन', 'क', const Color(0xFF9575CD), vyanjan),
  Category('numbers', '123', 'गिनती', '🔢', const Color(0xFF4DB6AC), numbers),
];

const praiseEn = ['Well done!', 'Great job!', 'Yay! You did it!', 'Super!', 'Wonderful!', 'Clap clap clap!'];
const praiseHi = ['बहुत अच्छा!', 'शाबाश!', 'वाह! बहुत बढ़िया!', 'कमाल कर दिया!', 'ताली ताली ताली!'];
