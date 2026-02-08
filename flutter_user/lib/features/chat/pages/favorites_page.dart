import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/message/message_response.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _api = bipupuApi;
  List<MessageResponse> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.getFavoriteMessages(page: 1, size: 50);
      setState(() => _items = resp.items);
    } catch (e) {
      debugPrint('Load favorites error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(MessageResponse m) async {
    try {
      // optimistic UI: remove from list
      setState(() => _items.removeWhere((it) => it.id == m.id));
      await bipupuApi.unfavoriteMessage(m.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已取消收藏')));
    } catch (e) {
      debugPrint('Unfavorite failed: $e');
      // reload to be safe
      await _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(child: Text('暂无收藏'))
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = _items[index];
                  return ListTile(
                    title: Text(
                      m.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${m.createdAt} • 用户 ${m.senderId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () => _toggleFavorite(m),
                    ),
                    onTap: () => Navigator.pop(context),
                  );
                },
              ),
      ),
    );
  }
}
