class Binder {
  final String id;
  final String name;
  final String description;
  final String colorHex;
  final DateTime createdAt;
  // the keywords are separated by spaces (which we will embed later)
  // we will cosine similarity this with the embedded extracted texts from the photo
  final String keywords;
  final List<String> photoAssetIds;

  Binder({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.createdAt,
    required this.keywords,
    required this.photoAssetIds,
  });

  Binder copyWith({
    String? name,
    String? description,
    String? colorHex,
    String? keywords,
    List<String>? photoAssetIds,
  }) {
    return Binder(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      keywords: keywords ?? this.keywords,
      photoAssetIds: photoAssetIds ?? this.photoAssetIds,
    );
  }
}
