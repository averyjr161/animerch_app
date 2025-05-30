import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // include doc ID for later reference
      return data;
    }).toList();
  }

  Future<void> _cancelOrder(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': 'cancelled'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Purchases')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No purchases yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['status'] ?? 'pending';

              return Card(
                child: ListTile(
                  title: Text("Order ID: ${order['id']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: $status"),
                      Text("Total Items: ${order['items'].length}"),
                      Text("Payment: ${order['paymentMethod']}"),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await _cancelOrder(order['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Order cancelled.")),
                            );
                          },
                          child: const Text('Cancel Order'),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shipping = order['shippingAddress'];
    final items = order['items'] as List;

    double totalPrice = items.fold(0.0, (total, item) {
      return total + ((item['price'] as num) * (item['quantity'] as num));
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Order ID: ${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Status: ${order['status']}"),
            Text("Payment Method: ${order['paymentMethod']}"),
            const Divider(height: 32),

            Text("Shipping Address", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Name: ${shipping['name']}"),
            Text("Phone: ${shipping['phone']}"),
            Text("Address: ${shipping['address']}"),
            const Divider(height: 32),

            Text("Items", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name']),
                subtitle: Text("Qty: ${item['quantity']}"),
                trailing: Text("₱${(item['price'] as num).toStringAsFixed(2)}"),
              );
            }).toList(),

            const Divider(height: 32),
            Text(
              "Total Price: ₱${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
