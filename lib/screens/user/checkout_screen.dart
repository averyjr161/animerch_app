import 'package:animerch_app/models/cart_item_model.dart';
import 'package:animerch_app/models/user_address.dart';
import 'package:animerch_app/models/user_model.dart';
import 'package:animerch_app/providers/cart_provider.dart';
import 'package:animerch_app/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  // Optional parameter for direct "Buy Now" purchases (not from full cart)
  final List<CartItem>? items;

  const CheckoutScreen({super.key, this.items});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId; // Selected shipping address ID
  bool _isPlacingOrder = false; // Loading state during order placement
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default payment method

  // Get cart items from either passed items or the cart provider (default)
  List<CartItem> get cartItems => widget.items ?? ref.watch(cartProvider);

  // Fetch the logged-in user's saved addresses from Firestore
  Future<List<UserAddress>> _fetchAddresses() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();

    return snapshot.docs
        .map((doc) => UserAddress.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Main order placement logic: creates an order and updates stock quantities
  void _placeOrder(
    UserModel user,
    List<CartItem> cartItems,
    UserAddress selectedAddress,
  ) async {
    setState(() => _isPlacingOrder = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Prepare list of ordered items for Firestore
      final cartSnapshot = cartItems.map((item) => {
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'uploadedBy': item.uploadedBy,
            'productId': item.id,
          }).toList();

      // Order document to be stored
      final order = {
        'userId': userId,
        'email': user.email,
        'items': cartSnapshot,
        'shippingAddress': {
          'name': selectedAddress.name,
          'phone': selectedAddress.phone,
          'address': selectedAddress.address,
        },
        'paymentMethod': _selectedPaymentMethod,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };

      // Add order to Firestore orders collection
      await firestore.collection('orders').add(order);

      // 🔻 Update stock quantities atomically with transaction
      for (final item in cartItems) {
        final docRef = firestore.collection('items').doc(item.id);
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) return;

          final currentStock = snapshot['stockQuantity'] ?? 0;
          final newStock = currentStock - item.quantity;

          transaction.update(docRef, {
            'stockQuantity': newStock < 0 ? 0 : newStock,
          });
        });
      }

      // Clear the cart only if the checkout was from the full cart (not direct buy)
      if (widget.items == null) {
        ref.read(cartProvider.notifier).clearCart();
      }

      // Show success message and pop the checkout screen with success flag
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      // Show error if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  // Calculate total price of the items in the checkout list
  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (total, item) => total + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    // Get current logged-in user from provider
    final user = ref.watch(userProvider);

    // Show loading while user info is not yet available
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show message if cart/items list is empty
    if (cartItems.isEmpty) {
      return const Scaffold(body: Center(child: Text("Your cart is empty")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Shipping Address:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),

              // Load and display saved user addresses with radio button selection
              FutureBuilder<List<UserAddress>>(
                future: _fetchAddresses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading addresses');
                  }
                  final addresses = snapshot.data!;
                  if (addresses.isEmpty) {
                    return const Text("No addresses saved.");
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      final isSelected = _selectedAddressId == address.id;
                      return ListTile(
                        title: Text(address.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address.phone),
                            Text(address.address),
                          ],
                        ),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Colors.deepPurple : null,
                        ),
                        tileColor: isSelected ? Colors.deepPurple.shade50 : null,
                        onTap: () {
                          setState(() => _selectedAddressId = address.id);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Display the list of items being purchased
              const Text("Items:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text("Qty: ${item.quantity} | ₱${item.price.toStringAsFixed(2)}"),
                    trailing: Text("Total: ₱${(item.price * item.quantity).toStringAsFixed(2)}"),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Show total price
              Text(
                "Total Price: ₱${_calculateTotal(cartItems).toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Payment method selection - currently only Cash on Delivery
              const Text("Select Payment Method:", style: TextStyle(fontSize: 16)),
              RadioListTile<String>(
                value: 'Cash on Delivery',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value!);
                },
                title: const Text('Cash on Delivery'),
              ),
              const SizedBox(height: 16),

              // Place order button, disabled if loading or no address selected
              ElevatedButton(
                child: Text(
                  _isPlacingOrder ? "Placing Order..." : "Place Order",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: _isPlacingOrder || _selectedAddressId == null
                    ? null
                    : () async {
                        // Find the selected address object by ID
                        final selected = (await _fetchAddresses())
                            .firstWhere((a) => a.id == _selectedAddressId!);
                        // Start placing order
                        _placeOrder(user, cartItems, selected);
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
