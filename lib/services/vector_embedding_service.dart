import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mediapipe_text/mediapipe_text.dart';

// this is the AI part which uses text_embedder to embed keywords into vector space
// then we use cosine similarity to compare
// https://developers.google.com/edge/mediapipe/solutions/text/text_embedder
class VectorEmbeddingService {
  TextEmbedder? _embedder;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // we also have in-memory of the embedding parang yung sa ibang services!
  static final Map<String, TextEmbedderResult> _embeddingCache = {};

  Future<void> init() async {
    if (_isInitialized) return;

    // gumagana lang sa android/ios
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        _embedder = await TextEmbedder.create(
          TextEmbedderOptions(l2Normalize: true, quantize: false),
        );
        _isInitialized = true;
        debugPrint(
          'VectorEmbeddingService: MediaPipe TextEmbedder successfully initialized!',
        );
        return;
      } catch (e) {
        debugPrint(
          'VectorEmbeddingService: MediaPipe init notice (fallback active): $e',
        );
      }
    }
    _isInitialized = true;
  }

  // to embed a text (convert into a vector)
  Future<TextEmbedderResult?> getEmbedding(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    // if nasa in-memory na (meaning na embed na before, simply return it)
    if (_embeddingCache.containsKey(clean)) {
      return _embeddingCache[clean];
    }

    if (!_isInitialized || _embedder == null) {
      await init();
    }

    if (_embedder != null) {
      try {
        final result = await _embedder!
            .embed(clean)
            .timeout(
              const Duration(milliseconds: 300),
              onTimeout: () => throw TimeoutException(
                'MediaPipe native embedder unavailable',
              ),
            );
        _embeddingCache[clean] = result;
        return result;
      } catch (e) {
        debugPrint('TextEmbedder embed notice (using fallback): $e');
        _embedder = null;
      }
    }
    return null;
  }

  // compute for cosine similarity of 2 embeddings
  Future<double> cosineSimilarity(
    TextEmbedderResult? a,
    TextEmbedderResult? b,
  ) async {
    if (a == null || b == null || _embedder == null) return 0.0;
    if (a.embeddings.isEmpty || b.embeddings.isEmpty) return 0.0;

    try {
      return TextEmbedder.cosineSimilarity(
        a.embeddings.first,
        b.embeddings.first,
      );
    } catch (e) {
      debugPrint('TextEmbedder cosineSimilarity error: $e');
      return 0.0;
    }
  }

  // wrapper nung cosineSimilarity function that converts first strings to
  // embeddings then uses that cosineSimilarity
  Future<double> compareTexts(String textA, String textB) async {
    if (_embedder != null) {
      final resA = await getEmbedding(textA);
      final resB = await getEmbedding(textB);

      if (resA != null && resB != null) {
        return await cosineSimilarity(resA, resB);
      }
    }

    // pang fallback lang if in-case ayaw gumana nung TextEmbedder
    return _computeFallbackSimilarity(textA, textB);
  }

  double _computeFallbackSimilarity(String docText, String conceptText) {
    final docWords = docText
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((w) => w.length > 1)
        .toSet();
    final conceptWords = conceptText
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((w) => w.length > 2)
        .toSet();
    if (docWords.isEmpty || conceptWords.isEmpty) return 0.0;
    final intersection = docWords.intersection(conceptWords).length;
    return (intersection / sqrt(conceptWords.length)).clamp(0.0, 1.0);
  }

  void dispose() {
    _embeddingCache.clear();
    try {
      _embedder?.dispose();
    } catch (_) {}
    _embedder = null;
    _isInitialized = false;
  }
}
