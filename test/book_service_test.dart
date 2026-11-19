import 'dart:convert';

import 'package:bookin_bookout/book_service.dart';
import 'package:bookin_bookout/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('API controller searches the Google Books catalog', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
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
    });
    final controller = BookApiController(client: client);

    final books = await controller.getBooks('hobbit');
    controller.close();

    expect(books.single.title, 'The Hobbit');
    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters['q'], 'hobbit');
    expect(requests.single.url.queryParameters['printType'], 'books');
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
