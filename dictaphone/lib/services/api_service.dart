import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // ---- HTML helpers ----

  static List<TextEntry> parseHtml(String html) {
    final entries = <TextEntry>[];
    final pTagRegex = RegExp(r'<p>(.*?)</p>', dotAll: true);
    final sTagRegex = RegExp(r'^<s>(.*?)</s>$', dotAll: true);
    int index = 0;
    for (final match in pTagRegex.allMatches(html)) {
      final inner = match.group(1) ?? '';
      final sMatch = sTagRegex.firstMatch(inner);
      final isStruckOut = sMatch != null;
      final rawText = isStruckOut ? (sMatch!.group(1) ?? '') : inner;
      final textPiece = rawText.replaceAll(RegExp(r'<[^>]+>'), '');
      entries.add(TextEntry(
        id: index,
        textPiece: textPiece,
        number: index + 1,
        isStruckOut: isStruckOut,
      ));
      index++;
    }
    return entries;
  }

  static String serializeToHtml(List<TextEntry> entries) {
    final buffer = StringBuffer();
    for (final entry in entries) {
      if (entry.isStruckOut) {
        buffer.write('<p><s>${entry.textPiece}</s></p>');
      } else {
        buffer.write('<p>${entry.textPiece}</p>');
      }
    }
    return buffer.toString();
  }

  // ---- Folders (chapters) ----

  Future<List<Map<String, dynamic>>> listChapters() async {
    final response = await http.get(Uri.parse('$baseUrl/api/folders'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load chapters: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createChapter(String name, {int? parentId}) async {
    final body = <String, dynamic>{'title': name};
    if (parentId != null) body['parent'] = parentId;
    final response = await http.post(
      Uri.parse('$baseUrl/api/folders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create chapter: ${response.statusCode}');
  }

  Future<void> renameChapter(int folderId, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/folders/$folderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rename chapter: ${response.statusCode}');
    }
  }

  Future<void> deleteChapter(int folderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/folders/$folderId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete chapter: ${response.statusCode}');
    }
  }

  // ---- Texts ----

  Future<List<TextEntry>> getTexts(int folderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/texts/$folderId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as String? ?? '';
      return parseHtml(content);
    }
    throw Exception('Failed to load texts: ${response.statusCode}');
  }

  Future<List<TextEntry>> addText(int folderId, String textPiece) async {
    final current = await getTexts(folderId);
    final updated = List<TextEntry>.from(current)
      ..add(TextEntry(
        id: current.length,
        textPiece: textPiece,
        number: current.length + 1,
        isStruckOut: false,
      ));
    return await _putContent(folderId, serializeToHtml(updated));
  }

  Future<List<TextEntry>> updateText(
      int folderId, int entryIndex, String textPiece) async {
    final current = await getTexts(folderId);
    if (entryIndex < 0 || entryIndex >= current.length) {
      throw Exception('Entry index out of range');
    }
    final updated = List<TextEntry>.from(current);
    updated[entryIndex] = updated[entryIndex].copyWith(textPiece: textPiece);
    return await _putContent(folderId, serializeToHtml(updated));
  }

  Future<List<TextEntry>> redoText(int folderId, int entryIndex) async {
    final current = await getTexts(folderId);
    if (entryIndex < 0 || entryIndex >= current.length) {
      throw Exception('Entry index out of range');
    }
    final updated = List<TextEntry>.from(current);
    updated[entryIndex] = updated[entryIndex].copyWith(isStruckOut: true);
    return await _putContent(folderId, serializeToHtml(updated));
  }

  Future<List<TextEntry>> _putContent(int folderId, String html) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/texts/$folderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': html}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as String? ?? '';
      return parseHtml(content);
    }
    throw Exception('Failed to save texts: ${response.statusCode}');
  }
}
