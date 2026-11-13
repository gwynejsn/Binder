class SuggestedTopic {
  final String name;
  final String colorHex;
  final String keywords;
  final String description;

  const SuggestedTopic({
    required this.name,
    required this.colorHex,
    required this.keywords,
    this.description = '',
  });

  static SuggestedTopic fromMap(Map<String, dynamic> map) {
    return SuggestedTopic(
      name: map['name'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? '0xFF3B82F6',
      keywords: map['keywords'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorHex': colorHex,
      'keywords': keywords,
      'description': description,
    };
  }
}
