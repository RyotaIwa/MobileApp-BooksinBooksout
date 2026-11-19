import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'book_api_controller.dart';

class BookActivity {
  final String orderId;
  final String collection;
  final BookProduct product;
  final String action;
  final String status;

  const BookActivity({
    required this.orderId,
    required this.collection,
    required this.product,
    required this.action,
    required this.status,
  });

  factory BookActivity.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String collection,
  ) {
    final data = document.data();
    final bookId = data['bookId'] is String ? data['bookId'] as String : '';
    final isRead = data['lastReadAt'] != null;
    final isReturned = data['returnedAt'] != null;
    return BookActivity(
      orderId: document.id,
      collection: collection,
      product: BookProduct(
        id: bookId,
        title: data['title'] is String
            ? data['title'] as String
            : bookId.isNotEmpty
            ? bookId
            : 'Unknown Title',
        author: data['author'] is String
            ? data['author'] as String
            : 'Unknown Author',
        description: data['description'] is String
            ? data['description'] as String
            : 'No description available.',
        imageUrl: data['imageUrl'] is String
            ? data['imageUrl'] as String
            : null,
      ),
      action: data['action'] is String
          ? data['action'] as String
          : isRead
          ? 'Buy'
          : isReturned
          ? 'Rent'
          : '',
      status: data['status'] is String
          ? data['status'] as String
          : isRead
          ? 'Read'
          : isReturned
          ? 'Returned'
          : '',
    );
  }
}

class BookFirestoreController {
  static const purchasesCollection = 'purchases';
  static const rentalsCollection = 'rentals';
  static const readingHistoryCollection = 'reading_history';
  static const usersCollection = 'users';

  final FirebaseFirestore _firestore;
  final String? _configuredUserId;

  BookFirestoreController({FirebaseFirestore? firestore, String? userId})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _configuredUserId = userId;

  String get _userId {
    final userId = _configuredUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('A signed-in user is required to access book data.');
    }
    return userId;
  }

  Future<void> ensureUserProfile({
    required String email,
    String? displayName,
  }) async {
    final userReference = _firestore.collection(usersCollection).doc(_userId);
    final existingUser = await userReference.get();
    final data = <String, dynamic>{
      'uid': _userId,
      'email': email,
      'displayName': displayName,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (!existingUser.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await userReference.set(data, SetOptions(merge: true));
  }

  Future<List<BookActivity>> getActivities() async {
    final collectionNames = [
      purchasesCollection,
      rentalsCollection,
      readingHistoryCollection,
    ];
    final snapshots = await Future.wait(
      collectionNames.map(
        (name) => _firestore
            .collection(name)
            .where('userId', isEqualTo: _userId)
            .get(),
      ),
    );

    final activities = <BookActivity>[];
    for (var index = 0; index < collectionNames.length; index++) {
      activities.addAll(
        snapshots[index].docs.map(
          (document) =>
              BookActivity.fromDocument(document, collectionNames[index]),
        ),
      );
    }
    return activities;
  }

  Future<BookActivity> createActivity({
    required BookProduct product,
    required String action,
  }) async {
    final collection = _collectionForNewAction(action);
    final status = action == 'Rent' ? 'Rented' : 'To read';
    final reference = _firestore.collection(collection).doc();
    await reference.set({
      ..._bookData(product),
      'action': action,
      'status': status,
      'userId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return BookActivity(
      orderId: reference.id,
      collection: collection,
      product: product,
      action: action,
      status: status,
    );
  }

  Future<BookActivity> updateActivity({
    required String orderId,
    required String collection,
    required BookProduct product,
    required String action,
    required String status,
  }) async {
    final targetCollection = _collectionForStatus(action, status);
    final sourceReference = _firestore.collection(collection).doc(orderId);
    final sourceSnapshot = await sourceReference.get();
    final sourceData = sourceSnapshot.data();
    if (sourceData == null) {
      throw StateError('The book activity no longer exists.');
    }
    if (sourceData['userId'] != _userId) {
      throw StateError(
        'This book activity does not belong to the signed-in user.',
      );
    }

    final updatedData = <String, dynamic>{
      ...sourceData,
      ..._bookData(product),
      'action': action,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastReadAt': status == 'Read'
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'returnedAt': status == 'Returned'
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
    };
    final targetReference = _firestore
        .collection(targetCollection)
        .doc(orderId);
    final batch = _firestore.batch();
    batch.set(targetReference, updatedData);
    if (targetCollection != collection) {
      batch.delete(sourceReference);
    }
    await batch.commit();

    return BookActivity(
      orderId: orderId,
      collection: targetCollection,
      product: product,
      action: action,
      status: status,
    );
  }

  Future<void> deleteActivity({
    required String orderId,
    required String collection,
  }) async {
    final reference = _firestore.collection(collection).doc(orderId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('The book activity no longer exists.');
    }
    if (data['userId'] != _userId) {
      throw StateError(
        'This book activity does not belong to the signed-in user.',
      );
    }
    await reference.delete();
  }

  String _collectionForNewAction(String action) {
    switch (action) {
      case 'Buy':
        return purchasesCollection;
      case 'Rent':
        return rentalsCollection;
      default:
        throw ArgumentError.value(action, 'action', 'Unsupported book action.');
    }
  }

  String _collectionForStatus(String action, String status) {
    if (action == 'Buy' && status == 'To read') {
      return purchasesCollection;
    }
    if (action == 'Rent' && status == 'Rented') {
      return rentalsCollection;
    }
    if ((action == 'Buy' && status == 'Read') ||
        (action == 'Rent' && status == 'Returned')) {
      return readingHistoryCollection;
    }
    throw ArgumentError.value(
      '$action / $status',
      'status',
      'Unsupported book activity status.',
    );
  }

  Map<String, dynamic> _bookData(BookProduct product) => {
    'bookId': product.id,
    'title': product.title,
    'author': product.author,
    'description': product.description,
    'imageUrl': product.imageUrl,
  };
}
