// providers/performanceProvider.dart

import 'package:flutter/material.dart';
import '../apis/getPerformances.dart';
import '../model/performanceModel.dart';

class PerformanceProvider with ChangeNotifier {
  Performances? _performances;
  bool _isLoading = false;

  Performances? get performances => _performances;
  bool get isLoading => _isLoading;

  Future<void> fetchPerformanceCollection(BuildContext context, String festivalId) async {
    _isLoading = true;
    notifyListeners();

    _performances = await getPerformanceCollection(context, festivalId);

    _isLoading = false;
    notifyListeners();
  }
}
