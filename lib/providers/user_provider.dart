import 'dart:async';
import 'package:animerch_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider to access the current authenticated user's data
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

// Manages and listens to changes in the current user's Firestore data
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
    _listenToUser(); // 
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Subscribes to real-time updates of the current user's Firestore document
  void _listenToUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        state = UserModel.fromMap(doc.data()!);
      }
    });
  }

  // Cancel the Firestore subscription when the notifier is disposed
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
