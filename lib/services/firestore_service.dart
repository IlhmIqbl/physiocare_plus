import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> setDoc(
      String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).set(data);
  }

  Future<void> updateDoc(
      String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDoc(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<DocumentSnapshot> getDoc(String collection, String id) async {
    return await _db.collection(collection).doc(id).get();
  }

  Stream<QuerySnapshot> collectionStream(String collection) {
    return _db.collection(collection).snapshots();
  }

  Future<QuerySnapshot> getCollection(String collection) async {
    return await _db.collection(collection).get();
  }

  Future<DocumentReference> addDoc(
      String collection, Map<String, dynamic> data) async {
    return await _db.collection(collection).add(data);
  }
}
