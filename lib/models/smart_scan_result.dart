import 'package:binder/models/suggested_topic.dart';

// may dalawang ginagawa yung AI
// suggest an existing binder if meron nag match
// suggest a new binder to be made if nag match doon sa catalog na nilagay natin
// sa assets/data/suggested_topics.json
class SmartScanResult {
  final String extractedText;
  final String? suggestedBinderId; // match found in existing binders
  final SuggestedTopic? suggestedNewTopic; // match found in catalog to create

  const SmartScanResult({
    required this.extractedText,
    this.suggestedBinderId,
    this.suggestedNewTopic,
  });
}
