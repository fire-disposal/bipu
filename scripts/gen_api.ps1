# PowerShell 脚本：用 openapi-generator-cli 生成 Dart Dio 客户端代码
# 需先全局安装 openapi-generator-cli（npm install @openapitools/openapi-generator-cli -g）

openapi-generator-cli generate -i flutter/openapi.json -g dart-dio -o flutter/packages/bipupu_api --skip-validate-spec 

cd flutter/packages/bipupu_api ; flutter pub run build_runner build --delete-conflicting-outputs
