import 'dart:io';

import 'package:animerch_app/screens/admin/controller/add_items_controller.dart';
import 'package:animerch_app/widgets/my_button.dart';
import 'package:animerch_app/widgets/show_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddItems extends ConsumerStatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingData;
  final String? docId;

  AddItems({
    super.key,
    this.isEditing = false,
    this.existingData,
    this.docId,
  });

  @override
  ConsumerState<AddItems> createState() => _AddItemsState();
}

class _AddItemsState extends ConsumerState<AddItems> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sizeController;
  late final TextEditingController _colorController;
  late final TextEditingController _discountPercentageController;
  late final TextEditingController _stockQuantityController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _sizeController = TextEditingController();
    _colorController = TextEditingController();
    _discountPercentageController = TextEditingController();
    _stockQuantityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _discountPercentageController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  // Load existing item data into the form fields for editing
  void _initializeEditingState() {
    final notifier = ref.read(addItemProvider.notifier);
    final data = widget.existingData!;

    _nameController.text = data['name'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _descriptionController.text = data['description'] ?? '';
    _discountPercentageController.text =
        data['discountPercentage']?.toString() ?? '';
    _stockQuantityController.text = data['stockQuantity']?.toString() ?? '0';

    notifier.setDescription(_descriptionController.text);
    notifier.setSelectedCategory(data['category'] ?? '');
    notifier.setSizes(List<String>.from(data['sizes'] ?? []));
    notifier.setColors(List<String>.from(data['colors'] ?? []));
    notifier.setDiscount(data['isDiscounted'] ?? false);
    notifier.setDiscountPercentage(_discountPercentageController.text);
    notifier.setStockQuantity(int.tryParse(_stockQuantityController.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addItemProvider);
    final notifier = ref.read(addItemProvider.notifier);

    // Initialize editing form only once
    if (widget.isEditing && widget.existingData != null && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditingState();
        setState(() {
          _isInitialized = true;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.isEditing ? "Edit Item" : "Add New Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (upload / display picked image)
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: state.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(state.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GestureDetector(
                              onTap: notifier.pickImage,
                              child: const Icon(Icons.camera_alt, size: 30),
                            ),
                ),
              ),
              const SizedBox(height: 10),

              // Item name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Price input with Peso prefix
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              // Item description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                onChanged: notifier.setDescription,
              ),
              const SizedBox(height: 10),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: (state.selectedCategory != null && state.selectedCategory!.isNotEmpty)
                    ? state.selectedCategory
                    : null,
                decoration: const InputDecoration(
                  labelText: "Select Category",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value != null) {
                    notifier.setSelectedCategory(value);
                  }
                },
                items: state.categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),

              // Stock quantity
              TextField(
                controller: _stockQuantityController,
                decoration: const InputDecoration(
                  labelText: "Stock Quantity",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = int.tryParse(value);
                  if (qty != null) {
                    notifier.setStockQuantity(qty);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Sizes input
              TextField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: "Sizes (Comma Separated)",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    notifier.addSize(value.trim());
                    _sizeController.clear();
                  }
                },
              ),
              Wrap(
                spacing: 8,
                children: state.sizes
                    .map((size) => Chip(
                          label: Text(size),
                          onDeleted: () => notifier.removeSize(size),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),

              // Colors input
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: "Colors (Comma Separated)",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    notifier.addColor(value.trim());
                    _colorController.clear();
                  }
                },
              ),
              Wrap(
                spacing: 8,
                children: state.colors
                    .map((color) => Chip(
                          label: Text(color),
                          onDeleted: () => notifier.removeColor(color),
                        ))
                    .toList(),
              ),

              // Discount toggle
              Row(
                children: [
                  Checkbox(
                    value: state.isDiscounted,
                    onChanged: (value) {
                      if (value != null) {
                        notifier.toggleDiscount(value);
                      }
                    },
                  ),
                  const Text("Apply Discount"),
                ],
              ),

              // Discount percentage input (only if discounted)
              if (state.isDiscounted)
                TextField(
                  controller: _discountPercentageController,
                  decoration: const InputDecoration(
                    labelText: "Discount Percentage {%}",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: notifier.setDiscountPercentage,
                ),

              const SizedBox(height: 20),

              // Submit button (Save or Update)
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: MyButton(
                        buttonText: widget.isEditing ? "Update Item" : "Save Item",
                        onTab: () async {
                          try {
                            if (widget.isEditing && widget.docId != null) {
                              await FirebaseFirestore.instance
                                  .collection('items')
                                  .doc(widget.docId)
                                  .update({
                                'name': _nameController.text,
                                'price': int.tryParse(_priceController.text),
                                'description': _descriptionController.text,
                                'category': state.selectedCategory,
                                'sizes': state.sizes,
                                'colors': state.colors,
                                'isDiscounted': state.isDiscounted,
                                'discountPercentage': state.isDiscounted
                                    ? int.tryParse(_discountPercentageController.text)
                                    : 0,
                                'stockQuantity': state.stockQuantity,
                                // Image update not yet handled
                              });
                              showSnackBar(context, "Item updated!");
                            } else {
                              await notifier.uploadAndSaveItem(
                                _nameController.text,
                                _priceController.text,
                              );
                              showSnackBar(context, "Item added successfully!");
                            }

                            if (mounted) Navigator.of(context).pop();
                          } catch (e) {
                            showSnackBar(context, "Error: $e");
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
