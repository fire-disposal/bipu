import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

/// Comprehensive voice system dependency analyzer
class VoiceSystemAnalyzer {
  static final VoiceSystemAnalyzer _instance = VoiceSystemAnalyzer._internal();
  factory VoiceSystemAnalyzer() => _instance;
  VoiceSystemAnalyzer._internal();

  /// Analyze the complete voice system dependency tree
  Future<VoiceDependencyAnalysis> analyzeVoiceSystem() async {
    logger.i('Analyzing voice system dependencies...');
    
    final analysis = VoiceDependencyAnalysis();
    
    try {
      // Analyze core voice components
      await _analyzeCoreVoiceComponents(analysis);
      
      // Analyze UI components
      await _analyzeUIComponents(analysis);
      
      // Analyze service dependencies
      await _analyzeServiceDependencies(analysis);
      
      // Analyze external dependencies
      await _analyzeExternalDependencies(analysis);
      
      // Identify critical issues
      _identifyCriticalIssues(analysis);
      
      // Generate recommendations
      _generateRecommendations(analysis);
      
      logger.i('Voice system analysis completed');
      return analysis;
    } catch (e, stackTrace) {
      logger.e('Error analyzing voice system', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze core voice components
  Future<void> _analyzeCoreVoiceComponents(VoiceDependencyAnalysis analysis) async {
    final coreComponents = {
      'ASR Engine': 'lib/core/voice/asr_engine.dart',
      'TTS Engine': 'lib/core/voice/tts_engine.dart',
      'Audio Bus': 'lib/core/voice/audio_bus.dart',
      'Audio Resource Manager': 'lib/core/voice/audio_resource_manager.dart',
      'Model Manager': 'lib/core/voice/model_manager.dart',
      'Assistant Controller': 'lib/features/assistant/assistant_controller.dart',
      'Assistant Config': 'lib/features/assistant/assistant_config.dart',
    };

    for (final entry in coreComponents.entries) {
      final componentName = entry.key;
      final filePath = entry.value;
      
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final issues = _analyzeComponentIssues(componentName, content);
          
          analysis.coreComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: true,
            issues: issues,
            complexity: _calculateComplexity(content),
            dependencies: _extractDependencies(content),
          );
        } else {
          analysis.coreComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: false,
            issues: ['File not found'],
            complexity: 0,
            dependencies: [],
          );
        }
      } catch (e) {
        analysis.coreComponents[componentName] = ComponentAnalysis(
          name: componentName,
          filePath: filePath,
          exists: true,
          issues: ['Error reading file: $e'],
          complexity: 0,
          dependencies: [],
        );
      }
    }
  }

  /// Analyze UI components
  Future<void> _analyzeUIComponents(VoiceDependencyAnalysis analysis) async {
    final uiComponents = {
      'Voice Test Page': 'lib/features/voice_test/voice_test_page.dart',
      'Pager Page': 'lib/features/pager/pages/pager_page.dart',
      'Voice Assistant Panel': 'lib/features/pager/widgets/voice_assistant_panel.dart',
      'Waveform Widget': 'lib/features/pager/widgets/waveform_widget.dart',
      'Waveform Controller': 'lib/features/pager/widgets/waveform_controller.dart',
    };

    for (final entry in uiComponents.entries) {
      final componentName = entry.key;
      final filePath = entry.value;
      
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final issues = _analyzeUIComponentIssues(componentName, content);
          
          analysis.uiComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: true,
            issues: issues,
            complexity: _calculateComplexity(content),
            dependencies: _extractDependencies(content),
          );
        } else {
          analysis.uiComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: false,
            issues: ['File not found'],
            complexity: 0,
            dependencies: [],
          );
        }
      } catch (e) {
        analysis.uiComponents[componentName] = ComponentAnalysis(
          name: componentName,
          filePath: filePath,
          exists: true,
          issues: ['Error reading file: $e'],
          complexity: 0,
          dependencies: [],
        );
      }
    }
  }

  /// Analyze service dependencies
  Future<void> _analyzeServiceDependencies(VoiceDependencyAnalysis analysis) async {
    final serviceFiles = [
      'lib/core/services/im_service.dart',
      'lib/core/services/bluetooth_device_service.dart',
      'lib/core/services/auth_service.dart',
    ];

    for (final filePath in serviceFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final voiceRelated = _isVoiceRelated(content);
          
          if (voiceRelated) {
            analysis.serviceDependencies[filePath] = ServiceDependency(
              filePath: filePath,
              voiceRelated: true,
              dependencies: _extractDependencies(content),
              issues: _analyzeServiceIssues(content),
            );
          }
        }
      } catch (e) {
        logger.w('Error analyzing service file $filePath: $e');
      }
    }
  }

  /// Analyze external dependencies
  Future<void> _analyzeExternalDependencies(VoiceDependencyAnalysis analysis) async {
    final pubspecFile = File('flutter_user/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      final voiceDependencies = _extractVoiceDependencies(content);
      
      analysis.externalDependencies = voiceDependencies;
    }
  }

  /// Analyze component-specific issues
  List<String> _analyzeComponentIssues(String componentName, String content) {
    final issues = <String>[];
    
    // Check for common voice-related issues
    if (content.contains('sherpa_onnx') && !content.contains('try') && !content.contains('catch')) {
      issues.add('Missing error handling for sherpa_onnx operations');
    }
    
    if (content.contains('StreamController') && !content.contains('close()')) {
      issues.add('Potential memory leak: StreamController not properly closed');
    }
    
    if (content.contains('Completer') && !content.contains('completeError')) {
      issues.add('Incomplete error handling: Completer may not handle errors');
    }
    
    if (content.contains('dispose()') && !content.contains('Future')) {
      issues.add('Synchronous dispose may cause async cleanup issues');
    }
    
    if (content.contains('Isolate') && !content.contains('kill()')) {
      issues.add('Isolate cleanup may be incomplete');
    }
    
    // Component-specific issues
    if (componentName.contains('ASR')) {
      issues.addAll(_analyzeASRIssues(content));
    } else if (componentName.contains('TTS')) {
      issues.addAll(_analyzeTTSEngineIssues(content));
    } else if (componentName.contains('Audio')) {
      issues.addAll(_analyzeAudioResourceIssues(content));
    } else if (componentName.contains('Assistant')) {
      issues.addAll(_analyzeAssistantIssues(content));
    }
    
    return issues;
  }

  /// Analyze ASR-specific issues
  List<String> _analyzeASRIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('permission_handler')) {
      issues.add('Missing microphone permission handling');
    }
    
    if (!content.contains('AudioSession')) {
      issues.add('Missing audio session management');
    }
    
    if (content.contains('RecorderStream') && !content.contains('onError')) {
      issues.add('Missing error handling for audio stream');
    }
    
    if (content.contains('Float32List') && !content.contains('try')) {
      issues.add('Missing error handling for audio data conversion');
    }
    
    return issues;
  }

  /// Analyze TTS-specific issues
  List<String> _analyzeTTSEngineIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('OfflineTts') && content.contains('sherpa_onnx')) {
      issues.add('TTS engine may not be properly initialized');
    }
    
    if (content.contains('generate(') && !content.contains('null check')) {
      issues.add('Missing null checks for TTS generation');
    }
    
    return issues;
  }

  /// Analyze audio resource issues
  List<String> _analyzeAudioResourceIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('AudioSession')) {
      issues.add('Missing audio session configuration');
    }
    
    if (!content.contains('timeout')) {
      issues.add('Missing timeout handling for resource acquisition');
    }
    
    return issues;
  }

  /// Analyze assistant controller issues
  List<String> _analyzeAssistantIssues(String content) {
    final issues = <String>[];
    
    if (content.contains('startListening') && !content.contains('stopListening')) {
      issues.add('Missing proper listening lifecycle management');
    }
    
    if (content.contains('State.') && !content.contains('enum')) {
      issues.add('State management may be inconsistent');
    }
    
    return issues;
  }

  /// Analyze UI component issues
  List<String> _analyzeUIComponentIssues(String componentName, String content) {
    final issues = <String>[];
    
    if (componentName.contains('Test') && !content.contains('error')) {
      issues.add('Test page may not handle errors properly');
    }
    
    if (content.contains('setState') && !content.contains('mounted')) {
      issues.add('Potential setState called after dispose');
    }
    
    return issues;
  }

  /// Analyze service issues
  List<String> _analyzeServiceIssues(String content) {
    final issues = <String>[];
    
    if (content.contains('dio') && !content.contains('try')) {
      issues.add('Missing error handling for network operations');
    }
    
    return issues;
  }

  /// Check if content is voice-related
  bool _isVoiceRelated(String content) {
    final voiceKeywords = [
      'voice', 'speech', 'audio', 'tts', 'asr', 'recognition', 'sherpa',
      'microphone', 'recording', 'playback', 'sound_stream'
    ];
    
    return voiceKeywords.any((keyword) => 
      content.toLowerCase().contains(keyword));
  }

  /// Calculate code complexity
  int _calculateComplexity(String content) {
    int complexity = 0;
    
    // Count control structures
    complexity += RegExp(r'\b(if|else|switch|case)\b').allMatches(content).length;
    complexity += RegExp(r'\b(for|while|do)\b').allMatches(content).length;
    complexity += RegExp(r'\b(try|catch|finally)\b').allMatches(content).length;
    
    // Count async operations
    complexity += RegExp(r'\b(async|await)\b').allMatches(content).length;
    complexity += RegExp(r'Future<').allMatches(content).length;
    complexity += RegExp(r'Stream<').allMatches(content).length;
    
    // Count class and method definitions
    complexity += RegExp(r'\bclass\s+\w+').allMatches(content).length * 2;
    complexity += RegExp(r'\bFuture<\w+>\s+\w+\s*\(').allMatches(content).length;
    
    return complexity;
  }

  /// Extract dependencies from content
  List<String> _extractDependencies(String content) {
    final dependencies = <String>[];
    
    // Extract import statements
    final importRegex = RegExp(r"import\s+['\"]([^'\"]+)['\"];");
    for (final match in importRegex.allMatches(content)) {
      dependencies.add(match.group(1)!);
    }
    
    // Extract package dependencies
    final packageRegex = RegExp(r'package:([^/]+)/');
    for (final match in packageRegex.allMatches(content)) {
      dependencies.add(match.group(1)!);
    }
    
    return dependencies.toSet().toList()..sort();
  }

  /// Extract voice-related dependencies from pubspec
  List<String> _extractVoiceDependencies(String pubspecContent) {
    final voicePackages = [
      'sherpa_onnx',
      'sound_stream',
      'permission_handler',
      'audioplayers',
      'just_audio',
      'audio_session',
    ];
    
    final dependencies = <String>[];
    
    for (final package in voicePackages) {
      if (pubspecContent.contains(package)) {
        dependencies.add(package);
      }
    }
    
    return dependencies;
  }

  /// Identify critical issues
  void _identifyCriticalIssues(VoiceDependencyAnalysis analysis) {
    final criticalIssues = <CriticalIssue>[];
    
    // Check for missing error handling
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('error handling'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Missing error handling',
          severity: Severity.high,
          impact: 'May cause app crashes or undefined behavior',
        ));
      }
    }
    
    // Check for memory leaks
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('memory leak'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Potential memory leak',
          severity: Severity.high,
          impact: 'May cause app to run out of memory over time',
        ));
      }
    }
    
    // Check for resource management issues
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('resource'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Resource management issue',
          severity: Severity.medium,
          impact: 'May cause resource conflicts or deadlocks',
        ));
      }
    }
    
    analysis.criticalIssues = criticalIssues;
  }

  /// Generate recommendations
  void _generateRecommendations(VoiceDependencyAnalysis analysis) {
    final recommendations = <Recommendation>[];
    
    // Error handling recommendations
    if (analysis.criticalIssues.any((issue) => issue.issue.contains('error handling'))) {
      recommendations.add(Recommendation(
        category: 'Error Handling',
        priority: Priority.high,
        description: 'Implement comprehensive error handling with try-catch blocks',
        implementation: 'Wrap all sherpa_onnx operations in try-catch with proper error recovery',
      ));
    }
    
    // Memory management recommendations
    if (analysis.criticalIssues.any((issue) => issue.issue.contains('memory'))) {
      recommendations.add(Recommendation(
        category: 'Memory Management',
        priority: Priority.high,
        description: 'Implement proper resource cleanup and disposal',
        implementation: 'Use dispose() methods and ensure all streams/controllers are closed',
      ));
    }
    
    // Resource management recommendations
    recommendations.add(Recommendation(
      category: 'Resource Management',
      priority: Priority.medium,
      description: 'Implement enhanced audio resource manager',
      implementation: 'Use the new EnhancedAudioResourceManager for better resource coordination',
    ));
    
    // Testing recommendations
    recommendations.add(Recommendation(
      category: 'Testing',
      priority: Priority.medium,
      description: 'Add comprehensive error scenario testing',
      implementation: 'Test microphone permission denial, network failures, and resource conflicts',
    ));
    
    analysis.recommendations = recommendations;
  }
}

