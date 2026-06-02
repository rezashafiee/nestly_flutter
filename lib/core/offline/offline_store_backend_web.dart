// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'offline_store_backend.dart';

OfflineStoreBackend createOfflineStoreBackend() {
  return BrowserOfflineStoreBackend();
}

class BrowserOfflineStoreBackend implements OfflineStoreBackend {
  static const _prefix = 'nestly:';

  @override
  Future<String?> read(String key) async {
    return html.window.localStorage['$_prefix$key'];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage['$_prefix$key'] = value;
  }

  @override
  Future<void> remove(String key) async {
    html.window.localStorage.remove('$_prefix$key');
  }
}
