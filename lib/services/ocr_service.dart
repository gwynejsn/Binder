import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

// we use this
// https://pub.dev/packages/google_mlkit_text_recognition
class OcrService {
  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
  }

  // from the asset entity, we extract yung text
  Future<String> recognizeTextFromAsset(AssetEntity asset) async {
    try {
      final File? file = await asset.file;
      if (file == null) return '';
      return await recognizeTextFromFilePath(file.path);
    } catch (e) {
      debugPrint('Error getting file from asset for OCR: $e');
      return '';
    }
  }

  Future<String> recognizeTextFromFilePath(String filePath) async {
    // make sure naka initialize muna!
    init();

    if (_textRecognizer == null) return '';

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );

      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('ML Kit Text Recognition error: $e');
      return '';
    }
  }

  Future<void> dispose() async {
    try {
      await _textRecognizer?.close();
    } catch (e) {
      debugPrint('Error closing TextRecognizer: $e');
    }
    _textRecognizer = null;
    _isInitialized = false;
  }
}
