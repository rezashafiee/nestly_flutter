import 'dart:convert';
import 'dart:typed_data';

class PhotoAsset {
  const PhotoAsset({
    required this.iconKey,
    required this.colorValue,
    this.imageData,
  });

  factory PhotoAsset.fromJson(Map<String, Object?> json) {
    return PhotoAsset(
      iconKey: json['iconKey']?.toString() ?? 'chair',
      colorValue: _readInt(json['colorValue']),
      imageData: json['imageData']?.toString(),
    );
  }

  final String iconKey;
  final int colorValue;
  final String? imageData;

  Uint8List? get imageBytes {
    final data = imageData;
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      return base64Decode(data);
    } on FormatException {
      return null;
    }
  }

  Map<String, Object?> toJson() {
    final data = imageData;
    return {
      'iconKey': iconKey,
      'colorValue': colorValue,
      if (data != null && data.isNotEmpty) 'imageData': data,
    };
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
