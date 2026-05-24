import 'dart:async';

import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  Timer? _splashTimer;
  bool _splashComplete = false;

  bool get splashComplete => _splashComplete;

  void start() {
    _splashTimer ??= Timer(const Duration(milliseconds: 1100), () {
      _splashComplete = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }
}

class MergedListenable extends ChangeNotifier {
  MergedListenable(List<Listenable> listenables) : _listenables = listenables {
    for (final listenable in _listenables) {
      listenable.addListener(notifyListeners);
    }
  }

  final List<Listenable> _listenables;

  @override
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
