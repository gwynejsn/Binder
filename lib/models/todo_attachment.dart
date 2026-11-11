class TodoAttachment {
  final String assetId;

  const TodoAttachment({required this.assetId});

  bool get isValid => assetId.isNotEmpty;

  Map<String, dynamic> toMap() => {'assetId': assetId};

  factory TodoAttachment.fromMap(Map<String, dynamic> map) =>
      TodoAttachment(assetId: map['assetId'] as String);
}
