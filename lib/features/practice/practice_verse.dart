import 'package:json_annotation/json_annotation.dart';

part 'practice_verse.g.dart';

@JsonSerializable()
class PracticeVerse {
  final String id;
  final String content;
  final String reference;
  final DateTime createdAt;

  PracticeVerse({
    required this.id,
    required this.content,
    required this.reference,
    required this.createdAt,
  });

  factory PracticeVerse.fromJson(Map<String, dynamic> json) => _$PracticeVerseFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeVerseToJson(this);

  PracticeVerse copyWith({
    String? id,
    String? content,
    String? reference,
    DateTime? createdAt,
  }) {
    return PracticeVerse(
      id: id ?? this.id,
      content: content ?? this.content,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