/// Voice dependency analysis result
class VoiceDependencyAnalysis {
  Map<String, ComponentAnalysis> coreComponents = {};
  Map<String, ComponentAnalysis> uiComponents = {};
  Map<String, ServiceDependency> serviceDependencies = {};
  List<String> externalDependencies = [];
  List<CriticalIssue> criticalIssues = [];
  List<Recommendation> recommendations = [];

  /// Generate summary report
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== VOICE SYSTEM DEPENDENCY ANALYSIS ===');
    buffer.writeln();
    
    buffer.writeln('CORE COMPONENTS (${coreComponents.length}):');
    for (final component in coreComponents.values) {
      buffer.writeln('  ${component.name}: ${component.issues.length} issues');
    }
    buffer.writeln();
    
    buffer.writeln('UI COMPONENTS (${uiComponents.length}):');
    for (final component in uiComponents.values) {
      buffer.writeln('  ${component.name}: ${component.issues.length} issues');
    }
    buffer.writeln();
    
    buffer.writeln('CRITICAL ISSUES (${criticalIssues.length}):');
    for (final issue in criticalIssues) {
      buffer.writeln('  [${issue.severity.name.toUpperCase()}] ${issue.component}: ${issue.issue}');
    }
    buffer.writeln();
    
    buffer.writeln('RECOMMENDATIONS (${recommendations.length}):');
    for (final rec in recommendations) {
      buffer.writeln('  [${rec.priority.name.toUpperCase()}] ${rec.category}: ${rec.description}');
    }
    
