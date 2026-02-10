import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/favorite/favorite.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ImService _imService = ImService();
  List<Favorite> _favorites = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      // Assuming paginated, just getting first page for now
      final resp = await _imService.messageApi.getFavorites(page: 1, size: 50);
      setState(() => _favorites = resp.items);
    } catch (e) {
      debugPrint('Load favorites error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(Favorite fav) async {
    try {
      setState(() => _favorites.removeWhere((f) => f.id == fav.id));
      // Use messageId to remove favorite as per API: DELETE /api/messages/{message_id}/favorite
      await _imService.messageApi.removeFavorite(fav.messageId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('unfavorited'.tr())));
      }
    } catch (e) {
      debugPrint('Unfavorite failed: $e');
      _loadFavorites(); // Reload on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('my_favorites'.tr())),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    alignment: Alignment.center,
                    child: Text('no_favorites'.tr()),
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _favorites.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final fav = _favorites[index];
                  final msg = fav.message;

                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.amber),
                    title: Text(msg?.content ?? 'message_deleted'.tr()),
                    subtitle: Text(
                      '${'sender'.tr(args: [msg?.senderBipupuId ?? "Unknown"])}  \n${'note'.tr(args: [fav.note ?? ""])}',
                      maxLines: 2,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeFavorite(fav),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
