import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/dictation_service.dart';
import '../services/story_manager.dart';

class StoryScreen extends StatefulWidget {
  final int chapterId;
  final String chapterName;

  const StoryScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Load existing chapter content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryManager>().loadChapter(widget.chapterId);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    // Stop session if active when leaving screen
    final manager = context.read<StoryManager>();
    if (manager.isActive) {
      manager.stopSession();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryManager>(
      builder: (context, manager, child) {
        if (manager.texts.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF16213E),
            title: Text(
              widget.chapterName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white38),
          ),
          body: Column(
            children: [
              _buildStatusBar(manager),
              Expanded(child: _buildStoryContent(manager)),
              _buildMicButton(manager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(StoryManager manager) {
    String statusText;
    Color statusColor;

    switch (manager.state) {
      case DictationState.disconnected:
        statusText = 'Tap mic to start';
        statusColor = Colors.white38;
        break;
      case DictationState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.amber;
        break;
      case DictationState.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case DictationState.listening:
        statusText = '● Listening...';
        statusColor = Colors.redAccent;
        break;
      case DictationState.processing:
        statusText = 'Processing...';
        statusColor = Colors.amber;
        break;
      case DictationState.speaking:
        statusText = '🔊 Reading back...';
        statusColor = Colors.blueAccent;
        break;
      case DictationState.error:
        statusText = 'Error: ${manager.errorMessage ?? "Unknown"}';
        statusColor = Colors.red;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF16213E),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStoryContent(StoryManager manager) {
    final markdown = manager.storyMarkdown;

    if (markdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 64,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Start dictating your chapter.\nTap the microphone and speak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Say "redo" to redo last paragraph\n'
                'Say "reread 3" to hear last 3 paragraphs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: MarkdownBody(
          data: markdown,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.8,
              fontFamily: 'Georgia',
            ),
            em: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.8,
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia',
            ),
            del: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 16,
              height: 1.8,
              decoration: TextDecoration.lineThrough,
              fontFamily: 'Georgia',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(StoryManager manager) {
    final isActive = manager.isActive;

    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 16),
      child: GestureDetector(
        onTap: () async {
          if (isActive) {
            await manager.stopSession();
          } else {
            // Request both microphone and notification permissions
            final micStatus = await Permission.microphone.request();
            await Permission.notification.request();
            if (micStatus.isGranted) {
              await manager.startSession(widget.chapterId);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Microphone permission is required'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isActive ? 1.0 + (_pulseController.value * 0.1) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.redAccent.withValues(alpha: 0.9)
                      : const Color(0xFF0F3460),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isActive ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
