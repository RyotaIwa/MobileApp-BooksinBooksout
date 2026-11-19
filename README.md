# Bookin & Bookout

## App description

Bookin & Bookout is a Flutter book discovery and personal library app. Readers
can search the Google Books catalog, add books to a purchased or rented shelf,
mark books as read, return rentals, and remove entries.

## Features

- Register, sign in, and sign out with Firebase Authentication.
- Validate registration and login form inputs before sending requests.
- Search and browse books through the Google Books API.
- Create, read, update, and delete user-owned book activity in Cloud Firestore.
- Move completed purchases and returned rentals into reading history.
- Navigate between the dashboard, catalog, purchases, rentals, and history.

## Technologies and integrations

- Flutter and Dart with Material 3.
- Firebase Authentication for email/password accounts.
- Cloud Firestore for user profiles and book activity.
- Google Books API as the catalog server/API integration.

## Firebase setup

The app initializes Firebase from `lib/firebase_options.dart` and uses the
`bookinout-a6047` project. In Firebase Console, enable Email/Password under
**Authentication → Sign-in method** and create a Cloud Firestore database.

Publish the rules in `firestore.rules` from **Firestore Database → Rules**.
These rules restrict profile and book activity access to the signed-in user.
Do not use test-mode rules.

The app creates the records it needs; no example documents are required:

- `users/{uid}`: `uid`, `email`, `displayName`, `createdAt`, and `lastSeenAt`.
- `purchases/{id}`: bought books not yet marked as read.
- `rentals/{id}`: books currently rented.
- `reading_history/{id}`: books marked read or rentals returned.

Book activity records contain `bookId`, `title`, `author`, `description`,
`imageUrl`, `action`, `status`, `userId`, and server timestamps. Read records
also include `lastReadAt`; returned rentals include `returnedAt`. Activity
queries are filtered by the authenticated user's UID. The existing
`saved_books` collection is not currently used.

## Run and verify

From the project directory:

```shell
flutter pub get
flutter run
```

Run the automated checks with:

```shell
flutter analyze
flutter test
```

## Assessment demonstration and evidence

Use an Android emulator or device and a test account in the configured Firebase
project. Capture genuine screenshots of:

1. Login and registration forms.
2. The dashboard and navigation drawer.
3. Searching the catalog and viewing a book.
4. Adding a purchase and a rental, then marking the purchase read and returning
   the rental.
5. Removing a book and the resulting shelves/history.
6. Firebase Authentication showing the test account and Firestore showing its
   user profile and activity documents.
7. Google Books search results as evidence of the API integration.

Use the Firebase Console to capture Authentication and Firestore evidence.
Do not include real user passwords or other sensitive account information.
