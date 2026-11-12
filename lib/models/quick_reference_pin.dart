class QuickReferencePin {
  final String id;
  final String label;
  final String assetId;
  final DateTime createdAt;

  QuickReferencePin({
    required this.id,
    required this.label,
    required this.assetId,
    required this.createdAt,
  });

  QuickReferencePin copyWith({String? label, String? assetId}) {
    return QuickReferencePin(
      id: id,
      label: label ?? this.label,
      assetId: assetId ?? this.assetId,
      createdAt: createdAt,
    );
  }
}
