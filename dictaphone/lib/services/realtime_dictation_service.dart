import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../models/models.dart';
import 'audio_player_service.dart';
import 'dictation_service.dart';

class RealtimeDictationService extends DictationService {
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayerService _audioPlayer;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _wsSubscription;

  final _resultController = StreamController<DictationResult>.broadcast();
  final _audioOutputController = StreamController<Uint8List>.broadcast();
  final _stateController = StreamController<DictationState>.broadcast();

  DictationState _currentState = DictationState.disconnected;

  String _responseTextBuffer = '';
  bool _responseTextHandled = false;
  bool _pendingCancel = false;

  RealtimeDictationService({required AudioPlayerService audioPlayer})
      : _audioPlayer = audioPlayer {
    // When audio playback completes, go back to listening
    _audioPlayer.onPlaybackComplete = () {
      print('Playback complete, clearing buffer and restarting mic');
      _sendEvent({'type': 'input_audio_buffer.clear'});
      // Restart the recorder — playback kills the mic stream
      _startRecorderStream();
    };
  }

  @override
  Stream<DictationResult> get onResult => _resultController.stream;

  @override
  Stream<Uint8List> get onAudioOutput => _audioOutputController.stream;

  @override
  Stream<DictationState> get onStateChange => _stateController.stream;

  @override
  DictationState get currentState => _currentState;

