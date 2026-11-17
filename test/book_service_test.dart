import 'dart:convert';

import 'package:bookin_bookout/book_service.dart';
import 'package:bookin_bookout/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('API controller executes GET, POST, PUT, and DELETE', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'book-123',
                'volumeInfo': {
                  'title': 'The Hobbit',
                  'authors': ['J. R. R. Tolkien'],
                },
              },
            ],
          }),
          200,
        );
      }

      if (request.method == 'POST') {
        return http.Response('{"id":42,"title":"Buy: The Hobbit"}', 201);
      }

      if (request.method == 'PUT') {
        return http.Response('{"id":42,"title":"Buy: The Hobbit"}', 200);
      }

      return http.Response('', 200);
    });
    final controller = BookApiController(client: client);
    const book = BookProduct(
      id: 'book-123',
      title: 'The Hobbit',
      author: 'J. R. R. Tolkien',
      description: 'A fantasy adventure.',
    );

    final books = await controller.getBooks('hobbit');
    final created = await controller.createOrder(
      product: books.single,
      action: 'Buy',
    );
    final updated = await controller.updateOrder(
      orderId: '42',
      product: book,
      action: 'Buy',
      status: 'Completed',
    );
    final deleted = await controller.deleteOrder('42');
    controller.close();

    expect(books.single.title, 'The Hobbit');
    expect(created.statusCode, 201);
    expect(updated.statusCode, 200);
    expect(deleted.statusCode, 200);
    expect(requests.map((request) => request.method), [
      'GET',
      'POST',
      'PUT',
      'DELETE',
    ]);
    expect(requests[0].url.queryParameters['q'], 'hobbit');
    expect(requests[1].url.path, '/posts');
    expect(requests[1].headers['content-type'], contains('application/json'));
    expect(requests[2].url.path, '/posts/42');
    final updateBody = jsonDecode(requests[2].body) as Map<String, dynamic>;
    expect(
      jsonDecode(updateBody['body'] as String),
      containsPair('status', 'Completed'),
    );
    expect(requests[3].url.path, '/posts/42');
  });

  group('BookProduct', () {
    test('maps a Google Books item into a catalog product', () {
      final product = BookProduct.fromJson({
        'volumeInfo': {
          'title': 'The Hobbit',
          'authors': ['J. R. R. Tolkien'],
          'description': 'A fantasy adventure.',
          'imageLinks': {'thumbnail': 'http://example.com/cover.jpg'},
        },
      });

      expect(product.title, 'The Hobbit');
      expect(product.author, 'J. R. R. Tolkien');
      expect(product.description, 'A fantasy adventure.');
      expect(product.imageUrl, 'https://example.com/cover.jpg');
    });

    test('uses safe defaults when optional catalog fields are missing', () {
      final product = BookProduct.fromJson({});

      expect(product.title, 'Unknown Title');
      expect(product.author, 'Unknown Author');
      expect(product.description, 'No description available.');
      expect(product.imageUrl, isNull);
    });

    test('filters products by title, author, and description', () {
      const product = BookProduct(
        title: 'The Hobbit',
        author: 'J. R. R. Tolkien',
        description: 'A fantasy adventure.',
      );

      expect(product.matchesQuery('hobbit'), isTrue);
      expect(product.matchesQuery('tolkien'), isTrue);
      expect(product.matchesQuery('fantasy'), isTrue);
      expect(product.matchesQuery('history'), isFalse);
      expect(product.matchesQuery('  '), isTrue);
    });

    testWidgets('catalog displays products and filters as the user types', (
      tester,
    ) async {
      const products = [
        BookProduct(
          title: 'The Hobbit',
          author: 'J. R. R. Tolkien',
          description: 'A fantasy adventure.',
        ),
        BookProduct(
          title: 'A Brief History of Time',
          author: 'Stephen Hawking',
          description: 'An introduction to cosmology.',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookSearchSection(loadProducts: (_) async => products),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Catalog'), findsOneWidget);
      expect(find.text('GET response JSON'), findsNothing);
      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('A Brief History of Time'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tolkien');
      await tester.pump();

      expect(find.text('The Hobbit'), findsOneWidget);
      expect(find.text('A Brief History of Time'), findsNothing);
      expect(find.text('1 catalog product'), findsOneWidget);
    });

    testWidgets('book details triggers buy and rent actions', (tester) async {
      final actions = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BookDetailsPage(
            title: 'The Hobbit',
            author: 'J. R. R. Tolkien',
            description: 'A fantasy adventure.',
            onAction: (action) async {
              actions.add(action);
            },
          ),
        ),
      );

      await tester.tap(find.text('Rent Book'));
      await tester.ensureVisible(find.text('Buy Book'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buy Book'));

      expect(actions, ['Rent', 'Buy']);
    });
  });
}
