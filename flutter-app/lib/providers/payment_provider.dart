import 'package:flutter/foundation.dart';
import '../models/api_models.dart';

class PaymentProvider with ChangeNotifier {
  PaymentStatusResponse? _status;
  PaymentSchedule? _schedule;
  List<PaymentHistoryItem> _history = [];

  PaymentStatusResponse? get status => _status;
  PaymentSchedule? get schedule => _schedule;
  List<PaymentHistoryItem> get history => _history;

  void updateStatus(PaymentStatusResponse status) {
    _status = status;
    notifyListeners();
  }

  void updateSchedule(PaymentSchedule schedule) {
    _schedule = schedule;
    notifyListeners();
  }

  void updateHistory(List<PaymentHistoryItem> history) {
    _history = history;
    notifyListeners();
  }
}