    return buffer.toString();
  }
}

/// Component analysis
class ComponentAnalysis {
  final String name;
  final String filePath;
  final bool exists;
  final List<String> issues;
  final int complexity;
  final List<String> dependencies;

  ComponentAnalysis({
    required this.name,
    required this.filePath,
    required this.exists,
    required this.issues,
    required this.complexity,
    required this.dependencies,
  });
}

/// Service dependency
class ServiceDependency {
  final String filePath;
  final bool voiceRelated;
  final List<String> dependencies;
  final List<String> issues;

  ServiceDependency({
    required this.filePath,
    required this.voiceRelated,
    required this.dependencies,
    required this.issues,
  });
}

/// Critical issue
class CriticalIssue {
  final String component;
  final String issue;
  final Severity severity;
  final String impact;

  CriticalIssue({
    required this.component,
    required this.issue,
    required this.severity,
    required this.impact,
  });
}

/// Recommendation
class Recommendation {
  final String category;
  final Priority priority;
  final String description;
  final String implementation;

  Recommendation({
    required this.category,
    required this.priority,
    required this.description,
    required this.implementation,
  });
}

enum Severity { low, medium, high, critical }
enum Priority { low, medium, high }import 'package:path/path.dart' as path;
import '../utils/logger.dart';

/// Comprehensive voice system dependency analyzer
class VoiceSystemAnalyzer {
  static final VoiceSystemAnalyzer _instance = VoiceSystemAnalyzer._internal();
  factory VoiceSystemAnalyzer() => _instance;
  VoiceSystemAnalyzer._internal();

