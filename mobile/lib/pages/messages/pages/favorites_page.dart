import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteResponse> _favorites = [];
  bool _loading = false;
  int _currentPage = 1;
  int _totalFavorites = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.api.messages
          .getApiMessagesFavorites(page: page, pageSize: _pageSize);
      setState(() {
        _favorites = resp.favorites;
        _currentPage = page;
        _totalFavorites = resp.total;
      });
    } on ApiException catch (e) {
      debugPrint('Load favorites error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('load_favorites_failed'.tr())));
      }
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
      _loadFavorites(page: _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasNextPage = _currentPage * _pageSize < _totalFavorites;

    return Scaffold(
      appBar: AppBar(title: Text('my_favorites'.tr()), elevation: 0),
      body: _loading && _favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_favorites'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFavorites(page: 1),
              child: ListView.separated(
                itemCount: _favorites.length + (hasNextPage ? 1 : 0),
                separatorBuilder: (_, index) {
                  if (index == _favorites.length) {
                    return const SizedBox.shrink();
                  }
                  return const Divider(height: 1);
                },
                itemBuilder: (context, index) {
                  if (index == _favorites.length) {
                    // 加载更多按钮
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () =>
                              _loadFavorites(page: _currentPage + 1),
                          child: Text('load_more'.tr()),
                        ),
                      ),
                    );
                  }

                  final fav = _favorites[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        // 可以跳转到消息详情页面
                        // context.push('/messages/detail', extra: message);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'From: ${fav.messageSender}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        fav.messageContent,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeFavorite(fav),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (fav.note != null && fav.note!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      'Note: ${fav.note}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                Text(
                                  DateFormat(
                                    'MM-dd HH:mm',
                                  ).format(fav.messageCreatedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
