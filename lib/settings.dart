import 'package:flutter/material.dart';

/// In-memory settings only (no database). Resets when the app is closed.
class Settings extends ChangeNotifier {
  Settings._();
  static final Settings I = Settings._();

  bool hindi = false; // speak Hindi words
  bool calm = false; // reduced animation
  bool muted = false;

  void update(void Function() f) {
    f();
    notifyListeners();
  }
}