  /// Analyze the complete voice system dependency tree
  Future<VoiceDependencyAnalysis> analyzeVoiceSystem() async {
    logger.i('Analyzing voice system dependencies...');
    
    final analysis = VoiceDependencyAnalysis();
    
    try {
      // Analyze core voice components
      await _analyzeCoreVoiceComponents(analysis);
      
      // Analyze UI components
      await _analyzeUIComponents(analysis);
      
      // Analyze service dependencies
      await _analyzeServiceDependencies(analysis);
      
      // Analyze external dependencies
      await _analyzeExternalDependencies(analysis);
      
      // Identify critical issues
      _identifyCriticalIssues(analysis);
      
      // Generate recommendations
      _generateRecommendations(analysis);
      
      logger.i('Voice system analysis completed');
      return analysis;
    } catch (e, stackTrace) {
      logger.e('Error analyzing voice system', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze core voice components
  Future<void> _analyzeCoreVoiceComponents(VoiceDependencyAnalysis analysis) async {
    final coreComponents = {
      'ASR Engine': 'lib/core/voice/asr_engine.dart',
      'TTS Engine': 'lib/core/voice/tts_engine.dart',
      'Audio Bus': 'lib/core/voice/audio_bus.dart',
      'Audio Resource Manager': 'lib/core/voice/audio_resource_manager.dart',
      'Model Manager': 'lib/core/voice/model_manager.dart',
      'Assistant Controller': 'lib/features/assistant/assistant_controller.dart',
      'Assistant Config': 'lib/features/assistant/assistant_config.dart',
    };

    for (final entry in coreComponents.entries) {
      final componentName = entry.key;
      final filePath = entry.value;
      
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final issues = _analyzeComponentIssues(componentName, content);
          
          analysis.coreComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: true,
            issues: issues,
            complexity: _calculateComplexity(content),
            dependencies: _extractDependencies(content),
          );
        } else {
          analysis.coreComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: false,
            issues: ['File not found'],
            complexity: 0,
            dependencies: [],
          );
        }
      } catch (e) {
        analysis.coreComponents[componentName] = ComponentAnalysis(
          name: componentName,
          filePath: filePath,
          exists: true,
          issues: ['Error reading file: $e'],
          complexity: 0,
          dependencies: [],
        );
      }
    }
  }

  /// Analyze UI components
  Future<void> _analyzeUIComponents(VoiceDependencyAnalysis analysis) async {
    final uiComponents = {
      'Voice Test Page': 'lib/features/voice_test/voice_test_page.dart',
      'Pager Page': 'lib/features/pager/pages/pager_page.dart',
      'Voice Assistant Panel': 'lib/features/pager/widgets/voice_assistant_panel.dart',
      'Waveform Widget': 'lib/features/pager/widgets/waveform_widget.dart',
      'Waveform Controller': 'lib/features/pager/widgets/waveform_controller.dart',
    };

    for (final entry in uiComponents.entries) {
      final componentName = entry.key;
      final filePath = entry.value;
      
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final issues = _analyzeUIComponentIssues(componentName, content);
          
          analysis.uiComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: true,
            issues: issues,
            complexity: _calculateComplexity(content),
            dependencies: _extractDependencies(content),
          );
        } else {
          analysis.uiComponents[componentName] = ComponentAnalysis(
            name: componentName,
            filePath: filePath,
            exists: false,
            issues: ['File not found'],
            complexity: 0,
            dependencies: [],
          );
        }
      } catch (e) {
        analysis.uiComponents[componentName] = ComponentAnalysis(
          name: componentName,
          filePath: filePath,
          exists: true,
          issues: ['Error reading file: $e'],
          complexity: 0,
          dependencies: [],
        );
      }
    }
  }

  /// Analyze service dependencies
  Future<void> _analyzeServiceDependencies(VoiceDependencyAnalysis analysis) async {
    final serviceFiles = [
      'lib/core/services/im_service.dart',
      'lib/core/services/bluetooth_device_service.dart',
      'lib/core/services/auth_service.dart',
    ];

    for (final filePath in serviceFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final voiceRelated = _isVoiceRelated(content);
          
          if (voiceRelated) {
            analysis.serviceDependencies[filePath] = ServiceDependency(
              filePath: filePath,
              voiceRelated: true,
              dependencies: _extractDependencies(content),
              issues: _analyzeServiceIssues(content),
            );
          }
        }
      } catch (e) {
        logger.w('Error analyzing service file $filePath: $e');
      }
    }
  }

  /// Analyze external dependencies
  Future<void> _analyzeExternalDependencies(VoiceDependencyAnalysis analysis) async {
    final pubspecFile = File('flutter_user/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      final voiceDependencies = _extractVoiceDependencies(content);
      
      analysis.externalDependencies = voiceDependencies;
    }
  }

  /// Analyze component-specific issues
  List<String> _analyzeComponentIssues(String componentName, String content) {
    final issues = <String>[];
    
    // Check for common voice-related issues
    if (content.contains('sherpa_onnx') && !content.contains('try') && !content.contains('catch')) {
      issues.add('Missing error handling for sherpa_onnx operations');
    }
    
    if (content.contains('StreamController') && !content.contains('close()')) {
      issues.add('Potential memory leak: StreamController not properly closed');
    }
    
    if (content.contains('Completer') && !content.contains('completeError')) {
      issues.add('Incomplete error handling: Completer may not handle errors');
    }
    
    if (content.contains('dispose()') && !content.contains('Future')) {
      issues.add('Synchronous dispose may cause async cleanup issues');
    }
    
    if (content.contains('Isolate') && !content.contains('kill()')) {
      issues.add('Isolate cleanup may be incomplete');
    }
    
    // Component-specific issues
    if (componentName.contains('ASR')) {
      issues.addAll(_analyzeASRIssues(content));
    } else if (componentName.contains('TTS')) {
      issues.addAll(_analyzeTTSEngineIssues(content));
    } else if (componentName.contains('Audio')) {
      issues.addAll(_analyzeAudioResourceIssues(content));
    } else if (componentName.contains('Assistant')) {
      issues.addAll(_analyzeAssistantIssues(content));
    }
    
    return issues;
  }

  /// Analyze ASR-specific issues
  List<String> _analyzeASRIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('permission_handler')) {
      issues.add('Missing microphone permission handling');
    }
    
    if (!content.contains('AudioSession')) {
      issues.add('Missing audio session management');
    }
    
    if (content.contains('RecorderStream') && !content.contains('onError')) {
      issues.add('Missing error handling for audio stream');
    }
    
    if (content.contains('Float32List') && !content.contains('try')) {
      issues.add('Missing error handling for audio data conversion');
    }
    
    return issues;
  }

  /// Analyze TTS-specific issues
  List<String> _analyzeTTSEngineIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('OfflineTts') && content.contains('sherpa_onnx')) {
      issues.add('TTS engine may not be properly initialized');
    }
    
    if (content.contains('generate(') && !content.contains('null check')) {
      issues.add('Missing null checks for TTS generation');
    }
    
    return issues;
  }

  /// Analyze audio resource issues
  List<String> _analyzeAudioResourceIssues(String content) {
    final issues = <String>[];
    
    if (!content.contains('AudioSession')) {
      issues.add('Missing audio session configuration');
    }
    
    if (!content.contains('timeout')) {
      issues.add('Missing timeout handling for resource acquisition');
    }
    
    return issues;
  }

  /// Analyze assistant controller issues
  List<String> _analyzeAssistantIssues(String content) {
    final issues = <String>[];
    
    if (content.contains('startListening') && !content.contains('stopListening')) {
      issues.add('Missing proper listening lifecycle management');
    }
    
    if (content.contains('State.') && !content.contains('enum')) {
      issues.add('State management may be inconsistent');
    }
    
    return issues;
  }

  /// Analyze UI component issues
  List<String> _analyzeUIComponentIssues(String componentName, String content) {
    final issues = <String>[];
    
    if (componentName.contains('Test') && !content.contains('error')) {
      issues.add('Test page may not handle errors properly');
    }
    
    if (content.contains('setState') && !content.contains('mounted')) {
      issues.add('Potential setState called after dispose');
    }
    
    return issues;
  }

  /// Analyze service issues
  List<String> _analyzeServiceIssues(String content) {
    final issues = <String>[];
    
    if (content.contains('dio') && !content.contains('try')) {
      issues.add('Missing error handling for network operations');
    }
    
    return issues;
  }

  /// Check if content is voice-related
  bool _isVoiceRelated(String content) {
    final voiceKeywords = [
      'voice', 'speech', 'audio', 'tts', 'asr', 'recognition', 'sherpa',
      'microphone', 'recording', 'playback', 'sound_stream'
    ];
    
    return voiceKeywords.any((keyword) => 
      content.toLowerCase().contains(keyword));
  }

  /// Calculate code complexity
  int _calculateComplexity(String content) {
    int complexity = 0;
    
    // Count control structures
    complexity += RegExp(r'\b(if|else|switch|case)\b').allMatches(content).length;
    complexity += RegExp(r'\b(for|while|do)\b').allMatches(content).length;
    complexity += RegExp(r'\b(try|catch|finally)\b').allMatches(content).length;
    
    // Count async operations
    complexity += RegExp(r'\b(async|await)\b').allMatches(content).length;
    complexity += RegExp(r'Future<').allMatches(content).length;
    complexity += RegExp(r'Stream<').allMatches(content).length;
    
    // Count class and method definitions
    complexity += RegExp(r'\bclass\s+\w+').allMatches(content).length * 2;
    complexity += RegExp(r'\bFuture<\w+>\s+\w+\s*\(').allMatches(content).length;
    
    return complexity;
  }

  /// Extract dependencies from content
  List<String> _extractDependencies(String content) {
    final dependencies = <String>[];
    
    // Extract import statements
    final importRegex = RegExp(r"import\s+['\"]([^'\"]+)['\"];");
    for (final match in importRegex.allMatches(content)) {
      dependencies.add(match.group(1)!);
    }
    
    // Extract package dependencies
    final packageRegex = RegExp(r'package:([^/]+)/');
    for (final match in packageRegex.allMatches(content)) {
      dependencies.add(match.group(1)!);
    }
    
    return dependencies.toSet().toList()..sort();
  }

  /// Extract voice-related dependencies from pubspec
  List<String> _extractVoiceDependencies(String pubspecContent) {
    final voicePackages = [
      'sherpa_onnx',
      'sound_stream',
      'permission_handler',
      'audioplayers',
      'just_audio',
      'audio_session',
    ];
    
    final dependencies = <String>[];
    
    for (final package in voicePackages) {
      if (pubspecContent.contains(package)) {
        dependencies.add(package);
      }
    }
    
    return dependencies;
  }

  /// Identify critical issues
  void _identifyCriticalIssues(VoiceDependencyAnalysis analysis) {
    final criticalIssues = <CriticalIssue>[];
    
    // Check for missing error handling
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('error handling'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Missing error handling',
          severity: Severity.high,
          impact: 'May cause app crashes or undefined behavior',
        ));
      }
    }
    
    // Check for memory leaks
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('memory leak'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Potential memory leak',
          severity: Severity.high,
          impact: 'May cause app to run out of memory over time',
        ));
      }
    }
    
    // Check for resource management issues
    for (final component in analysis.coreComponents.values) {
      if (component.issues.any((issue) => issue.contains('resource'))) {
        criticalIssues.add(CriticalIssue(
          component: component.name,
          issue: 'Resource management issue',
          severity: Severity.medium,
          impact: 'May cause resource conflicts or deadlocks',
        ));
      }
    }
    
    analysis.criticalIssues = criticalIssues;
  }

  /// Generate recommendations
  void _generateRecommendations(VoiceDependencyAnalysis analysis) {
    final recommendations = <Recommendation>[];
    
    // Error handling recommendations
    if (analysis.criticalIssues.any((issue) => issue.issue.contains('error handling'))) {
      recommendations.add(Recommendation(
        category: 'Error Handling',
        priority: Priority.high,
        description: 'Implement comprehensive error handling with try-catch blocks',
        implementation: 'Wrap all sherpa_onnx operations in try-catch with proper error recovery',
      ));
    }
    
    // Memory management recommendations
    if (analysis.criticalIssues.any((issue) => issue.issue.contains('memory'))) {
      recommendations.add(Recommendation(
        category: 'Memory Management',
        priority: Priority.high,
        description: 'Implement proper resource cleanup and disposal',
        implementation: 'Use dispose() methods and ensure all streams/controllers are closed',
      ));
    }
    
    // Resource management recommendations
    recommendations.add(Recommendation(
      category: 'Resource Management',
      priority: Priority.medium,
      description: 'Implement enhanced audio resource manager',
      implementation: 'Use the new EnhancedAudioResourceManager for better resource coordination',
    ));
    
    // Testing recommendations
    recommendations.add(Recommendation(
      category: 'Testing',
      priority: Priority.medium,
      description: 'Add comprehensive error scenario testing',
      implementation: 'Test microphone permission denial, network failures, and resource conflicts',
    ));
    
    analysis.recommendations = recommendations;
  }
}

