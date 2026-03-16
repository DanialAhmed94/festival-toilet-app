import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/festivalsDetail_model.dart';
import '../resource_module/utilities/sharedPrefs.dart';

Future<Festivals> fetchFestivals(String url, {int page = 1, String? search}) async {
  final uri = Uri.parse(url);
  var urlWithPage = uri.query.isEmpty
      ? '$url${url.contains('?') ? '&' : '?'}page=$page'
      : '$url&page=$page';
  if (search != null && search.trim().isNotEmpty) {
    urlWithPage += '&search=${Uri.encodeComponent(search.trim())}';
  }
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('[fetchFestivals] 🌐 REQUEST URL: $urlWithPage');
  final bearerToken = await getToken();
  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (bearerToken != null && bearerToken.isNotEmpty) 'Authorization': 'Bearer $bearerToken',
  };
  final response = await http.get(Uri.parse(urlWithPage), headers: headers);

  // Debug: print full response
  debugPrint('[fetchFestivals] 📊 STATUS: ${response.statusCode}');
  debugPrint('[fetchFestivals] 📋 HEADERS: ${response.headers}');
  debugPrint('[fetchFestivals] 📄 BODY (raw): ${response.body}');
  try {
    final decoded = json.decode(response.body);
    debugPrint('[fetchFestivals] 📦 BODY (decoded): $decoded');
  } catch (_) {
    debugPrint('[fetchFestivals] ⚠️ BODY is not valid JSON');
  }
  debugPrint('═══════════════════════════════════════════════════════════');

  if (response.statusCode == 200) {
    return Festivals.fromJson(json.decode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load festivals');
  }
}
