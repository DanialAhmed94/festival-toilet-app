import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for compute function

class ImageDecoder {
  static Future<Uint8List> decodeImage(String base64String) async {
    // Remove file extension (if present)
    // final extensionPattern = RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false);
    // base64String = base64String.replaceAll(extensionPattern, '');
    return base64Decode(base64String);
  }
}

class MyImageCache {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> getOrDecode(String? base64String) async {
    if (base64String == null) {
      return null;
    }
    if (_cache.containsKey(base64String)) {
      return _cache[base64String];
    } else {
      final decodedImage = await ImageDecoder.decodeImage(base64String);
      _cache[base64String] = decodedImage;
      return decodedImage;
    }
  }
}
