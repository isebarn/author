import 'dart:async';
import 'dart:typed_data';
import '../models/models.dart';

enum DictationState {
  disconnected,
  connecting,
  connected,
  listening,
  processing,
  speaking,
  error,
}

abstract class DictationService {
  Stream<DictationResult> get onResult;
  Stream<Uint8List> get onAudioOutput;
  Stream<DictationState> get onStateChange;
  DictationState get currentState;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> startListening();
  Future<void> stopListening();

  /// Send a text message to the AI (used for reread commands)
  Future<void> sendTextMessage(String text);

  void dispose();
}
