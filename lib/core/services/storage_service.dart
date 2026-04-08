import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> uploadFile(File file) async {
    final userId = _auth.currentUser!.uid;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage.ref().child('users/$userId/receipts/$fileName');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }
}
