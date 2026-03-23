import 'dart:convert';

class TextEntry {
  final int id;
  final String textPiece;
  final int number;
  final bool isStruckOut;

  TextEntry({
    required this.id,
    required this.textPiece,
    required this.number,
    required this.isStruckOut,
  });

  factory TextEntry.fromJson(Map<String, dynamic> json) => TextEntry(
        id: json['id'] as int,
        textPiece: json['text_piece'] as String,
        number: json['number'] as int,
        isStruckOut: (json['is_struck_out'] as int? ?? 0) == 1,
      );

  TextEntry copyWith({
    int? id,
    String? textPiece,
    int? number,
    bool? isStruckOut,
  }) =>
      TextEntry(
        id: id ?? this.id,
        textPiece: textPiece ?? this.textPiece,
        number: number ?? this.number,
        isStruckOut: isStruckOut ?? this.isStruckOut,
      );
}

enum DictationResultMode { transcribe, command }

class DictationResult {
  final DictationResultMode mode;
  final String data;

  DictationResult({required this.mode, required this.data});

  factory DictationResult.fromJson(Map<String, dynamic> json) {
    final modeStr = json['mode'] as String;
    return DictationResult(
      mode: modeStr == 'command'
          ? DictationResultMode.command
          : DictationResultMode.transcribe,
      data: json['data'] as String,
    );
  }

  factory DictationResult.fromJsonString(String jsonStr) {
    return DictationResult.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}
