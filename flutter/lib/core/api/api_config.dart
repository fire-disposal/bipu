import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
  inputSpec: InputSpec(path: '../../../../backend/openapi.json'),
  generatorName: Generator.dio,
  outputDirectory: 'packages/bipupu_api',
  runSourceGenOnOutput: true,
)
class ApiConfig {}
