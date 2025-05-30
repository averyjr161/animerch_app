import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animerch_app/models/user_address.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({Key? key}) : super(key: key);

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Current user ID fetched from Firebase Authentication
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  // Adds a new address to Firestore under current user's 'addresses' subcollection
  Future<void> _addAddress() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Simple validation to ensure no field is empty
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('addresses')
        .add({
      'name': name,
      'phone': phone,
      'address': address,
    });

    // Clear the input fields after adding
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  // Deletes an address by document ID from Firestore
  Future<void> _deleteAddress(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('addresses')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final addressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('addresses');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Addresses')),
      body: Column(
        children: [
          // Input form for adding new address
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Address"),
                  onPressed: _addAddress,
                ),
              ],
            ),
          ),

          // List of saved addresses with real-time updates using StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: addressRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading addresses'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final addresses = snapshot.data!.docs
                    .map((doc) => UserAddress.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                if (addresses.isEmpty) {
                  return const Center(child: Text('No saved addresses'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    return ListTile(
                      title: Text(addr.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone: ${addr.phone}"),
                          Text(addr.address),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAddress(addr.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
