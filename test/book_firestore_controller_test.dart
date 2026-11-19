import 'package:bookin_bookout/book_api_controller.dart';
import 'package:bookin_bookout/book_firestore_controller.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const book = BookProduct(
    id: 'google-book-id',
    title: 'The Hobbit',
    author: 'J. R. R. Tolkien',
    description: 'A fantasy adventure.',
    imageUrl: 'https://example.com/cover.jpg',
  );

  test(
    'buying then reading a book moves it from purchases to history',
    () async {
      final firestore = FakeFirebaseFirestore();
      final controller = BookFirestoreController(
        firestore: firestore,
        userId: 'reader-1',
      );

      final purchase = await controller.createActivity(
        product: book,
        action: 'Buy',
      );
      expect(purchase.collection, BookFirestoreController.purchasesCollection);
      expect(purchase.status, 'To read');

      final completed = await controller.updateActivity(
        orderId: purchase.orderId,
        collection: purchase.collection,
        product: book,
        action: 'Buy',
        status: 'Read',
      );

      expect(
        (await firestore
                .collection(BookFirestoreController.purchasesCollection)
                .doc(purchase.orderId)
                .get())
            .exists,
        isFalse,
      );
      final historyDocument = await firestore
          .collection(BookFirestoreController.readingHistoryCollection)
          .doc(purchase.orderId)
          .get();
      expect(historyDocument.data()?['bookId'], book.id);
      expect(historyDocument.data()?['userId'], 'reader-1');
      expect(historyDocument.data()?['status'], 'Read');
      expect(historyDocument.data()?['lastReadAt'], isNotNull);
      expect(
        completed.collection,
        BookFirestoreController.readingHistoryCollection,
      );
    },
  );

  test('renting and returning a book persists it in reading history', () async {
    final firestore = FakeFirebaseFirestore();
    final controller = BookFirestoreController(
      firestore: firestore,
      userId: 'reader-1',
    );

    final rental = await controller.createActivity(
      product: book,
      action: 'Rent',
    );
    final returned = await controller.updateActivity(
      orderId: rental.orderId,
      collection: rental.collection,
      product: book,
      action: 'Rent',
      status: 'Returned',
    );

    expect(
      returned.collection,
      BookFirestoreController.readingHistoryCollection,
    );
    expect(
      (await controller.getActivities()).map((activity) => activity.status),
      ['Returned'],
    );
    await controller.deleteActivity(
      orderId: returned.orderId,
      collection: returned.collection,
    );
    expect(await controller.getActivities(), isEmpty);
  });

  test('activities are scoped to the signed-in user', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection(BookFirestoreController.purchasesCollection)
        .add({
          'bookId': book.id,
          'title': book.title,
          'author': book.author,
          'description': book.description,
          'action': 'Buy',
          'status': 'To read',
          'userId': 'another-reader',
        });
    final controller = BookFirestoreController(
      firestore: firestore,
      userId: 'reader-1',
    );

    expect(await controller.getActivities(), isEmpty);
  });

  test(
    'reads existing reading history records with only screenshot fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection(BookFirestoreController.readingHistoryCollection)
          .doc('history-1')
          .set({
            'bookId': 'google_book_id',
            'lastReadAt': DateTime.utc(2026, 11, 20),
            'userId': 'reader-1',
          });
      final controller = BookFirestoreController(
        firestore: firestore,
        userId: 'reader-1',
      );

      final activities = await controller.getActivities();

      expect(activities.single.product.title, 'google_book_id');
      expect(activities.single.action, 'Buy');
      expect(activities.single.status, 'Read');
    },
  );
}
