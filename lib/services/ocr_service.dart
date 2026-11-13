import 'dart:convert';
import 'dart:io';

import 'package:binder/models/binder.dart';
import 'package:binder/models/smart_scan_result.dart';
import 'package:binder/models/suggested_topic.dart';
import 'package:binder/services/vector_embedding_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class OcrService {
  TextRecognizer? _textRecognizer;
  final VectorEmbeddingService _embeddingService = VectorEmbeddingService();

  bool _isInitialized = false;
  List<SuggestedTopic> _ragTopics = [];
  bool _isCatalogLoaded = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    await _embeddingService.init();
    await _loadTopicsCatalog();
    _isInitialized = true;
  }

  // load the suggested_topics.json file catalog
  Future<void> _loadTopicsCatalog() async {
    if (_isCatalogLoaded) return;
    try {
      // we use rootBundle to load a json file daw sabi dito
      // https://stackoverflow.com/questions/71294190/how-to-read-local-json-file-in-flutter
      final jsonString = await rootBundle.loadString(
        'assets/data/suggested_topics.json',
      );
      if (jsonString.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is List) {
          _ragTopics = decoded
              .map(
                (item) => SuggestedTopic.fromMap(item as Map<String, dynamic>),
              )
              .toList();
          _isCatalogLoaded = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading suggested_topics.json: $e');
    }
  }

  // from scan AssetEntity using OCR and return the extracted text
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
    if (!_isInitialized) {
      await init();
    }

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

  // scans photo to extract the text using OCR
  // then use vector embedding to compare (ai part)
  Future<SmartScanResult> scanAndAnalyze(
    AssetEntity asset, {
    List<Binder> existingBinders = const [],
  }) async {
    final rawText = await recognizeTextFromAsset(asset);
    return analyzeText(rawText, existingBinders: existingBinders);
  }

  Future<SmartScanResult> analyzeText(
    String text, {
    List<Binder> existingBinders = const [],
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length < 5) {
      return SmartScanResult(extractedText: cleanText);
    }

    if (!_isInitialized) {
      await init();
    }

    // we only use a sample (hindi lahat nung extracted text!)
    final sample = cleanText.length > 350
        ? cleanText.substring(0, 350)
        : cleanText;

    String? bestBinderId;
    double highestBinderSimilarity = 0.0;

    // PART 1: suggest from existing binders
    // goal natin is
    // for each binders, we embed lahat ng keywords nun
    // then for the words in the sample as well, we embed din sila
    // then we compute for the similarity
    for (final b in existingBinders) {
      final binderConcept = b.keywords.isNotEmpty
          ? '${b.name}: ${b.keywords}'
          : b.name;

      // here, the embedding and computation ng cosineSimilarity
      // is nangyayari sa embeddingService
      final double similarity = await _embeddingService.compareTexts(
        sample,
        binderConcept,
      );

      // we are changing kung anong binder yung isusuggest if mas malaki
      // yung similarity to this b index existingBinders
      if (similarity > highestBinderSimilarity) {
        highestBinderSimilarity = similarity;
        bestBinderId = b.id;
      }
    }

    // If an existing binder matches with high cosine similarity (>= 0.28), return it immediately!
    // trip ko lang si 28% (can be changed!)
    if (bestBinderId != null && highestBinderSimilarity >= 0.28) {
      return SmartScanResult(
        extractedText: cleanText,
        suggestedBinderId: bestBinderId,
      );
    }

    // NOTE: it will only proceed dito if walang nahanap na similarity
    // from existing binders

    // PART 2: suggest a new binder found from the catalog
    SuggestedTopic? bestRagTopic;
    double highestCatalogSimilarity = 0.0;

    for (final topic in _ragTopics) {
      final topicConcept = '${topic.name}: ${topic.keywords}';

      // same sa kanina per using the catalog naman
      final double similarity = await _embeddingService.compareTexts(
        sample,
        topicConcept,
      );

      if (similarity > highestCatalogSimilarity) {
        highestCatalogSimilarity = similarity;
        bestRagTopic = topic;
      }
    }

    // if a catalog topic matches with good confidence (>= 0.22) trip ko lang 22%
    if (bestRagTopic != null && highestCatalogSimilarity >= 0.22) {
      // check if user already has a binder with a similar name
      final topicFirstName = bestRagTopic.name.toLowerCase().split(' ').first;
      for (final b in existingBinders) {
        if (b.name.toLowerCase().contains(topicFirstName)) {
          // if meron na, simply return that!
          return SmartScanResult(
            extractedText: cleanText,
            suggestedBinderId: b.id,
          );
        }
      }

      // or else, suggest creating this new binder suggestion
      return SmartScanResult(
        extractedText: cleanText,
        suggestedNewTopic: bestRagTopic,
      );
    }

    //fallback: kung wala talaga mahanap na similar, simply return the extracted text
    // we handle it in the ui to make users select manually
    return SmartScanResult(extractedText: cleanText);
  }

  Future<void> dispose() async {
    try {
      await _textRecognizer?.close();
    } catch (e) {
      debugPrint('Error closing TextRecognizer: $e');
    }
    _textRecognizer = null;
    _embeddingService.dispose();
    _isInitialized = false;
  }
}
