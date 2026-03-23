import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/models.dart';
import 'api_service.dart';
import 'dictation_service.dart';
import 'audio_player_service.dart';

class StoryManager extends ChangeNotifier {
  final DictationService _dictationService;
  final ApiService _apiService;
  final AudioPlayerService _audioPlayer;

  int? _chapterId;
  final List<TextEntry> _texts = [];
  DictationState _state = DictationState.disconnected;
  String? _errorMessage;

  StreamSubscription? _resultSub;
  StreamSubscription? _stateSub;

  StoryManager({
    required DictationService dictationService,
    required ApiService apiService,
    required AudioPlayerService audioPlayer,
  })  : _dictationService = dictationService,
        _apiService = apiService,
        _audioPlayer = audioPlayer {
    _resultSub = _dictationService.onResult.listen(_handleResult);
    _stateSub = _dictationService.onStateChange.listen(_handleStateChange);
  }

  int? get chapterId => _chapterId;
  List<TextEntry> get texts => List.unmodifiable(_texts);
  DictationState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isActive =>
      _state == DictationState.listening ||
      _state == DictationState.processing ||
      _state == DictationState.speaking ||
      _state == DictationState.connecting;

  String get storyMarkdown {
    final buffer = StringBuffer();
    for (final t in _texts) {
      if (t.isStruckOut) {
        buffer.writeln('~~${t.textPiece}~~\n');
      } else {
        buffer.writeln('${t.textPiece}\n');
      }
    }
    return buffer.toString();
  }

  List<TextEntry> get activeTexts =>
      _texts.where((t) => !t.isStruckOut).toList();

  Future<void> loadChapter(int chapterId) async {
    _chapterId = chapterId;
    _texts.clear();
    try {
      final entries = await _apiService.getTexts(chapterId);
      _texts.addAll(entries);
    } catch (e) {
      print('Error loading chapter: $e');
    }
    notifyListeners();
  }

  Future<void> startSession(int chapterId) async {
    _errorMessage = null;
    _chapterId = chapterId;
    _state = DictationState.connecting;
    notifyListeners();

    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Dictator',
        notificationText: 'Recording your story...',
        callback: _foregroundCallback,
      );

      await _dictationService.connect();
      await _dictationService.startListening();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopSession() async {
    try {
      await _dictationService.stopListening();
      await _dictationService.disconnect();
      await _audioPlayer.stop();
      await FlutterForegroundTask.stopService();
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void _handleResult(DictationResult result) {
    if (_chapterId == null) return;

    print('StoryManager got result: mode=${result.mode}, data="${result.data}"');

    switch (result.mode) {
      case DictationResultMode.transcribe:
        _addText(result.data);
        break;
      case DictationResultMode.command:
        _handleCommand(result.data);
        break;
    }
  }

  Future<void> _addText(String text) async {
    if (_chapterId == null) return;

    // Add locally first for immediate UI feedback
    final tempEntry = TextEntry(id: -1, textPiece: text, number: _texts.length + 1, isStruckOut: false);
    _texts.add(tempEntry);
    notifyListeners();

    try {
      final updated = await _apiService.addText(_chapterId!, text);
      _texts.clear();
      _texts.addAll(updated);
    } catch (e) {
      print('Error saving text to server: $e');
      _texts.remove(tempEntry);
    }
  }

  void _handleCommand(String command) {
    if (command == 'redo') {
      _handleRedo();
    } else if (command.startsWith('reread')) {
      final parts = command.split(':');
      final count = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
      _handleReread(count);
    }
  }

  Future<void> _handleRedo() async {
    for (int i = _texts.length - 1; i >= 0; i--) {
      if (!_texts[i].isStruckOut) {
        _texts[i] = _texts[i].copyWith(isStruckOut: true);
        notifyListeners();

        try {
          if (_chapterId != null) {
            final updated = await _apiService.redoText(_chapterId!, i);
            _texts.clear();
            _texts.addAll(updated);
            notifyListeners();
          }
        } catch (e) {
          print('Error marking text as redo: $e');
        }
        break;
      }
    }
  }

  void _handleReread(int count) {
    final active = activeTexts;
    if (active.isEmpty) return;

    final toRead = active.length >= count
        ? active.sublist(active.length - count)
        : active;

    final text = toRead.map((t) => t.textPiece).join('\n\n');

    _dictationService.sendTextMessage(
      'Please read the following text aloud exactly as written, do not return JSON, just speak it: $text',
    );
  }

  void _handleStateChange(DictationState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _stateSub?.cancel();
    _dictationService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

@pragma('vm:entry-point')
void _foregroundCallback() {
  FlutterForegroundTask.setTaskHandler(_DictatorTaskHandler());
}

class _DictatorTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isAppTerminated) async {}
}
