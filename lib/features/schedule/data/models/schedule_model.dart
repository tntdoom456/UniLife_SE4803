import 'dart:convert';

class ScheduleModel {
  final String id;
  final String subject;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int colorValue;

  ScheduleModel({
    required this.id,
    required this.subject,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
  });

  ScheduleModel copyWith({
    String? id,
    String? subject,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? colorValue,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'location': location,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'colorValue': colorValue,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      location: map['location'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      colorValue: map['colorValue']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleModel.fromJson(String source) =>
      ScheduleModel.fromMap(json.decode(source));
}
