import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/getFeedbacksModel.dart';

int totalPages = 0;

void setTotalPages(int totalpages) {
  totalPages = totalpages;
}

int getTotalPages() {
  return totalPages;
}

Future<List<FeedbackItem>> fetchFeedback(
    int pageNumber, String festival_id) async {
  final apiUrl =
      'https://stagingcrapadvisor.semicolonstech.com/api/getFeedback?page=$pageNumber&festival_id=$festival_id';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Check if the response body is not null
      if (response.body != null) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the response data contains the 'data' key
        if (responseData.containsKey('data')) {
          final data = FeedbackData.fromJson(responseData['data']);
          int temptotalPages = data.lastPage.toInt();
          setTotalPages(temptotalPages);
          return data.feedbackItems;
        } else {
          throw Exception('Response does not contain data');
        }
      } else {
        throw Exception('Response body is null');
      }
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load feedback: ${response.statusCode}');
    }
  } catch (e) {
    // Catching any exceptions that occurred during the API call.
    throw Exception('Failed to load feedback: $e');
  }
}
