import 'dart:convert';

import 'offline_store_backend.dart';
import 'offline_store_backend_factory.dart'
    if (dart.library.io) 'offline_store_backend_io.dart'
    if (dart.library.html) 'offline_store_backend_web.dart';

class OfflineJsonStore {
  OfflineJsonStore({OfflineStoreBackend? backend})
    : _backend = backend ?? createOfflineStoreBackend();

  OfflineJsonStore.inMemory() : _backend = MemoryOfflineStoreBackend();

  final OfflineStoreBackend _backend;

  Future<Map<String, Object?>?> readMap(String key) async {
    final decoded = await _readJson(key);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    return null;
  }

  Future<List<Object?>> readList(String key) async {
    final decoded = await _readJson(key);
    if (decoded is List<Object?>) {
      return decoded;
    }
    if (decoded is List) {
      return decoded.cast<Object?>();
    }
    return const [];
  }

  Future<void> writeMap(String key, Map<String, Object?> value) async {
    await _writeJson(key, value);
  }

  Future<void> writeList(String key, List<Object?> value) async {
    await _writeJson(key, value);
  }

  Future<void> remove(String key) async {
    try {
      await _backend.remove(key);
    } catch (_) {
      // Offline storage is an enhancement; callers should keep working.
    }
  }

  Future<Object?> _readJson(String key) async {
    try {
      final encoded = await _backend.read(key);
      if (encoded == null || encoded.trim().isEmpty) {
        return null;
      }
      return jsonDecode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJson(String key, Object? value) async {
    try {
      await _backend.write(key, jsonEncode(value));
    } catch (_) {
      // Keep the app responsive even when a platform refuses local storage.
    }
  }
}

String offlineKeyPart(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'anonymous';
  }
  return normalized.replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
}
