import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../core/widgets/core_button.dart';

/// 管理端通用表单构建器，支持快速创建各种类型的表单字段
class AdminFormBuilder extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic> initialValue;
  final List<FormFieldConfig> fields;
  final VoidCallback? onSubmit;
  final String submitButtonText;
  final bool loading;
  final double spacing;
  final EdgeInsetsGeometry padding;

  const AdminFormBuilder({
    super.key,
    required this.formKey,
    required this.fields,
    this.initialValue = const {},
    this.onSubmit,
    this.submitButtonText = '提交',
    this.loading = false,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      initialValue: initialValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 表单字段
          ...fields
              .map((field) => _buildField(context, field))
              .expand((widget) => [widget, SizedBox(height: spacing)]),
          // 提交按钮
          if (onSubmit != null) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CoreButton(
                  label: submitButtonText,
                  onPressed: loading ? null : onSubmit,
                  loading: loading,
                  icon: Icons.check,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, FormFieldConfig field) {
    switch (field.type) {
      case FormFieldType.text:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            prefixIcon: field.icon != null ? Icon(field.icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}不能为空')
              : null,
          initialValue: field.initialValue,
          maxLines: field.maxLines,
          keyboardType: field.keyboardType,
        );

      case FormFieldType.email:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: FormBuilderValidators.compose([
            if (field.required)
              FormBuilderValidators.required(errorText: '${field.label}不能为空'),
            FormBuilderValidators.email(errorText: '请输入有效的邮箱地址'),
          ]),
          initialValue: field.initialValue,
          keyboardType: TextInputType.emailAddress,
        );

      case FormFieldType.password:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          obscureText: true,
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}不能为空')
              : null,
          initialValue: field.initialValue,
        );

      case FormFieldType.number:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            prefixIcon: field.icon != null ? Icon(field.icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}不能为空')
              : null,
          initialValue: field.initialValue,
          keyboardType: TextInputType.number,
        );

      case FormFieldType.dropdown:
        return FormBuilderDropdown<String>(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: field.icon != null ? Icon(field.icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}不能为空')
              : null,
          items:
              field.options?.map((option) {
                return DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                );
              }).toList() ??
              [],
          initialValue: field.initialValue,
        );

      case FormFieldType.date:
        return FormBuilderDateTimePicker(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}不能为空')
              : null,
          initialValue: field.initialValue != null
              ? DateTime.tryParse(field.initialValue!)
              : null,
          inputType: InputType.date,
        );

      case FormFieldType.switchField:
        return FormBuilderSwitch(
          name: field.name,
          title: Text(field.label),
          decoration: const InputDecoration(border: InputBorder.none),
          initialValue:
              field.initialValue == 'true' || field.initialValue == true,
        );

      case FormFieldType.checkbox:
        return FormBuilderCheckbox(
          name: field.name,
          title: Text(field.label),
          validator: field.required
              ? FormBuilderValidators.required(errorText: '${field.label}必须勾选')
              : null,
          initialValue:
              field.initialValue == 'true' || field.initialValue == true,
        );
    }
  }
}

/// 表单字段配置类
class FormFieldConfig {
  final String name;
  final String label;
  final FormFieldType type;
  final String? hint;
  final IconData? icon;
  final bool required;
  final String? initialValue;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<DropdownOption>? options;

  const FormFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.icon,
    this.required = false,
    this.initialValue,
    this.maxLines,
    this.keyboardType,
    this.options,
  });
}

/// 表单字段类型枚举
enum FormFieldType {
  text,
  email,
  password,
  number,
  dropdown,
  date,
  switchField,
  checkbox,
}

/// 下拉选项配置
class DropdownOption {
  final String value;
  final String label;

  const DropdownOption({required this.value, required this.label});
}
