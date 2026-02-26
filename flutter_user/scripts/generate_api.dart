#!/usr/bin/env dart
// Script to generate API client code from OpenAPI specification
// Usage: dart scripts/generate_api.dart

import 'dart:io';
import 'dart:convert';
import 'package:openapi_generator_cli/openapi_generator_cli.dart';

Future<void> main(List<String> arguments) async {
  print('🚀 Starting API client generation...');

  // Configuration
  const openapiUrl = 'https://api.205716.xyz/api/openapi.json';
  const configFile = 'openapi-generator-config.yaml';
  const outputDir = 'lib/generated';

  try {
    // Check if openapi-generator-cli is installed
    print('📦 Checking openapi-generator-cli installation...');
    await OpenapiGeneratorCli.installIfNeeded();

    // Clean up previous generated files
    print('🧹 Cleaning up previous generated files...');
    final generatedDir = Directory(outputDir);
    if (generatedDir.existsSync()) {
      generatedDir.deleteSync(recursive: true);
    }

    // Generate API client
    print('⚙️  Generating API client from $openapiUrl...');

    await OpenapiGeneratorCli.generate(
      generatorName: 'dart-dio',
      inputSpec: openapiUrl,
      outputDir: outputDir,
      configFile: configFile,
      additionalProperties: {
        'pubName': 'flutter_user_api',
        'pubVersion': '1.0.0',
        'pubDescription': 'Generated API client for bipupu Flutter app',
        'pubAuthor': 'Bipupu Team',
        'pubAuthorEmail': 'team@bipupu.com',
        'pubHomepage': 'https://bipupu.com',
        'useEnumExtension': 'true',
        'enumUnknownDefaultCase': 'false',
        'serializationLibrary': 'json_serializable',
        'dateLibrary': 'core',
        'nullableFields': 'true',
        'sortParamsByRequiredFlag': 'true',
        'ensureUniqueParams': 'true',
        'hideGenerationTimestamp': 'true',
        'removeEnumValuePrefix': 'false',
        'allowUnicodeIdentifiers': 'true',
        'sourceFolder': '',
        'library': 'dio',
        'useCollectionWrappers': 'true',
        'generateAliasAsModel': 'false',
        'supportDart2': 'true',
        'skipOverwrite': 'false',
        'pubPublishTo': 'none',
      },
      globalProperties: {
        'apis': '',
        'models': '',
        'supportingFiles': '',
        'apiTests': 'false',
        'modelTests': 'false',
        'apiDocs': 'false',
        'modelDocs': 'false',
      },
    );

    print('✅ API client generated successfully!');
    print('📁 Output directory: $outputDir');

    // Run build_runner to generate json_serializable code
    print('🔧 Running build_runner for json_serializable...');
    final process = await Process.start('flutter', [
      'pub',
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], runInShell: true);

    // Stream output
    process.stdout.transform(utf8.decoder).listen((data) => print(data));
    process.stderr.transform(utf8.decoder).listen((data) => print(data));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('⚠️  build_runner exited with code $exitCode');
    } else {
      print('✅ build_runner completed successfully!');
    }

    // Format generated code
    print('🎨 Formatting generated code...');
    final formatProcess = await Process.start('dart', [
      'format',
      outputDir,
    ], runInShell: true);

    formatProcess.stdout.transform(utf8.decoder).listen((data) => print(data));
    formatProcess.stderr.transform(utf8.decoder).listen((data) => print(data));

    final formatExitCode = await formatProcess.exitCode;
    if (formatExitCode != 0) {
      print('⚠️  dart format exited with code $formatExitCode');
    } else {
      print('✅ Code formatting completed!');
    }

    print('\n🎉 API client generation completed!');
    print('📋 Next steps:');
    print('   1. Review generated code in $outputDir');
    print('   2. Update your Dio configuration to use the generated client');
    print('   3. Run tests to ensure everything works correctly');
  } catch (e, stackTrace) {
    print('❌ Error generating API client: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
