import 'dart:convert';

class MaterialModel {
  final String id;
  final String filePath;
  final String fileName;
  final DateTime createdAt;

  MaterialModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
  });

  MaterialModel copyWith({
    String? id,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] ?? '',
      filePath: map['filePath'] ?? '',
      fileName: map['fileName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MaterialModel.fromJson(String source) =>
      MaterialModel.fromMap(json.decode(source));
}
