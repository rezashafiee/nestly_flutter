import 'dart:io';

import 'offline_store_backend.dart';

OfflineStoreBackend createOfflineStoreBackend() {
  return FileOfflineStoreBackend();
}

class FileOfflineStoreBackend implements OfflineStoreBackend {
  FileOfflineStoreBackend({List<Directory>? candidates})
    : _candidates = candidates ?? _defaultDirectories();

  final List<Directory> _candidates;

  @override
  Future<String?> read(String key) async {
    for (final directory in _candidates) {
      final file = _fileFor(directory, key);
      try {
        if (await file.exists()) {
          return file.readAsString();
        }
      } catch (_) {
        // Try the next storage location.
      }
    }
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    Object? lastError;
    for (final directory in _candidates) {
      try {
        await directory.create(recursive: true);
        await _fileFor(directory, key).writeAsString(value, flush: true);
        return;
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw FileSystemException('Unable to write offline data', key);
    }
  }

  @override
  Future<void> remove(String key) async {
    for (final directory in _candidates) {
      final file = _fileFor(directory, key);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Removing cached data is best-effort.
      }
    }
  }

  File _fileFor(Directory directory, String key) {
    return File(_joinPath(directory.path, '${_sanitizeKey(key)}.json'));
  }
}

List<Directory> _defaultDirectories() {
  final directories = <Directory>[];
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.trim().isNotEmpty) {
    directories.add(Directory(_joinPath(home, '.nestly')));
  }
  directories.add(Directory(_joinPath(Directory.systemTemp.path, 'nestly')));
  return directories;
}

String _joinPath(String directory, String child) {
  if (directory.endsWith(Platform.pathSeparator)) {
    return '$directory$child';
  }
  return '$directory${Platform.pathSeparator}$child';
}

String _sanitizeKey(String key) {
  return key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
