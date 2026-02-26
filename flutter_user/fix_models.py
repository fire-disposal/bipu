import os
import re

def fix_model_file(file_path):
    """修复模型文件，将 part of 指令改为正确的导入"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 检查是否是模型文件（排除主文件和生成的文件）
    if 'models.dart' in file_path or '.g.dart' in file_path:
        return

    # 获取文件名（不带扩展名）
    file_name = os.path.basename(file_path).replace('.dart', '')

    # 替换 part of 指令
    if 'part of' in content:
        # 移除 part of 指令
        content = re.sub(r'part of \'\.\./models\.dart\';', '', content)
        content = re.sub(r'part of \"\.\./models\.dart\";', '', content)
        content = re.sub(r'part of \.\./models\.dart;', '', content)

        # 添加正确的导入和 part 指令
        new_content = """import 'package:json_annotation/json_annotation.dart';

part '$file_name.g.dart';

"""
        content = new_content + content.lstrip()

    # 写入修复后的内容
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'已修复: {file_path}')

def main():
    # 获取所有模型文件
    models_dir = 'lib/models'

    for root, dirs, files in os.walk(models_dir):
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart'):
                file_path = os.path.join(root, file)
                fix_model_file(file_path)

    print('所有模型文件修复完成！')

    # 更新 pubspec.yaml 添加必要的依赖
    print('\n请确保 pubspec.yaml 包含以下依赖:')
    print('''
dependencies:
  json_annotation: ^4.10.0

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
''')

if __name__ == '__main__':
    main()
