import 'book_api_controller.dart';

export 'book_api_controller.dart';

class BookService {
  static Future<List<BookProduct>> searchBooks(String query) async {
    final controller = BookApiController();
    try {
      return await controller.getBooks(query);
    } finally {
      controller.close();
    }
  }
}
