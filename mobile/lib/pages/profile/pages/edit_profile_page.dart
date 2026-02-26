import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/api/models/user_update.dart';
import '../../../../core/api/models/gender.dart';
import '../../../../core/services/snackbar_manager.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late AuthService _authService;
  late ApiClient _apiClient;
  late TextEditingController _nicknameController;
  late TextEditingController _mbtiController;
  late TextEditingController _birthTimeController;
  late TextEditingController _birthplaceController;
  late TextEditingController _zodiacController;
  late TextEditingController _baziController;

  DateTime? _birthday;
  Gender? _gender;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiClient = ApiClient.instance;

    final user = _authService.currentUser;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _mbtiController = TextEditingController(text: user?.mbti ?? '');
    _birthTimeController = TextEditingController(text: user?.birthTime ?? '');
    _birthplaceController = TextEditingController(text: user?.birthplace ?? '');
    _zodiacController = TextEditingController(text: user?.zodiac ?? '');
    _baziController = TextEditingController(text: user?.bazi ?? '');

    _birthday = user?.birthday;
    _gender = user?.gender;
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _mbtiController.dispose();
    _birthTimeController.dispose();
    _birthplaceController.dispose();
    _zodiacController.dispose();
    _baziController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    Future<void> _pickAndCropImage() async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image == null) return;

        // 裁剪图片
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'crop_avatar'.tr(),
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'crop_avatar'.tr(),
              aspectRatioLockEnabled: true,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );

        if (croppedFile == null) return;

        // 上传头像
        setState(() => _isUploadingAvatar = true);
        try {
          final updatedUser = await _apiClient.api.userProfile
              .postApiProfileAvatar(file: File(croppedFile.path));

          setState(() => _avatarUrl = updatedUser.avatarUrl);
          // 更新当前用户信息
          _authService.fetchCurrentUser();

          SnackBarManager.showSuccess('avatar_updated_success'.tr());
        } catch (e) {
          SnackBarManager.showError(
            'avatar_upload_failed'.tr(args: [e.toString()]),
          );
        } finally {
          setState(() => _isUploadingAvatar = false);
        }
      } catch (e) {
        SnackBarManager.showError(
          'image_selection_failed'.tr(args: [e.toString()]),
        );
      }
    }

    Future<void> _selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _birthday ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        locale: const Locale('zh', 'CN'),
      );

      if (picked != null) {
        setState(() => _birthday = picked);
      }
    }

    Future<void> _saveProfile() async {
      if (_nicknameController.text.trim().isEmpty) {
        SnackBarManager.showValidationError('nickname');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final updateData = UserUpdate(
          nickname: _nicknameController.text.trim(),
          birthday: _birthday,
          gender: _gender,
          mbti: _mbtiController.text.trim().isEmpty
              ? null
              : _mbtiController.text.trim(),
          birthTime: _birthTimeController.text.trim().isEmpty
              ? null
              : _birthTimeController.text.trim(),
          birthplace: _birthplaceController.text.trim().isEmpty
              ? null
              : _birthplaceController.text.trim(),
          zodiac: _zodiacController.text.trim().isEmpty
              ? null
              : _zodiacController.text.trim(),
          bazi: _baziController.text.trim().isEmpty
              ? null
              : _baziController.text.trim(),
        );

        final updatedUser = await _apiClient.api.userProfile.putApiProfile(
          body: updateData,
        );

        // 更新当前用户信息
        _authService.fetchCurrentUser();
        SnackBarManager.showUpdateSuccess();

        if (context.mounted) {
          context.pop();
        }
      } on ApiException catch (e) {
        SnackBarManager.showOperationFailed('update', e.message);
      } catch (e) {
        SnackBarManager.showOperationFailed('update', e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile_page_title'.tr()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'save_button'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像部分
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    backgroundImage: _avatarUrl != null
                        ? CachedNetworkImageProvider(
                            _avatarUrl!.startsWith('http')
                                ? _avatarUrl!
                                : 'https://api.205716.xyz${_avatarUrl}',
                          )
                        : null,
                    child: _avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndCropImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 基本信息部分
            _buildSectionTitle('basic_info'.tr()),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nicknameController,
              label: 'nickname'.tr(),
              hint: 'enter_nickname'.tr(),
              icon: Icons.person_outline,
              required: true,
            ),
            const SizedBox(height: 16),

            // 性别选择
            _buildDropdownField<Gender>(
              value: _gender,
              label: 'gender'.tr(),
              items: [
                DropdownMenuItem(
                  value: Gender.male,
                  child: Text('gender_male'.tr()),
                ),
                DropdownMenuItem(
                  value: Gender.female,
                  child: Text('gender_female'.tr()),
                ),
                DropdownMenuItem(
                  value: Gender.other,
                  child: Text('gender_other'.tr()),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value),
              icon: Icons.wc,
            ),
            const SizedBox(height: 16),

            // 生日选择
            _buildDateField(
              label: 'birthday'.tr(),
              value: _birthday,
              onTap: _selectDate,
              icon: Icons.cake_outlined,
            ),
            const SizedBox(height: 32),

            // 详细信息部分
            _buildSectionTitle('detailed_info'.tr()),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _mbtiController,
              label: 'mbti_type'.tr(),
              hint: 'mbti_example'.tr(),
              icon: Icons.psychology_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _birthTimeController,
              label: 'birth_time'.tr(),
              hint: 'birth_time_format'.tr(),
              icon: Icons.access_time,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _birthplaceController,
              label: 'birthplace'.tr(),
              hint: 'enter_birthplace'.tr(),
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _zodiacController,
              label: 'zodiac'.tr(),
              hint: 'zodiac_example'.tr(),
              icon: Icons.star_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _baziController,
              label: 'bazi'.tr(),
              hint: 'bazi_example'.tr(),
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          value != null
              ? DateFormat('yyyy年MM月dd日').format(value)
              : 'select_date'.tr(),
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
