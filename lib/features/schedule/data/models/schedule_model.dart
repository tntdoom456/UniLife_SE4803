import 'dart:convert';

class ScheduleModel {
  final String id;
  final String subject;
  final String location;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceRule;

  ScheduleModel({
    required this.id,
    required this.subject,
    required this.location,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
  });

  ScheduleModel copyWith({
    String? id,
    String? subject,
    String? location,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceRule,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      location: location ?? this.location,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': subject,
      'lokasi': location,
      'kategori': category,
      'mulai': startTime.toIso8601String(),
      'selesai': endTime.toIso8601String(),
      'recurrenceRule': recurrenceRule,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      subject: map['nama'] ?? map['subject'] ?? '',
      location: map['lokasi'] ?? map['location'] ?? '',
      category: map['kategori'] ?? 'Kuliah',
      startTime: DateTime.parse(map['mulai'] ?? map['startTime']),
      endTime: DateTime.parse(map['selesai'] ?? map['endTime']),
      recurrenceRule: map['recurrenceRule'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleModel.fromJson(String source) =>
      ScheduleModel.fromMap(json.decode(source));
}