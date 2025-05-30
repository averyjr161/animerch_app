class AddItemState {
  final String? imagePath;
  final bool isLoading;
  final String? selectedCategory;
  final List<String> categories;
  final List<String> sizes;
  final List<String> colors;
  final bool isDiscounted;
  final String? discountPercentage;
  final int stockQuantity;
  

  final String? name;
  final String? price;
  final String? description;  

  AddItemState({
    this.imagePath,
    this.isLoading = false,
    this.selectedCategory,
    this.categories = const [],
    this.sizes = const [],
    this.colors = const [],
    this.isDiscounted = false,
    this.discountPercentage,
    this.name,
    this.price,
    this.description,
    this.stockQuantity = 0,
  });

  AddItemState copyWith({
    String? imagePath,
    bool? isLoading,
    String? selectedCategory,
    List<String>? categories,
    List<String>? sizes,
    List<String>? colors,
    bool? isDiscounted,
    String? discountPercentage,
    String? name,
    String? price,
    String? description,
    int? stockQuantity,
  }) {
    return AddItemState(
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      isDiscounted: isDiscounted ?? this.isDiscounted,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}
