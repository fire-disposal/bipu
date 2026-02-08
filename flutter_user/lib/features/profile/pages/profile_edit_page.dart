import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_user/api/api.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/toast_service.dart';
import '../../common/widgets/app_button.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ProfileService().updateProfile(
        nickname: _nicknameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      AuthService().fetchCurrentUser();
      if (mounted) {
        ToastService().showSuccess('资料已更新');
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) ToastService().showError('更新失败�?e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final theme = Theme.of(context);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          toolbarColor: theme.primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: '裁剪头像', aspectRatioLockEnabled: true),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _saving = true);
    try {
      await ProfileService().uploadAvatar(File(croppedFile.path));
      await AuthService().fetchCurrentUser();
      if (mounted) {
        ToastService().showSuccess('头像已更新');
      }
    } catch (e) {
      if (mounted) ToastService().showError('上传失败�?e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '个人资料',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage:
                              AuthService().currentUser?.avatarUrl != null
                              ? CachedNetworkImageProvider(
                                  AuthService().currentUser!.avatarUrl!
                                          .startsWith('http')
                                      ? AuthService().currentUser!.avatarUrl!
                                      : '${bipupuHttp.options.baseUrl}${AuthService().currentUser!.avatarUrl}',
                                )
                              : null,
                          child: AuthService().currentUser?.avatarUrl == null
                              ? Text(
                                  (_nicknameCtrl.text.isNotEmpty
                                          ? _nicknameCtrl.text
                                          : _usernameCtrl.text)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  '基础信息',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameCtrl,
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: '唯一标识，用于好友搜索',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '用户名不能为空' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: '电子邮箱',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? '请输入有效邮箱' : null,
                ),
                const SizedBox(height: 48),
                AppButton(
                  text: '保存修改',
                  onPressed: _save,
                  isLoading: _saving,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
