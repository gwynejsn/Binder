class Binder {
  final String id;
  final String name;
  final String description;
  final String colorHex;
  final DateTime createdAt;
  // the keywords are separated by spaces (which we will embed later)
  // we will cosine similarity this with the embedded extracted texts from the photo
  final String keywords;

  Binder({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.createdAt,
    required this.keywords,
  });
}
