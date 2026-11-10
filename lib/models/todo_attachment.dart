class TodoAttachment {
  final String? path;
  final String? assetId;
  final String? thumbUri;
  const TodoAttachment({this.path, this.assetId, this.thumbUri});
  bool get isValid =>
      (path != null && path!.isNotEmpty) ||
      (assetId != null && assetId!.isNotEmpty) ||
      (thumbUri != null && thumbUri!.isNotEmpty);
}
