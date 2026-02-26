#!/usr/bin/env dart
// Simplified script to generate API client code from OpenAPI specification
// Usage: dart scripts/generate_api_simple.dart

import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> arguments) async {
  print('🚀 Starting API client generation...');

  // Configuration
  const openapiUrl = 'https://api.205716.xyz/api/openapi.json';
  const configFile = 'openapi-generator-config.yaml';
  const outputDir = 'lib/generated';

  try {
    // Clean up previous generated files
    print('🧹 Cleaning up previous generated files...');
    final generatedDir = Directory(outputDir);
    if (generatedDir.existsSync()) {
      generatedDir.deleteSync(recursive: true);
    }

    // Download OpenAPI spec
    print('📥 Downloading OpenAPI specification from $openapiUrl...');
    final openapiSpecFile = File('openapi.json');

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(openapiUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download OpenAPI spec: HTTP ${response.statusCode}',
      );
    }

    final specData = await response.transform(utf8.decoder).join();
    await openapiSpecFile.writeAsString(specData);
    print('✅ OpenAPI specification downloaded successfully');

    // Check if openapi-generator is available
    print('🔍 Checking for openapi-generator...');
    final openapiGeneratorResult = await Process.run('openapi-generator', [
      'version',
    ]);

    if (openapiGeneratorResult.exitCode != 0) {
      print('⚠️  openapi-generator not found. Installing...');

      // Try to install using npm
      final npmResult = await Process.run('npm', [
        'install',
        '-g',
        '@openapitools/openapi-generator-cli',
      ]);
      if (npmResult.exitCode != 0) {
        throw Exception('Failed to install openapi-generator-cli via npm');
      }
      print('✅ openapi-generator-cli installed via npm');
    } else {
      print('✅ openapi-generator found: ${openapiGeneratorResult.stdout}');
    }

    // Generate API client using openapi-generator
    print('⚙️  Generating API client...');

    final generateArgs = [
      'generate',
      '-i',
      'openapi.json',
      '-g',
      'dart-dio',
      '-o',
      outputDir,
      '-c',
      configFile,
      '--skip-validate-spec',
    ];

    final generateResult = await Process.run('openapi-generator', generateArgs);

    if (generateResult.exitCode != 0) {
      print('❌ Failed to generate API client:');
      print(generateResult.stderr);
      throw Exception('API generation failed');
    }

    print('✅ API client generated successfully!');
    print('📁 Output directory: $outputDir');

    // Clean up downloaded spec
    if (openapiSpecFile.existsSync()) {
      openapiSpecFile.deleteSync();
    }

    // Run pub get in generated directory
    print('📦 Running pub get in generated directory...');
    final pubGetResult = await Process.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: outputDir);

    if (pubGetResult.exitCode != 0) {
      print('⚠️  pub get failed: ${pubGetResult.stderr}');
    } else {
      print('✅ Dependencies installed');
    }

    // Run build_runner for json_serializable
    print('🔧 Running build_runner...');
    final buildRunnerResult = await Process.run('flutter', [
      'pub',
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: outputDir);

    if (buildRunnerResult.exitCode != 0) {
      print('⚠️  build_runner failed: ${buildRunnerResult.stderr}');
    } else {
      print('✅ build_runner completed successfully!');
    }

    // Format generated code
    print('🎨 Formatting generated code...');
    final formatResult = await Process.run('dart', [
      'format',
      '.',
    ], workingDirectory: outputDir);

    if (formatResult.exitCode != 0) {
      print('⚠️  dart format failed: ${formatResult.stderr}');
    } else {
      print('✅ Code formatting completed!');
    }

    print('\n🎉 API client generation completed!');
    print('📋 Next steps:');
    print('   1. Review generated code in $outputDir');
    print('   2. Update your Dio configuration to use the generated client');
    print('   3. Run tests to ensure everything works correctly');
    print('\n📝 To use the generated client:');
    print('   - Import the generated API classes from lib/generated');
    print('   - Create a Dio instance with your configuration');
    print('   - Initialize the API client with your Dio instance');
    print('   - Use the generated methods for API calls');
  } catch (e, stackTrace) {
    print('❌ Error generating API client: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
