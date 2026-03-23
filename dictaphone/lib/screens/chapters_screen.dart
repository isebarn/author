import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'story_screen.dart';

class _FolderNode {
  final int id;
  final int? parent;
  final String title;
  final List<_FolderNode> children = [];

  _FolderNode({required this.id, required this.parent, required this.title});
}

List<_FolderNode> _buildTree(List<Map<String, dynamic>> folders) {
  final map = <int, _FolderNode>{};
  for (final f in folders) {
    map[f['id'] as int] = _FolderNode(
      id: f['id'] as int,
      parent: f['parent'] as int?,
      title: f['title'] as String,
    );
  }
  final roots = <_FolderNode>[];
  for (final node in map.values) {
    final p = node.parent;
    if (p == null || !map.containsKey(p)) {
      roots.add(node);
    } else {
      map[p]!.children.add(node);
    }
  }
  return roots;
}

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _folders = [];
  bool _loading = true;
  String? _error;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await _api.listChapters();
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createFolder({int? parentId}) async {
    final label = parentId == null ? 'New Folder' : 'New Subfolder';
    final name = await _showNameDialog(label);
    if (name == null || name.trim().isEmpty) return;
    try {
      final folder = await _api.createChapter(name.trim(), parentId: parentId);
      if (mounted) {
        if (parentId != null) {
          setState(() => _expanded.add(parentId));
        }
        await _loadFolders();
        if (mounted) {
          _openFolder(folder['id'] as int, folder['title'] as String);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<String?> _showNameDialog(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openFolder(int id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryScreen(chapterId: id, chapterName: name),
      ),
    ).then((_) => _loadFolders());
  }

  Widget _buildFolderTile(_FolderNode node, int depth) {
    final isExpanded = _expanded.contains(node.id);
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: const Color(0xFF16213E),
          margin: EdgeInsets.only(
            left: depth * 16.0,
            right: 0,
            bottom: 4,
          ),
          child: ListTile(
            dense: depth > 0,
            leading: hasChildren
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onPressed: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(node.id);
                      } else {
                        _expanded.add(node.id);
                      }
                    }),
                  )
                : const Icon(Icons.article_outlined, color: Colors.white24),
            title: Text(
              node.title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: depth > 0 ? 14 : 16,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.create_new_folder_outlined,
                  color: Colors.white24, size: 18),
              tooltip: 'Add subfolder',
              onPressed: () => _createFolder(parentId: node.id),
            ),
            onTap: () => _openFolder(node.id, node.title),
          ),
        ),
        if (hasChildren && isExpanded)
          ...node.children.map((child) => _buildFolderTile(child, depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildTree(_folders);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Dictaphone',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFolders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : tree.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            'No folders yet.\nTap + to start writing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFolders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: tree
                            .map((node) => _buildFolderTile(node, 0))
                            .toList(),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createFolder(),
        backgroundColor: const Color(0xFF0F3460),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
