import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteResponse> _favorites = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.api.messages
          .getApiMessagesFavorites(page: 1, pageSize: 50);
      setState(() => _favorites = resp.favorites);
    } on ApiException catch (e) {
      debugPrint('Load favorites error: ${e.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(FavoriteResponse fav) async {
    try {
      setState(() => _favorites.removeWhere((f) => f.id == fav.id));
      await ApiClient.instance.api.messages.deleteApiMessagesMessageIdFavorite(
        messageId: fav.messageId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('unfavorited'.tr())));
      }
    } on ApiException catch (e) {
      debugPrint('Unfavorite failed: ${e.message}');
      _loadFavorites();
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
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final fav = _favorites[index];

                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.amber),
                    title: Text(fav.messageContent),
                    subtitle: Text(
                      '${'sender'.tr(args: [fav.messageSender])}  \n${'note'.tr(args: [fav.note ?? ""])}',
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
