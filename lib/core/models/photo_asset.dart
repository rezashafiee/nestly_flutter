class PhotoAsset {
  const PhotoAsset({required this.iconKey, required this.colorValue});

  factory PhotoAsset.fromJson(Map<String, Object?> json) {
    return PhotoAsset(
      iconKey: json['iconKey']?.toString() ?? 'chair',
      colorValue: _readInt(json['colorValue']),
    );
  }

  final String iconKey;
  final int colorValue;

  Map<String, Object?> toJson() {
    return {'iconKey': iconKey, 'colorValue': colorValue};
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.parse(value);
  }
  return 0;
}
