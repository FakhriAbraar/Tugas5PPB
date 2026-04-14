import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');


  Future<void> addNote(String title, String content, String date, int color) {
    return notes.add({
      'title': title,
      'content': content,
      'date': date,
      'color': color,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateNote(String id, String title, String content, String date, int color) {
    return notes.doc(id).update({
      'title': title,
      'content': content,
      'date': date,
      'color': color,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getNotes() {
    return notes.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }
}