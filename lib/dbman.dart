import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Basic Manager for Firestore
// by @Bruh124567


class DBMan {
  FirebaseFirestore db = FirebaseFirestore.instance;

  DBMan() {
    // Initialize Firebase
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void addItem(String name, double quantity, double price, double pricepaid) {
    db.collection('items').add({
      'item': name,
      'quantity': quantity,
      'priceperunit': price,
      'price-paid': pricepaid,
      'isChecked': false,
    });
  }

  void deleteItem(String id) {
    db.collection('items').doc(id).delete();
  }
  void updateItem(String id, String name, double quantity, double price, double pricepaid, bool isChecked) {
    db.collection('items').doc(id).update({
      'item': name,
      'quantity': quantity,
      'priceperunit': price,
      'price-paid': pricepaid,
      'isChecked': isChecked,
    });
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('items').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Optionally include the document ID
      return data;
    }).toList();
  }
}