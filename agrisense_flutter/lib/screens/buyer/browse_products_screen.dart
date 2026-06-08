import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/buyer_service.dart';

class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);
  
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final products = await BuyerService.browseProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _addToCart(int productId, int availableQuantity) async {
    final qtyController = TextEditingController(text: '1');
    final quantitySubmitted = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgDark,
        title: const Text('Enter Quantity', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Quantity',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(qtyController.text);
              if (val != null && val > 0 && val <= availableQuantity) {
                Navigator.pop(context, val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid quantity up to $availableQuantity')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: bgDark),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (quantitySubmitted == null) return;

    final success = await BuyerService.addToCart(productId, quantity: quantitySubmitted);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Available Products', style: TextStyle(color: primaryGreen)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No products available.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          product['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Price: \$${product['price']}', style: TextStyle(color: primaryGreen)),
                            Text('Available: ${product['quantity']}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _addToCart(product['id'], (product['quantity'] as num).toInt()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: const Color(0xFF064E3B),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
