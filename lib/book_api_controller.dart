import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BookProduct {
  final String id;
  final String title;
  final String author;
  final String description;
  final String? imageUrl;

  const BookProduct({
    this.id = '',
    required this.title,
    required this.author,
    required this.description,
    this.imageUrl,
  });

  factory BookProduct.fromJson(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'];
    final info = volumeInfo is Map<String, dynamic>
        ? volumeInfo
        : <String, dynamic>{};
    final authors = info['authors'];
    final imageLinks = info['imageLinks'];
    final images = imageLinks is Map<String, dynamic>
        ? imageLinks
        : <String, dynamic>{};
    final image = images['thumbnail'] ?? images['smallThumbnail'];
    final authorNames = authors is List
        ? authors.whereType<String>().toList()
        : <String>[];

    return BookProduct(
      id: item['id'] is String ? item['id'] as String : '',
      title: info['title'] is String
          ? info['title'] as String
          : 'Unknown Title',
      author: authorNames.isEmpty ? 'Unknown Author' : authorNames.join(', '),
      description: info['description'] is String
          ? info['description'] as String
          : 'No description available.',
      imageUrl: image is String
          ? image.replaceFirst('http://', 'https://')
          : null,
    );
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return title.toLowerCase().contains(normalizedQuery) ||
        author.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery);
  }
}

class ApiCallResult {
  final String method;
  final Uri uri;
  final int statusCode;
  final Map<String, dynamic> json;

  const ApiCallResult({
    required this.method,
    required this.uri,
    required this.statusCode,
    required this.json,
  });

  String get prettyJson => const JsonEncoder.withIndent('  ').convert(json);
}

class BookApiController {
  static const String booksBaseUrl =
      'https://www.googleapis.com/books/v1/volumes';
  static const String demoOrdersBaseUrl =
      'https://jsonplaceholder.typicode.com/posts';
  static const String apiKey = 'AIzaSyAD0m8xTS3vYbF9I3LyoJLG5ZnIFLcBVTw';

  final http.Client _client;

  BookApiController({http.Client? client}) : _client = client ?? http.Client();

  Future<List<BookProduct>> getBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(booksBaseUrl).replace(
      queryParameters: {
        'q': query.trim(),
        'maxResults': '20',
        'printType': 'books',
        'key': apiKey,
      },
    );
    final response = await _client.get(uri);
    final json = _decodeResponse(response);
    if (json.containsKey('data')) {
      throw const FormatException(
        'Book catalog response must be a JSON object.',
      );
    }
    final items = json['items'];
    if (items == null) return [];
    if (items is! List) {
      throw const FormatException('Book catalog items must be a JSON array.');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(BookProduct.fromJson)
        .toList();
  }

  Future<ApiCallResult> createOrder({
    required BookProduct product,
    required String action,
  }) {
    final uri = Uri.parse(demoOrdersBaseUrl);
    return _send(
      'POST',
      uri,
      body: {
        'title': '$action: ${product.title}',
        'body': jsonEncode({
          'bookId': product.id,
          'author': product.author,
          'action': action,
          'status': 'Active',
        }),
        'userId': 1,
      },
    );
  }

  Future<ApiCallResult> updateOrder({
    required String orderId,
    required BookProduct product,
    required String action,
    required String status,
  }) {
    final uri = Uri.parse('$demoOrdersBaseUrl/$orderId');
    return _send(
      'PUT',
      uri,
      body: {
        'title': '$action: ${product.title}',
        'body': jsonEncode({
          'bookId': product.id,
          'author': product.author,
          'action': action,
          'status': status,
        }),
        'userId': 1,
      },
    );
  }

  Future<ApiCallResult> deleteOrder(String orderId) {
    final uri = Uri.parse('$demoOrdersBaseUrl/$orderId');
    return _send('DELETE', uri);
  }

  Future<ApiCallResult> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['content-type'] = 'application/json; charset=UTF-8';
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final json = _decodeResponse(response);

    return ApiCallResult(
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      json: json,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.body}',
        uri: response.request?.url,
      );
    }

    if (response.body.trim().isEmpty) {
      return {'message': 'Request completed with an empty response.'};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  void close() => _client.close();
}
