import 'package:animerch_app/Services/auth_service.dart';
import 'package:animerch_app/login_screen.dart';
import 'package:animerch_app/screens/admin/add_items.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final AuthService _authService = AuthService();
final formatCurrency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Items"),
              Tab(text: "My Orders"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add New Item',
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddItems()),
            );
          },
        ),
        body: TabBarView(
          children: [
            _buildMyItemsTab(currentUser),
            _buildMyOrdersTab(currentUser),
          ],
        ),
      ),
    );
  }

  // Display list of items uploaded by the current admin
  Widget _buildMyItemsTab(User? currentUser) {
    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('uploadedBy', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No items uploaded yet"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data()! as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: data['image'] != null
                    ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? 'No Description'),
                    Text("Price: ${formatCurrency.format(data['price'] ?? 0)}"),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddItems(
                            isEditing: true,
                            existingData: data,
                            docId: docs[index].id,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      await FirebaseFirestore.instance
                          .collection('items')
                          .doc(docs[index].id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item deleted')),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Display orders that include items uploaded by the current admin
  Widget _buildMyOrdersTab(User? currentUser) {
    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allOrders = snapshot.data!.docs;

        // Filter only the orders that include the current admin's items
        final myOrders = allOrders.where((doc) {
          final items = List<Map<String, dynamic>>.from(doc['items']);
          return items.any((item) => item['uploadedBy'] == currentUser.uid);
        }).toList();

        if (myOrders.isEmpty) {
          return const Center(child: Text("No orders for your products."));
        }

        return ListView.builder(
          itemCount: myOrders.length,
          itemBuilder: (context, index) {
            final order = myOrders[index];
            final data = order.data() as Map<String, dynamic>;
            final orderId = order.id;
            final status = data['status'] ?? 'pending';

            final shipping = data['shippingAddress'] ?? {};
            final buyerName = shipping['name'] ?? 'Unknown';
            final phoneNumber = shipping['phone'] ?? 'Unknown';
            final address = shipping['address'] ?? 'Unknown';

            final allItems = List<Map<String, dynamic>>.from(data['items']);
            final myItems = allItems
                .where((item) => item['uploadedBy'] == currentUser.uid)
                .toList();

            final totalAmount = myItems.fold<double>(
              0.0,
              (sum, item) => sum + (item['price'] ?? 0) * (item['quantity'] ?? 1),
            );

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Order ID: $orderId"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: $status"),
                    Text("Payment: ${data['paymentMethod']}"),
                    Text("Total Items: ${myItems.length}"),
                    Text(
                      "Total Amount: ${formatCurrency.format(totalAmount)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Buyer: $buyerName"),
                    Text("Contact: $phoneNumber"),
                    Text("Address: $address"),
                    const SizedBox(height: 4),
                    ...myItems.map(
                      (item) => Text(
                        "- ${item['name']} (${formatCurrency.format(item['price'])})",
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'status': value});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Order updated to $value")),
                    );
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'processing', child: Text('Processing')),
                    PopupMenuItem(value: 'shipped', child: Text('Shipped')),
                    PopupMenuItem(value: 'delivered', child: Text('Delivered')),
                    PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  child: const Icon(Icons.edit),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
