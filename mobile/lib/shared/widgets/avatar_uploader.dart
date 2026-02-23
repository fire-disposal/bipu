import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/theme/design_system.dart';
import '../../core/services/avatar_service.dart';
import 'user_avatar.dart';

/// 头像上传组件
///
/// 提供用户头像上传功能，支持：
/// - 从相册选择图片
/// - 从相机拍摄
/// - 图片裁剪
/// - 上传到服务器
/// - 显示上传进度
///
/// 使用示例：
/// ```dart
/// AvatarUploader(
///   bipupuId: 'user123',
///   radius: 50,
///   onUploadComplete: () => print('上传完成'),
/// )
/// ```
class AvatarUploader extends HookConsumerWidget {
  /// 用户的 bipupu_id
  final String bipupuId;

  /// 头像半径
  final double radius;

  /// 上传完成回调
  final VoidCallback? onUploadComplete;

  /// 上传失败回调
  final Function(String error)? onError;

  /// 是否显示编辑按钮
  final bool showEditButton;

  const AvatarUploader({
    super.key,
    required this.bipupuId,
    this.radius = 50,
    this.onUploadComplete,
    this.onError,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUploading = useState(false);
    final uploadProgress = useState(0.0);
    final errorMessage = useState<String?>(null);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickAndUploadAvatar() async {
      // 显示选择对话框
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择头像'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍摄照片'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      try {
        // 选择图片
        final pickedFile = await imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile == null) return;

        // 裁剪图片
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '裁剪头像',
              toolbarColor: theme.colorScheme.primary,
              toolbarWidgetColor: theme.colorScheme.onPrimary,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              title: '裁剪头像',
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile == null) return;

        // 读取图片数据
        final imageBytes = await File(croppedFile.path).readAsBytes();

        // 上传头像
        isUploading.value = true;
        uploadProgress.value = 0;
        errorMessage.value = null;

        // 模拟上传进度（实际上传是同步的）
        Future.delayed(const Duration(milliseconds: 100), () {
          uploadProgress.value = 0.3;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          uploadProgress.value = 0.6;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          uploadProgress.value = 0.9;
        });

        final avatarService = ref.read(avatarApiProvider);
        final result = await avatarService.uploadUserAvatar(imageBytes);

        uploadProgress.value = 1.0;

        if (result != null) {
          // 清除缓存，使新头像立即生效
          ref.read(avatarCacheProvider.notifier).clearUserAvatarCache(bipupuId);

          onUploadComplete?.call();
        } else {
          errorMessage.value = '上传失败，请稍后重试';
          onError?.call('上传失败');
        }
      } catch (e) {
        errorMessage.value = '上传失败：$e';
        onError?.call(e.toString());
      } finally {
        isUploading.value = false;
        uploadProgress.value = 0;
      }
    }

    return Stack(
      children: [
        // 头像显示
        UserAvatar(
          bipupuId: bipupuId,
          radius: radius,
          showLoadingIndicator: isUploading.value,
          borderWidth: isUploading.value ? 0 : 2,
        ),

        // 上传进度指示器（环形）
        if (isUploading.value)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: CircularProgressIndicator(
                  value: uploadProgress.value,
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

        // 编辑按钮
        if (showEditButton && !isUploading.value)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  size: radius * 0.8,
                  color: theme.colorScheme.onPrimary,
                ),
                padding: EdgeInsets.all(radius * 0.4),
                onPressed: pickAndUploadAvatar,
              ),
            ),
          ),

        // 错误提示
        if (errorMessage.value != null)
          Positioned(
            bottom: -radius,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                errorMessage.value!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// 简化的头像上传按钮
///
/// 只显示一个按钮，点击后上传头像
class AvatarUploadButton extends HookConsumerWidget {
  final String bipupuId;
  final VoidCallback? onUploadComplete;
  final Function(String error)? onError;

  const AvatarUploadButton({
    super.key,
    required this.bipupuId,
    this.onUploadComplete,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUploading = useState(false);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> handleUpload() async {
      if (isUploading.value) return;

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择头像'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍摄照片'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      try {
        isUploading.value = true;

        final pickedFile = await imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile == null) return;

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '裁剪头像',
              toolbarColor: theme.colorScheme.primary,
              toolbarWidgetColor: theme.colorScheme.onPrimary,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: '裁剪头像',
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile == null) return;

        final imageBytes = await File(croppedFile.path).readAsBytes();

        final avatarService = ref.read(avatarApiProvider);
        final result = await avatarService.uploadUserAvatar(imageBytes);

        if (result != null) {
          ref.read(avatarCacheProvider.notifier).clearUserAvatarCache(bipupuId);
          onUploadComplete?.call();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('头像上传成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('头像上传失败，请稍后重试'),
                backgroundColor: Colors.red,
              ),
            );
          }
          onError?.call('上传失败');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败：$e'), backgroundColor: Colors.red),
          );
        }
        onError?.call(e.toString());
      } finally {
        isUploading.value = false;
      }
    }

    return ShadButton(
      onPressed: isUploading.value ? null : handleUpload,
      child: isUploading.value
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('上传中...'),
              ],
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 16),
                SizedBox(width: 4),
                Text('更换头像'),
              ],
            ),
    );
  }
}
