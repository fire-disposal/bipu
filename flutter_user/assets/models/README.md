# Speech Recognition Models

This directory should contain the pre-trained models required for offline speech recognition powered by `sherpa-onnx`.

Please download the **zipformer** streaming models ：
sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23-mobile.tar.bz2

### Required Files:

Based on the default configuration in `lib/services/speech_recognition_service.dart`, you need the following files:

1.  `tokens.txt`
2.  `encoder-epoch-99-avg-1.int8.onnx`
3.  `decoder-epoch-99-avg-1.onnx`
4.  `joiner-epoch-99-avg-1.int8.onnx`


