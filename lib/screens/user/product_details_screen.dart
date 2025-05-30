import 'package:animerch_app/models/cart_item_model.dart';
import 'package:animerch_app/providers/cart_provider.dart';
import 'package:animerch_app/screens/user/checkout_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({Key? key, required this.productId}) : super(key: key);

  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int selectedQuantity = 1;

  Future<DocumentSnapshot> _fetchProduct() {
    return FirebaseFirestore.instance.collection('items').doc(widget.productId).get();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchProduct(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Product not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final stock = data['stockQuantity'] ?? 0;

          if (stock > 0) {
  selectedQuantity = selectedQuantity.clamp(1, stock).toInt();
} else {
  selectedQuantity = 0; // cannot select quantity if no stock
}


          final cartItem = CartItem(
            id: widget.productId,
            name: data['name'] ?? 'No Name',
            price: (data['price'] ?? 0).toDouble(),
            image: data['image'] ?? '',
            quantity: selectedQuantity,
            uploadedBy: data['uploadedBy'] ?? '',
            stockQuantity: stock,
          );

         return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: data['image'] != null
              ? Image.network(
                  data['image'],
                  height: 220,
                  width: 220,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 220,
                  width: 220,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 100),
                ),
        ),
      ),
      const SizedBox(height: 24),

      // PRODUCT INFO CARD
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(data['price'] ?? 0),
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
            ),
            const SizedBox(height: 12),
            Text(
              data['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Stock: $stock",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: stock > 0 ? Colors.black87 : Colors.red,
              ),
            ),
            const SizedBox(height: 12),

            // QUANTITY SELECTOR
            Row(
              children: [
                const Text("Quantity: ", style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: selectedQuantity > 1
                      ? () => setState(() => selectedQuantity--)
                      : null,
                ),
                Text('$selectedQuantity', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: selectedQuantity < stock
                      ? () => setState(() => selectedQuantity++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),

      // ACTION BUTTONS
      Row(
        children: [
          IconButton(
            tooltip: 'Add to Cart',
            onPressed: stock == 0
                ? null
                : () {
                    ref.read(cartProvider.notifier).addToCart(cartItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item added to cart')),
                    );
                  },
            icon: const Icon(Icons.add_shopping_cart),
            color: Colors.deepPurple,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: stock == 0
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(items: [cartItem]),
                        ),
                      );
                    },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Buy Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
        },
      ),
    );
  }
}