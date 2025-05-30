import 'package:animerch_app/models/cart_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// StateNotifier to manage the user's cart state
class CartNotifier extends StateNotifier<List<CartItem>> {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CartNotifier(this.userId) : super([]) {
    _loadCartFromFirestore();
  }

  // Clear the cart and save changes to Firestore
  void clearCart() {
    state = [];
    _saveCartToFirestore();
  }

  // Load cart data from Firestore on initialization
  Future<void> _loadCartFromFirestore() async {
    try {
      final doc = await _firestore.collection('carts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['items'] != null) {
          final List<dynamic> items = data['items'];
          state = items.map((item) => CartItem.fromMap(item)).toList();
        }
      }
    } catch (e) {
      print('Error loading cart from Firestore: $e');
    }
  }

  // Save the current cart state to Firestore
  Future<void> _saveCartToFirestore() async {
    try {
      final items = state.map((item) => item.toMap()).toList();
      await _firestore.collection('carts').doc(userId).set({'items': items});
    } catch (e) {
      print('Error saving cart to Firestore: $e');
    }
  }

  // Add item to cart or increase quantity if it already exists
  void addToCart(CartItem item) {
    final index = state.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      state = [...state, item];
    } else {
      final updatedItem = state[index].copyWith(quantity: state[index].quantity + 1);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) updatedItem else state[i],
      ];
    }
    _saveCartToFirestore();
  }

  // Remove item from cart by ID
  void removeFromCart(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveCartToFirestore();
  }

  // Increase quantity of a specific cart item
  void incrementQuantity(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = state[index];
      final updatedItem = item.copyWith(quantity: item.quantity + 1);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) updatedItem else state[i],
      ];
      _saveCartToFirestore();
    }
  }

  // Decrease quantity of a specific cart item (or remove if quantity becomes 0)
  void decrementQuantity(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = state[index];
      if (item.quantity > 1) {
        final updatedItem = item.copyWith(quantity: item.quantity - 1);
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) updatedItem else state[i],
        ];
      } else {
        removeFromCart(id);
      }
      _saveCartToFirestore();
    }
  }
}

// Riverpod provider for the cart using FirebaseAuth user ID
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  return CartNotifier(userId);
});
