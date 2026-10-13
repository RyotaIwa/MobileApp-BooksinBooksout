import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  static const String apiKey = 'AIzaSyAD0m8xTS3vYbF9I3LyoJLG5ZnIFLcBVTw';

  static Future<List<dynamic>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final encodedQuery = Uri.encodeQueryComponent(query.trim());

    final url = Uri.parse(
      '$baseUrl'
      '?q=$encodedQuery'
      '&maxResults=20'
      '&printType=books'
      '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['items'] ?? [];
    }

    throw Exception(
      'Failed to load books: '
      '${response.statusCode}\n'
      '${response.body}',
    );
  }
}
