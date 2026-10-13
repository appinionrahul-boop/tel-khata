# Enable cloud sync with Firebase

Sync needs a signed-in user so each person only sees their own data. These steps use
Firebase Auth (anonymous or Google sign-in) and Cloud Firestore.

## 1. Create the Firebase project

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android
```

This creates `lib/firebase_options.dart` and registers the Android app.
In the Firebase console, enable **Firestore** and **Authentication** (Anonymous or Google).

## 2. Add packages

```bash
flutter pub add firebase_core firebase_auth cloud_firestore
```

## 3. Add the remote store

Create `lib/services/sync/firestore_remote_store.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'remote_store.dart';

class FirestoreRemoteStore implements RemoteStore {
  static const int _batchLimit = 400;

  final FirebaseFirestore _db;
  final String uid;

  FirestoreRemoteStore(this._db, this.uid);

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(uid).collection(name);

  @override
  Future<void> push(String collection, List<Map<String, Object?>> rows) async {
    for (var i = 0; i < rows.length; i += _batchLimit) {
      final batch = _db.batch();
      for (final row in rows.skip(i).take(_batchLimit)) {
        batch.set(_col(collection).doc(row['id'] as String), row);
      }
      await batch.commit();
    }
  }

  @override
  Future<List<Map<String, Object?>>> pullSince(String collection, int sinceMs) async {
    final snap = await _col(collection).where('updated_at', isGreaterThan: sinceMs).get();
    return snap.docs.map((d) => Map<String, Object?>.from(d.data())).toList();
  }
}
```

## 4. Wire it up in `main.dart`

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
final auth = FirebaseAuth.instance;
final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
final sync = SyncManager(repos, settings, FirestoreRemoteStore(FirebaseFirestore.instance, user.uid));
```

Anonymous sign-in keeps data on one device's account. To sync across phones, switch to
Google sign-in so the same `uid` is used everywhere.

## 5. Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{collection}/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

The app works fully offline; sync failures (no internet) are shown in Settings and retried
on the next app open, resume or change.
