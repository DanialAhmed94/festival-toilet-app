// providers/bulletinProvider.dart

import 'package:crapadvisor/resource_module/model/NewsModel.dart';
import 'package:flutter/material.dart';
import '../apis/getNews.dart';

class BulletinProvider with ChangeNotifier {
  BulletinResponse? _bulletinResponse;
  bool _isLoading = false;

  BulletinResponse? get bulletinResponse => _bulletinResponse;
  bool get isLoading => _isLoading;

  Future<void> fetchBulletinCollection(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    _bulletinResponse = await getBulletinCollection(context);

    _isLoading = false;
    notifyListeners();
  }
}
