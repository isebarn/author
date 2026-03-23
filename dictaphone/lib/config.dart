import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String realtimeModel = 'gpt-4o-realtime-preview-2024-12-17';
  static const String realtimeUrl = 'wss://api.openai.com/v1/realtime';

  static String get apiBaseUrl {
    const dartDefineUrl = String.fromEnvironment('SERVER_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;
    return dotenv.env['SERVER_URL'] ?? 'http://192.168.1.75:3010';
  }

  static const String systemPrompt = '''
You are a dictation transcriber. The user is dictating a fiction story out loud.

YOUR ONLY JOB: Repeat back EXACTLY what the user said. You may ONLY:
- Fix obvious grammar mistakes
- Add proper punctuation
- Format spoken dialogue with double quotes
- Use *italics* if the user indicates internal thoughts

STRICT RULES:
- NEVER add words, phrases, descriptions, or actions the user did not say
- NEVER extend or continue what the user said
- NEVER add "she said", "he whispered", scene descriptions, or any embellishment
- NEVER interpret or expand on the user's words
- If the user says "where is the corn" you say EXACTLY "Where is the corn?"
- If the user says "John said hello" you say EXACTLY: John said, "Hello."
- Your output must contain ONLY the user's words, properly punctuated

You are a transcriber, not a writer. Zero creative additions.
''';

  static const int silenceTimeoutMs = 5000;
  static const int audioSampleRate = 24000;
  static const int audioChannels = 1;
  static const int audioBitsPerSample = 16;
}
