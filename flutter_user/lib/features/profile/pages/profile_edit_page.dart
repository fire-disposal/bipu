import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
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
  late final TextEditingController _birthTimeCtrl;
  late final TextEditingController _birthplaceCtrl;
  late final TextEditingController _fortuneTimeCtrl;
  String? _gender;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _fortuneTimeCtrl = TextEditingController(text: ''); // TODO: 从用户资料获取推送时间
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _birthdayCtrl = TextEditingController(
      text: user?.cosmicProfile?['birthday'] ?? '',
    );
    _zodiacCtrl = TextEditingController(
      text: user?.cosmicProfile?['zodiac'] ?? '',
    );
    _baziCtrl = TextEditingController(text: user?.cosmicProfile?['bazi'] ?? '');
    _mbtiCtrl = TextEditingController(text: user?.cosmicProfile?['mbti'] ?? '');
    _birthTimeCtrl = TextEditingController(
      text: user?.cosmicProfile?['birth_time'] ?? '',
    );
    _birthplaceCtrl = TextEditingController(
      text: user?.cosmicProfile?['birthplace'] ?? '',
    );
    _gender = user?.cosmicProfile?['gender'] as String?;
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
    _birthTimeCtrl.dispose();
    _birthplaceCtrl.dispose();
    _fortuneTimeCtrl.dispose();
    // _gender 不需要 dispose
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
        if (_birthTimeCtrl.text.isNotEmpty) 'birth_time': _birthTimeCtrl.text,
        if (_birthplaceCtrl.text.isNotEmpty) 'birthplace': _birthplaceCtrl.text,
        if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
      };

      // 更新基本资料
      final updated = await ProfileService().updateProfile(
        nickname: _nicknameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        cosmicProfile: cosmicProfile.isNotEmpty ? cosmicProfile : null,
      );

      // 更新推送时间设置（如果已设置）
      if (_fortuneTimeCtrl.text.isNotEmpty) {
        try {
          await ProfileService().updatePushTime(
            fortuneTime: _fortuneTimeCtrl.text.trim(),
          );
        } catch (e) {
          // 推送时间更新失败不影响整体保存，但记录日志
          if (mounted) {
            ToastService().showWarning('资料已保存，但推送时间设置失败');
          }
        }
      }

      AuthService().fetchCurrentUser();
      if (mounted) {
        ToastService().showSuccess('资料已更新');
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) ToastService().showError('更新失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // 获取主题数据在异步操作之前
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
      // 压缩图片：限制在100x100像素，质量0.7
      final compressedFile = await _compressAvatar(File(croppedFile.path));
      await ProfileService().uploadAvatar(compressedFile);
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

  Future<File> _compressAvatar(File originalFile) async {
    // 读取原始图片
    final bytes = await originalFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('无法解码图片');
    }

    // 压缩到100x100像素
    final thumbnail = img.copyResize(image, width: 100, height: 100);

    // 编码为JPEG，质量0.7
    final compressedBytes = img.encodeJpg(thumbnail, quality: 70);

    // 保存到临时文件
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
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

  Future<void> _selectFortuneTime() async {
    final currentTime = _fortuneTimeCtrl.text;
    TimeOfDay? initialTime;

    if (currentTime.isNotEmpty) {
      try {
        final parts = currentTime.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {
        // 忽略解析错误，使用当前时间
      }
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _fortuneTimeCtrl.text =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: UserAvatar(
                    avatarUrl: AuthService().currentUser?.avatarUrl,
                    displayName:
                        AuthService().currentUser?.nickname ??
                        AuthService().currentUser?.username ??
                        '用户',
                    radius: 48,
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
                  '推送设置',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fortuneTimeCtrl,
                  readOnly: true,
                  onTap: _selectFortuneTime,
                  decoration: const InputDecoration(
                    labelText: '运势推送时间',
                    prefixIcon: Icon(Icons.notifications_active),
                    suffixIcon: Icon(Icons.access_time),
                    helperText: '设置每日运势推送的时间',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final reg = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');
                    if (!reg.hasMatch(v)) return '时间格式应为 HH:MM';
                    return null;
                  },
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final reg = RegExp(r'^\d{4}-\d{2}-\d{2}\$');
                    if (!reg.hasMatch(v)) return '生日格式应为 YYYY-MM-DD';
                    try {
                      DateTime.parse(v);
                      return null;
                    } catch (_) {
                      return '无效的日期';
                    }
                  },
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
                TextFormField(
                  controller: _birthTimeCtrl,
                  decoration: const InputDecoration(
                    labelText: '出生时间',
                    prefixIcon: Icon(Icons.access_time),
                    helperText: '可选，格式如 08:30',
                  ),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final reg = RegExp(
                      r'^([01]?\d|2[0-3]):[0-5]\d(:[0-5]\d)?\$',
                    );
                    if (!reg.hasMatch(v)) return '时间格式应为 HH:MM 或 HH:MM:SS';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _birthplaceCtrl,
                  decoration: const InputDecoration(
                    labelText: '出生地',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    helperText: '可选，填写城市或详细地址',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length > 100) return '出生地不应超过100字符';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _gender != null && _gender!.isNotEmpty
                      ? _gender
                      : null,
                  decoration: const InputDecoration(
                    labelText: '性别',
                    prefixIcon: Icon(Icons.transgender),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('男')),
                    DropdownMenuItem(value: 'female', child: Text('女')),
                    DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) {
                    // optional, but if provided ensure value from list
                    if (v == null || v.isEmpty) return null;
                    if (!['male', 'female', 'other'].contains(v)) {
                      return '请选择有效性别';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _mbtiCtrl.text.isNotEmpty
                      ? _mbtiCtrl.text
                      : null,
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
                  onChanged: (value) {
                    setState(() => _mbtiCtrl.text = value ?? '');
                  },
                ),
                const SizedBox(height: 48),
                AppButton(
                  text: '保存修改',
                  onPressed:
                      (!_saving && (_formKey.currentState?.validate() ?? true))
                      ? _save
                      : null,
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
