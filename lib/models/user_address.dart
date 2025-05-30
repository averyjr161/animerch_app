class UserAddress {
  final String id;
  final String name;
  final String phone;
  final String address;

  UserAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  // Creates a UserAddress instance from a map (e.g., from Firestore document data)
  factory UserAddress.fromMap(Map<String, dynamic> data, String id) {
    return UserAddress(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
    );
  }

  // Converts UserAddress instance to a map (e.g., for storing in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
