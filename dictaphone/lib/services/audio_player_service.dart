import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

/// Plays raw PCM16 audio chunks at 24kHz by accumulating them
/// and playing as a WAV when a response is complete.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final List<int> _pcmBuffer = [];
  bool _isAccumulating = false;
  void Function()? onPlaybackComplete;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        print('AudioPlayer: playback completed');
        onPlaybackComplete?.call();
      }
    });
  }

  void startAccumulating() {
    _pcmBuffer.clear();
    _isAccumulating = true;
  }

  void addPcmChunk(Uint8List chunk) {
    if (_isAccumulating) {
      _pcmBuffer.addAll(chunk);
    }
  }

  Future<void> playAccumulated() async {
    _isAccumulating = false;
    if (_pcmBuffer.isEmpty) {
      print('AudioPlayer: nothing to play');
      // Still fire callback so state machine progresses
      onPlaybackComplete?.call();
      return;
    }

    try {
      final pcmData = List<int>.from(_pcmBuffer);
      _pcmBuffer.clear();
      print('AudioPlayer: playing ${pcmData.length} bytes');

      final wavBytes = _pcm16ToWav(pcmData, 24000, 1, 16);
      final source = AudioSource.uri(
        Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav'),
      );

      await _player.setAudioSource(source);
      _player.play(); // Don't await — the listener handles completion
    } catch (e) {
      print('AudioPlayer play error: $e');
      onPlaybackComplete?.call();
    }
  }

  Future<void> stop() async {
    _isAccumulating = false;
    _pcmBuffer.clear();
    try {
      await _player.stop();
    } catch (e) {
      print('AudioPlayer stop error: $e');
    }
  }

  Uint8List _pcm16ToWav(
      List<int> pcmData, int sampleRate, int channels, int bitsPerSample) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM format
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    // PCM data
    for (int i = 0; i < dataSize; i++) {
      buffer.setUint8(44 + i, pcmData[i]);
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player.dispose();
  }
}
