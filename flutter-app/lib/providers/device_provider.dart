import 'package:flutter/foundation.dart';

class DeviceProvider with ChangeNotifier {
  bool _isLocked = false;
  bool _isAdminActive = false;

  bool get isLocked => _isLocked;
  bool get isAdminActive => _isAdminActive;

  void setLocked(bool locked) {
    _isLocked = locked;
    notifyListeners();
  }

  void setAdminActive(bool active) {
    _isAdminActive = active;
    notifyListeners();
  }
}

