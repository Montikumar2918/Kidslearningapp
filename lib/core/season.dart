import 'settings.dart';

enum Season { normal, diwali, holi, rain, winter, summer, birthday, halloween, christmas, school }

/// Picks a theme from today's date (approximate festival windows).
Season currentSeason([DateTime? now]) {
  final d = now ?? DateTime.now();
  if (AppState.I.isBirthday) return Season.birthday;
  final m = d.month, day = d.day;
  if (m == 10 && day >= 29) return Season.halloween;
  if (m == 12 && day >= 15) return Season.christmas;
  if ((m == 6 && day <= 15) || (m == 4 && day <= 7)) return Season.school;
  if ((m == 10 && day >= 15) || (m == 11 && day <= 15)) return Season.diwali;
  if (m == 3 && day <= 25) return Season.holi;
  if (m == 12 || m == 1 || m == 2) return Season.winter;
  if (m >= 7 && m <= 9) return Season.rain;
  if (m >= 4 && m <= 6) return Season.summer;
  return Season.normal;
}

String seasonGreeting(Season s, bool hindi) {
  switch (s) {
    case Season.diwali:
      return hindi ? 'शुभ दीपावली!' : 'Happy Diwali!';
    case Season.holi:
      return hindi ? 'होली है!' : 'Happy Holi!';
    case Season.birthday:
      return hindi ? 'जन्मदिन मुबारक!' : 'Happy Birthday!';
    case Season.halloween:
      return hindi ? 'हैलोवीन! बू!' : 'Happy Halloween! Boo!';
    case Season.christmas:
      return hindi ? 'मेरी क्रिसमस!' : 'Merry Christmas!';
    case Season.school:
      return hindi ? 'स्कूल का समय!' : 'Back to school!';
    case Season.rain:
      return hindi ? 'बारिश आई!' : 'Pitter patter rain!';
    case Season.winter:
      return hindi ? 'सर्दी आई!' : 'Brrr, it is winter!';
    default:
      return hindi ? 'नमस्ते! चलो खेलें!' : "Hello! Let's play!";
  }
}