/// Voice dependency analysis result
class VoiceDependencyAnalysis {
  Map<String, ComponentAnalysis> coreComponents = {};
  Map<String, ComponentAnalysis> uiComponents = {};
  Map<String, ServiceDependency> serviceDependencies = {};
  List<String> externalDependencies = [];
  List<CriticalIssue> criticalIssues = [];
  List<Recommendation> recommendations = [];

  /// Generate summary report
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== VOICE SYSTEM DEPENDENCY ANALYSIS ===');
    buffer.writeln();
    
    buffer.writeln('CORE COMPONENTS (${coreComponents.length}):');
    for (final component in coreComponents.values) {
      buffer.writeln('  ${component.name}: ${component.issues.length} issues');
    }
    buffer.writeln();
    
    buffer.writeln('UI COMPONENTS (${uiComponents.length}):');
    for (final component in uiComponents.values) {
      buffer.writeln('  ${component.name}: ${component.issues.length} issues');
    }
    buffer.writeln();
    
    buffer.writeln('CRITICAL ISSUES (${criticalIssues.length}):');
    for (final issue in criticalIssues) {
      buffer.writeln('  [${issue.severity.name.toUpperCase()}] ${issue.component}: ${issue.issue}');
    }
    buffer.writeln();
    
    buffer.writeln('RECOMMENDATIONS (${recommendations.length}):');
    for (final rec in recommendations) {
      buffer.writeln('  [${rec.priority.name.toUpperCase()}] ${rec.category}: ${rec.description}');
    }
    
    return buffer.toString();
  }
}

/// Component analysis
class ComponentAnalysis {
  final String name;
  final String filePath;
  final bool exists;
  final List<String> issues;
  final int complexity;
  final List<String> dependencies;

  ComponentAnalysis({
    required this.name,
    required this.filePath,
    required this.exists,
    required this.issues,
    required this.complexity,
    required this.dependencies,
  });
}

/// Service dependency
class ServiceDependency {
  final String filePath;
  final bool voiceRelated;
  final List<String> dependencies;
  final List<String> issues;

  ServiceDependency({
    required this.filePath,
    required this.voiceRelated,
    required this.dependencies,
    required this.issues,
  });
}

/// Critical issue
class CriticalIssue {
  final String component;
  final String issue;
  final Severity severity;
  final String impact;

  CriticalIssue({
    required this.component,
    required this.issue,
    required this.severity,
    required this.impact,
  });
}

/// Recommendation
class Recommendation {
  final String category;
  final Priority priority;
  final String description;
  final String implementation;

  Recommendation({
    required this.category,
    required this.priority,
    required this.description,
    required this.implementation,
  });
}

enum Severity { low, medium, high, critical }
enum Priority { low, medium, high }
