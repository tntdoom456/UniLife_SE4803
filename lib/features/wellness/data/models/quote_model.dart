class QuoteModel {
  final String text;
  final String author;

  QuoteModel({
    required this.text,
    required this.author,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      text: json['quote'] ?? json['q'] ?? '',
      author: json['author'] ?? json['a'] ?? 'Anonim',
    );
  }
}

class WellnessLogModel {
  final String date;
  final String mood;
  final int waterGlasses;
  final double sleepHours;
  final int mealsCount;
  final int score;
  final String note;

  WellnessLogModel({
    required this.date,
    required this.mood,
    required this.waterGlasses,
    required this.sleepHours,
    required this.mealsCount,
    required this.score,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'mood': mood,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'mealsCount': mealsCount,
      'score': score,
      'note': note,
    };
  }

  factory WellnessLogModel.fromMap(Map<String, dynamic> map) {
    return WellnessLogModel(
      date: map['date'] ?? '',
      mood: map['mood'] ?? '-',
      waterGlasses: map['waterGlasses']?.toInt() ?? 0,
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      mealsCount: map['mealsCount']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      note: map['note'] ?? '',
    );
  }
}