import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/toast_service.dart';
import '../../common/widgets/app_button.dart';
import '../../../core/widgets/user_avatar.dart';

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
  late final TextEditingController _birthdayCtrl;
  late final TextEditingController _zodiacCtrl;
  late final TextEditingController _baziCtrl;
  late final TextEditingController _mbtiCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _birthdayCtrl = TextEditingController(
      text: user?.cosmicProfile?['birthday'] ?? '',
    );
    _zodiacCtrl = TextEditingController(
      text: user?.cosmicProfile?['zodiac'] ?? '',
    );
    _baziCtrl = TextEditingController(text: user?.cosmicProfile?['bazi'] ?? '');
    _mbtiCtrl = TextEditingController(text: user?.cosmicProfile?['mbti'] ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _birthdayCtrl.dispose();
    _zodiacCtrl.dispose();
    _baziCtrl.dispose();
    _mbtiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cosmicProfile = {
        if (_birthdayCtrl.text.isNotEmpty) 'birthday': _birthdayCtrl.text,
        if (_zodiacCtrl.text.isNotEmpty) 'zodiac': _zodiacCtrl.text,
        if (_baziCtrl.text.isNotEmpty) 'bazi': _baziCtrl.text,
        if (_mbtiCtrl.text.isNotEmpty) 'mbti': _mbtiCtrl.text,
      };
      final updated = await ProfileService().updateProfile(
        nickname: _nicknameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        cosmicProfile: cosmicProfile.isNotEmpty ? cosmicProfile : null,
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

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayCtrl.text = picked.toIso8601String().split('T').first;
        // 自动计算星座
        _zodiacCtrl.text = _getZodiacSign(picked);
      });
    }
  }

  String _getZodiacSign(DateTime date) {
    final month = date.month;
    final day = date.day;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return '水瓶座';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return '双鱼座';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return '白羊座';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return '金牛座';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return '双子座';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return '巨蟹座';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return '狮子座';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return '处女座';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return '天秤座';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return '天蝎座';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return '射手座';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return '摩羯座';
    return '';
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
                  child: UserAvatar(
                    avatarUrl: AuthService().currentUser?.avatarUrl,
                    displayName: _nicknameCtrl.text.isNotEmpty
                        ? _nicknameCtrl.text
                        : _usernameCtrl.text,
                    radius: 50,
                    onTap: _pickAndUploadImage,
                    showEditIcon: true,
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
                Text(
                  '宇宙信息',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdayCtrl,
                  readOnly: true,
                  onTap: _selectBirthday,
                  decoration: const InputDecoration(
                    labelText: '生日',
                    prefixIcon: Icon(Icons.cake_outlined),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _zodiacCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '星座',
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _baziCtrl,
                  decoration: const InputDecoration(
                    labelText: '生辰八字',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _mbtiCtrl.text.isNotEmpty ? _mbtiCtrl.text : null,
                  decoration: const InputDecoration(
                    labelText: 'MBTI',
                    prefixIcon: Icon(Icons.psychology_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'INTJ', child: Text('INTJ - 建筑师')),
                    DropdownMenuItem(value: 'INTP', child: Text('INTP - 思想家')),
                    DropdownMenuItem(value: 'ENTJ', child: Text('ENTJ - 指挥官')),
                    DropdownMenuItem(value: 'ENTP', child: Text('ENTP - 辩论家')),
                    DropdownMenuItem(value: 'INFJ', child: Text('INFJ - 提倡者')),
                    DropdownMenuItem(value: 'INFP', child: Text('INFP - 调停者')),
                    DropdownMenuItem(value: 'ENFJ', child: Text('ENFJ - 主人公')),
                    DropdownMenuItem(value: 'ENFP', child: Text('ENFP - 竞选者')),
                    DropdownMenuItem(value: 'ISTJ', child: Text('ISTJ - 物流师')),
                    DropdownMenuItem(value: 'ISFJ', child: Text('ISFJ - 守护者')),
                    DropdownMenuItem(value: 'ESTJ', child: Text('ESTJ - 执行官')),
                    DropdownMenuItem(value: 'ESFJ', child: Text('ESFJ - 执政官')),
                    DropdownMenuItem(value: 'ISTP', child: Text('ISTP - 鉴赏家')),
                    DropdownMenuItem(value: 'ISFP', child: Text('ISFP - 探险家')),
                    DropdownMenuItem(value: 'ESTP', child: Text('ESTP - 企业家')),
                    DropdownMenuItem(value: 'ESFP', child: Text('ESFP - 娱乐家')),
                  ],
                  onChanged: (value) =>
                      setState(() => _mbtiCtrl.text = value ?? ''),
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
