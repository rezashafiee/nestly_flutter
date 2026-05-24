import 'photo_asset.dart';

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.condition,
    required this.location,
    required this.description,
    required this.sellerName,
    required this.createdAt,
    required this.photo,
    required this.likes,
    this.isMine = false,
  });

  factory Listing.fromJson(Map<String, Object?> json) {
    return Listing(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: _readDouble(json['price']),
      condition: json['condition']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      photo: PhotoAsset.fromJson(_readMap(json['photo'])),
      likes: _readInt(json['likes']),
      isMine: json['isMine'] == true,
    );
  }

  final String id;
  final String title;
  final String category;
  final double price;
  final String condition;
  final String location;
  final String description;
  final String sellerName;
  final DateTime createdAt;
  final PhotoAsset photo;
  final int likes;
  final bool isMine;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.parse(value);
  }
  return 0;
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

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return const {};
}
