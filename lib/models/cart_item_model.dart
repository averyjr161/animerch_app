class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final int quantity;
  final String uploadedBy;
  final int stockQuantity; // Total stock available for this item

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
    required this.uploadedBy,
    required this.stockQuantity,
  });

  // Creates a CartItem instance from a Map (e.g., from Firestore)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      image: map['image'] ?? '',
      quantity: (map['quantity'] as num).toInt(),
      uploadedBy: map['uploadedBy'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }

  // Converts CartItem instance to a Map (e.g., for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'uploadedBy': uploadedBy,
      'stockQuantity': stockQuantity,
    };
  }

  // Returns a copy of the CartItem with optional updated quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      image: image,
      quantity: quantity ?? this.quantity,
      uploadedBy: uploadedBy,
      stockQuantity: stockQuantity,
    );
  }
}
