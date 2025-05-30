import 'package:animerch_app/providers/cart_provider.dart';
import 'package:animerch_app/screens/user/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Keeps track of cart item IDs that user has selected for checkout
  final Set<String> _selectedItemIds = {};

  @override
  Widget build(BuildContext context) {
    // Watch the cart state provider to get current list of cart items
    final cartItems = ref.watch(cartProvider);

    // Show message if cart is empty
    if (cartItems.isEmpty) {
      return const Center(child: Text('Your cart is empty'));
    }

    // Filter selected items based on user selection
    final selectedItems = cartItems.where((item) => _selectedItemIds.contains(item.id)).toList();

    // Calculate total price for selected items
    final total = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    return Column(
      children: [
        // List of cart items with quantity controls, delete, and selection checkbox
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              final isSelected = _selectedItemIds.contains(item.id);
              final stock = item.stockQuantity;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(item.image, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),

                    // Item details and quantity controls
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Price: ₱${item.price.toStringAsFixed(2)}'),
                          Text('Stock: $stock'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Decrement quantity button (disabled if quantity = 1)
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: item.quantity > 1
                                    ? () => ref.read(cartProvider.notifier).decrementQuantity(item.id)
                                    : null,
                              ),
                              Text('${item.quantity}'),

                              // Increment quantity button (disabled if quantity >= stock)
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: item.quantity < stock
                                    ? () => ref.read(cartProvider.notifier).incrementQuantity(item.id)
                                    : null,
                              ),

                              const Spacer(),

                              // Delete item button
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).removeFromCart(item.id);
                                  setState(() {
                                    _selectedItemIds.remove(item.id);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Checkbox to select item for checkout
                    Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedItemIds.add(item.id);
                          } else {
                            _selectedItemIds.remove(item.id);
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const Divider(),

        // Bottom bar showing total price and checkout button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total price display
              Text(
                'Total: ₱${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // Checkout button, disabled if no items selected
              ElevatedButton(
                onPressed: selectedItems.isEmpty
                    ? null
                    : () async {
                        // Navigate to checkout screen with selected items
                        final bought = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(items: selectedItems),
                          ),
                        );

                        // On successful checkout, remove bought items from cart and clear selection
                        if (bought == true) {
                          final notifier = ref.read(cartProvider.notifier);
                          for (var item in selectedItems) {
                            notifier.removeFromCart(item.id);
                          }
                          setState(() {
                            _selectedItemIds.clear();
                          });
                        }
                      },
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
