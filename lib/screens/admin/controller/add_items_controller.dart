import 'dart:io';

import 'package:animerch_app/screens/admin/model/add_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Riverpod provider for managing add item form state
final addItemProvider =
    StateNotifierProvider<AddItemNotifier, AddItemState>((ref) {
  return AddItemNotifier();
});

class AddItemNotifier extends StateNotifier<AddItemState> {
  AddItemNotifier() : super(AddItemState()) {
    fetchCategories();
  }

  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('Category');

  // Removes the selected image
  void removeImage() {
    state = state.copyWith(imagePath: null);
  }

  // Sets the image path
  void setImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  // Picks an image from gallery
  Future<void> pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setImagePath(pickedFile.path);
      }
    } catch (e) {
      throw Exception("Error picking image: $e");
    }
  }

  // State update setters
  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void addSize(String size) {
    if (!state.sizes.contains(size)) {
      state = state.copyWith(sizes: [...state.sizes, size]);
    }
  }

  void removeSize(String size) {
    state = state.copyWith(
        sizes: state.sizes.where((s) => s != size).toList());
  }

  void setSizes(List<String> sizes) {
    state = state.copyWith(sizes: sizes);
  }

  void addColor(String color) {
    if (!state.colors.contains(color)) {
      state = state.copyWith(colors: [...state.colors, color]);
    }
  }

  void removeColor(String color) {
    state = state.copyWith(
        colors: state.colors.where((c) => c != color).toList());
  }

  void setColors(List<String> colors) {
    state = state.copyWith(colors: colors);
  }

  void toggleDiscount(bool? isDiscounted) {
    state = state.copyWith(isDiscounted: isDiscounted ?? false);
  }

  void setDiscountPercentage(String percentage) {
    state = state.copyWith(discountPercentage: percentage);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setStockQuantity(int quantity) {
    state = state.copyWith(stockQuantity: quantity);
  }

  // Fetches category list from Firestore
  Future<void> fetchCategories() async {
    try {
      QuerySnapshot snapshot = await categoriesCollection.get();
      List<String> categories =
          snapshot.docs.map((doc) => doc['name'] as String).toList();
      state = state.copyWith(categories: categories);
    } catch (e) {
      throw Exception("Error fetching categories: $e");
    }
  }

  // Uploads image and saves item data to Firestore
  Future<void> uploadAndSaveItem(String name, String price) async {
    if (name.isEmpty ||
        price.isEmpty ||
        state.description == null ||
        state.imagePath == null ||
        state.selectedCategory == null ||
        state.selectedCategory!.isEmpty ||
        state.sizes.isEmpty ||
        state.colors.isEmpty ||
        state.stockQuantity <= 0 ||
        (state.isDiscounted &&
            (state.discountPercentage == null ||
                state.discountPercentage!.isEmpty))) {
      throw Exception("Please fill all the fields and upload an image.");
    }

    setLoading(true);

    try {
      // Upload image to Firebase Storage
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('images/$fileName');
      await ref.putFile(File(state.imagePath!));
      final imageUrl = await ref.getDownloadURL();

      // Save item to Firestore
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await items.add({
        'name': name,
        'price': int.tryParse(price),
        'description': state.description,
        'image': imageUrl,
        'uploadedBy': uid,
        'category': state.selectedCategory,
        'sizes': state.sizes,
        'colors': state.colors,
        'isDiscounted': state.isDiscounted,
        'discountPercentage': state.isDiscounted
            ? int.tryParse(state.discountPercentage!)
            : 0,
        'stockQuantity': state.stockQuantity,
      });

      // Reset state after successful upload
      state = AddItemState();
    } catch (e) {
      throw Exception("Error saving item: $e");
    } finally {
      setLoading(false);
    }
  }

  // Pre-fill state values when editing an existing item
  void initializeForEdit({
    required String description,
    required String selectedCategory,
    required List<String> sizes,
    required List<String> colors,
    required bool isDiscounted,
    required String discountPercentage,
    required int stockQuantity,
  }) {
    state = state.copyWith(
      description: description,
      selectedCategory: selectedCategory,
      sizes: sizes,
      colors: colors,
      isDiscounted: isDiscounted,
      discountPercentage: discountPercentage,
      stockQuantity: stockQuantity,
    );
  }

  void setDiscount(dynamic _) {
    // Optional override or reserved for future use
  }
}
