import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../api/api.dart';
import '../../../api/message_api.dart';
import '../../../models/favorite/favorite.dart';
import '../../../models/message/message_response.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/toast_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MessageApi _messageApi = MessageApi();
  final AuthService _authService = AuthService();

  List<Favorite> _favorites = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      if (refresh) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          _isRefreshing = true;
        });
      } else {
        setState(() => _isLoading = true);
      }

      final response = await _messageApi.getFavorites(
        page: _currentPage,
        size: _pageSize,
      );

      setState(() {
        if (refresh || _currentPage == 1) {
          _favorites = response.items;
        } else {
          _favorites.addAll(response.items);
        }

        _hasMore = response.items.length == _pageSize;
        if (!refresh && response.items.isNotEmpty) {
          _currentPage++;
        }
      });
    } catch (e) {
      ToastService().showError(
        'load_favorites_failed'.tr(args: [e.toString()]),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _removeFavorite(Favorite favorite) async {
    try {
      await _messageApi.removeFavorite(favorite.messageId);

      setState(() {
        _favorites.removeWhere((f) => f.id == favorite.id);
      });

      ToastService().showSuccess('unfavorited'.tr());
    } catch (e) {
      ToastService().showError(
        'remove_favorite_failed'.tr(args: [e.toString()]),
      );
    }
  }

  void _showFavoriteDetails(Favorite favorite) {
    if (favorite.message != null) {
      context.push('/messages/detail', extra: favorite.message);
    }
  }

  void _showDeleteConfirmation(Favorite favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_remove'.tr()),
        content: Text('remove_favorite_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFavorite(favorite);
            },
            child: Text(
              'remove'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    final message = favorite.message;
    final currentUser = _authService.currentUser;
    final isFromMe = currentUser?.bipupuId == message?.senderBipupuId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Colors.amber),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null)
              Text(
                isFromMe
                    ? 'sent_to'.tr(args: [message.receiverBipupuId])
                    : 'received_from'.tr(args: [message.senderBipupuId]),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            if (favorite.note != null && favorite.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  favorite.note!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: message != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    message.content.length > 60
                        ? '${message.content.substring(0, 60)}...'
                        : message.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              )
            : Text('message_deleted'.tr()),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
          onPressed: () => _showDeleteConfirmation(favorite),
        ),
        onTap: () => _showFavoriteDetails(favorite),
        onLongPress: () => _showDeleteConfirmation(favorite),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'no_favorites'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_favorites_hint'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/messages'),
            icon: const Icon(Icons.message),
            label: Text('go_to_messages'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_favorites'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadFavorites(refresh: true),
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计信息
          if (_favorites.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total_favorites'.tr(args: [_favorites.length.toString()]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_favorites.any(
                    (f) => f.note != null && f.note!.isNotEmpty,
                  ))
                    Text(
                      '${_favorites.where((f) => f.note != null && f.note!.isNotEmpty).length} ${'with_notes'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          // 收藏列表
          Expanded(
            child: _isLoading && _favorites.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => _loadFavorites(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _favorites.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _favorites.length) {
                          if (_hasMore && !_isLoading) {
                            _loadFavorites();
                          }
                          return _hasMore
                              ? _buildLoadingIndicator()
                              : const SizedBox.shrink();
                        }
                        return _buildFavoriteCard(_favorites[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
