import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _shouldRefreshHome = false;

  bool get shouldRefreshHome => _shouldRefreshHome;

  void setShouldRefreshHome(bool value) {
    _shouldRefreshHome = value;
    notifyListeners();
  }
}
