import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'screens/chapters_screen.dart';
import 'services/api_service.dart';
import 'services/audio_player_service.dart';
import 'services/realtime_dictation_service.dart';
import 'services/story_manager.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DictatorTaskHandler());
}

class DictatorTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isAppTerminated) async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dictator_channel',
      channelName: 'Dictator Recording',
      channelDescription: 'Recording audio for story dictation',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  final audioPlayer = AudioPlayerService();
  final dictationService = RealtimeDictationService(audioPlayer: audioPlayer);
  final apiService = ApiService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => StoryManager(
        dictationService: dictationService,
        apiService: apiService,
        audioPlayer: audioPlayer,
      ),
      child: const DictatorApp(),
    ),
  );
}

class DictatorApp extends StatelessWidget {
  const DictatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dictator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3460),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WithForegroundTask(
        child: ChaptersScreen(),
      ),
    );
  }
}