  void _setState(DictationState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> connect() async {
    if (_currentState != DictationState.disconnected &&
        _currentState != DictationState.error) {
      return;
    }

    _setState(DictationState.connecting);

    try {
      final uri = Uri.parse(
          '${AppConfig.realtimeUrl}?model=${AppConfig.realtimeModel}');

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['realtime', 'openai-insecure-api-key.${AppConfig.openAiApiKey}', 'openai-beta.realtime-v1'],
      );

      await _channel!.ready;

      _wsSubscription = _channel!.stream.listen(
        _handleWsMessage,
        onError: (error) {
          print('WebSocket error: $error');
          _setState(DictationState.error);
        },
        onDone: () {
          print('WebSocket closed');
          _setState(DictationState.disconnected);
        },
      );

      // Configure the session
      _sendEvent({
        'type': 'session.update',
        'session': {
          'modalities': ['text', 'audio'],
          'instructions': AppConfig.systemPrompt,
          'voice': 'echo',
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'input_audio_transcription': {
            'model': 'whisper-1',
          },
          'turn_detection': {
            'type': 'server_vad',
            'threshold': 0.5,
            'prefix_padding_ms': 300,
            'silence_duration_ms': AppConfig.silenceTimeoutMs,
          },
        },
      });

      _setState(DictationState.connected);
    } catch (e) {
      print('Connection error: $e');
      _setState(DictationState.error);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await stopListening();
    _wsSubscription?.cancel();
    _wsSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(DictationState.disconnected);
  }

  @override
  Future<void> startListening() async {
    if (_channel == null) {
      throw StateError('Not connected. Call connect() first.');
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission not granted.');
    }

    await _startRecorderStream();
  }

  Future<void> _startRecorderStream() async {
    // Stop any existing recording first
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    // Start recording as a stream of PCM16 data
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: AppConfig.audioSampleRate,
        numChannels: AppConfig.audioChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    int chunkCount = 0;
    _recorderSubscription = stream.listen(
      (data) {
        chunkCount++;
        if (chunkCount % 100 == 1) {
          print('Audio chunk #$chunkCount, size=${data.length}');
        }
        final base64Audio = base64Encode(data);
        _sendEvent({
          'type': 'input_audio_buffer.append',
          'audio': base64Audio,
        });
      },
      onError: (error) {
        print('Recorder stream error: $error');
      },
    );

    _setState(DictationState.listening);
    print('Recorder stream started');
  }

  @override
  Future<void> stopListening() async {
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    if (_currentState == DictationState.listening) {
      _setState(DictationState.connected);
    }
  }

  @override
  Future<void> sendTextMessage(String text) async {
    if (_channel == null) {
      throw StateError('Not connected.');
    }

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': text,
          }
        ],
      },
    });

    _sendEvent({
      'type': 'response.create',
      'response': {
        'modalities': ['text', 'audio'],
      },
    });
  }

  void _sendEvent(Map<String, dynamic> event) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(event));
      } catch (e) {
        print('Error sending event ${event['type']}: $e');
      }
    }
  }

  void _handleWsMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'session.created':
        case 'session.updated':
          print('Session event: $type');
          break;

        case 'input_audio_buffer.speech_started':
          print('Speech started');
          _audioPlayer.stop().catchError((e) {
            print('Error stopping audio: $e');
          });
          _pendingCancel = false;
          break;

        case 'input_audio_buffer.speech_stopped':
          print('Speech stopped - processing');
          _setState(DictationState.processing);
          break;

        case 'input_audio_buffer.committed':
          print('Audio buffer committed');
          break;

        // Raw Whisper transcription of what the user said
        case 'conversation.item.input_audio_transcription.completed':
          final rawTranscript =
              (data['transcript'] as String? ?? '').trim().toLowerCase();
          print('Raw whisper transcript: "$rawTranscript"');

          // Check if it's a command
          if (_isCommand(rawTranscript)) {
            print('Detected command: $rawTranscript');
            _pendingCancel = true;
            // Cancel the auto-generated model response
            _sendEvent({'type': 'response.cancel'});
            _handleCommandFromTranscript(rawTranscript);
          }
          break;

        case 'response.created':
          _responseTextBuffer = '';
          _responseTextHandled = false;
          // Clear audio buffer so noise during response doesn't confuse VAD later
          _sendEvent({'type': 'input_audio_buffer.clear'});
          if (!_pendingCancel) {
            _audioPlayer.startAccumulating();
          }
          break;

        // Model's formatted text response (audio transcript = what model says)
        case 'response.audio_transcript.delta':
          if (!_pendingCancel) {
            final delta = data['delta'] as String? ?? '';
            _responseTextBuffer += delta;
          }
          break;

        case 'response.audio_transcript.done':
          if (!_pendingCancel) {
            final fullText =
                data['transcript'] as String? ?? _responseTextBuffer;
            print('Model formatted response: $fullText');
            // This is the formatted prose — add it as a transcription
            _resultController.add(DictationResult(
              mode: DictationResultMode.transcribe,
              data: fullText.trim(),
            ));
            _responseTextHandled = true;
          }
          break;

        case 'response.text.delta':
          if (!_pendingCancel) {
            final delta = data['delta'] as String? ?? '';
            _responseTextBuffer += delta;
          }
          break;

        case 'response.text.done':
          if (!_pendingCancel) {
            final fullText = data['text'] as String? ?? _responseTextBuffer;
            _resultController.add(DictationResult(
              mode: DictationResultMode.transcribe,
              data: fullText.trim(),
            ));
            _responseTextHandled = true;
          }
          break;

        case 'response.audio.delta':
          if (!_pendingCancel) {
            final audioBase64 = data['delta'] as String?;
            if (audioBase64 != null) {
              if (_currentState != DictationState.speaking) {
                _setState(DictationState.speaking);
              }
              _audioPlayer.addPcmChunk(base64Decode(audioBase64));
            }
          }
          break;

        case 'response.audio.done':
          print('Audio response done');
          break;

        case 'response.done':
          final status = data['response']?['status'] as String? ?? '';
          print('Response done (status: $status). Text handled: $_responseTextHandled, recorder active: ${_recorderSubscription != null}');

          if (!_pendingCancel && !_responseTextHandled && _responseTextBuffer.isNotEmpty) {
            _resultController.add(DictationResult(
              mode: DictationResultMode.transcribe,
              data: _responseTextBuffer.trim(),
            ));
          }

          _responseTextBuffer = '';
          _responseTextHandled = false;
          final wasCancelled = _pendingCancel;
          _pendingCancel = false;

          if (!wasCancelled) {
            // Set speaking state; playback callback will set listening when done
            _setState(DictationState.speaking);
            _audioPlayer.playAccumulated();
          } else {
            if (_recorderSubscription != null) {
              _setState(DictationState.listening);
            } else {
              _setState(DictationState.connected);
            }
          }
          break;

        case 'response.cancelled':
          print('Response cancelled');
          _pendingCancel = false;
          _responseTextBuffer = '';
          _responseTextHandled = false;
          if (_recorderSubscription != null) {
            _setState(DictationState.listening);
          }
          break;

        case 'error':
          final errorData = data['error'] as Map<String, dynamic>?;
          final errorMsg = errorData?['message'] ?? 'Unknown error';
          final errorCode = errorData?['code'] ?? '';
          print('Realtime API error: [$errorCode] $errorMsg');
          if (errorCode == 'session_expired' ||
              errorCode == 'invalid_api_key') {
            _setState(DictationState.error);
          }
          break;

        case 'conversation.item.created':
        case 'response.output_item.added':
        case 'response.output_item.done':
        case 'response.content_part.added':
        case 'response.content_part.done':
        case 'rate_limits.updated':
        case 'conversation.item.input_audio_transcription.failed':
          break;

        default:
          print('Unhandled event: $type');
          break;
      }
    } catch (e) {
      print('Error processing WS message: $e');
    }
  }

  bool _isCommand(String transcript) {
    final cleaned = transcript
        .replaceAll(RegExp(r'[.,!?]'), '')
        .trim()
        .toLowerCase();
    if (cleaned == 'redo' || cleaned == 'undo') return true;
    if (cleaned == 'reread' || cleaned.startsWith('reread ') ||
        cleaned.startsWith('re-read') || cleaned == 're read') return true;
    return false;
  }

  void _handleCommandFromTranscript(String transcript) {
    final cleaned = transcript
        .replaceAll(RegExp(r'[.,!?]'), '')
        .trim()
        .toLowerCase();

    if (cleaned == 'redo' || cleaned == 'undo') {
      _resultController.add(DictationResult(
        mode: DictationResultMode.command,
        data: 'redo',
      ));
    } else if (cleaned.startsWith('reread') ||
        cleaned.startsWith('re-read') ||
        cleaned.startsWith('re read')) {
      // Extract number
      final parts = cleaned.split(RegExp(r'\s+'));
      int count = 1;
      if (parts.length > 1) {
        count = int.tryParse(parts.last) ?? 1;
      }
      _resultController.add(DictationResult(
        mode: DictationResultMode.command,
        data: 'reread:$count',
      ));
    }
  }

  @override
  void dispose() {
    disconnect();
    _resultController.close();
    _audioOutputController.close();
    _stateController.close();
    _recorder.dispose();
  }
}
