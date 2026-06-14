import 'package:flutter/material.dart';
import '../../services/buyer_service.dart';
import '../../config/api_config.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);
  
  List<dynamic> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    final items = await BuyerService.getCart();
    setState(() {
      _cartItems = items;
      _isLoading = false;
    });
  }

  Future<void> _checkout() async {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    final addressSubmitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgDark,
        title: const Text('Delivery Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryGreen)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryGreen)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Gmail Address',
                hintText: 'example@gmail.com',
                hintStyle: const TextStyle(color: Colors.white24),
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryGreen)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: bgDark),
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );

    if (addressSubmitted != true) return;

    setState(() => _isLoading = true);
    final initResult = await BuyerService.checkoutInitiate(addressController.text, phoneController.text, emailController.text);
    setState(() => _isLoading = false);

    if (!initResult['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${initResult['error']}')));
      return;
    }
    
    // Get the OTP and checkout token from the response
    final testOtp = initResult['data']['otp'];
    final checkoutToken = initResult['data']['checkout_token'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent to your email! (TEST: $testOtp)')));

    final otpController = TextEditingController();
    final otpSubmitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgDark,
        title: const Text('Verify Checkout', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cash on Delivery selected. Please enter the OTP sent to your email address to verify this order.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '000000', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: bgDark),
            child: const Text('Verify & Place Order'),
          ),
        ],
      ),
    );

    if (otpSubmitted != true) return;

    setState(() => _isLoading = true);
    final result = await BuyerService.checkout(otpController.text, checkoutToken);
    if (!mounted) return;
    if (result['success']) {
      final data = result['data'];
      final message = data['message'] ?? 'Checkout successful!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushReplacementNamed(context, '/buyer_orders');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['error']}')));
    }
  }

  Future<void> _remove(int id) async {
    final success = await BuyerService.removeFromCart(id);
    if (success) _fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Cart', style: TextStyle(color: primaryGreen)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty.', style: TextStyle(color: Colors.white70)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final product = item['product_details'];
                          if (product == null) {
                            return const SizedBox.shrink();
                          }
                          final imageUrl = product['image'] != null
                              ? (product['image'].toString().startsWith('http')
                                  ? product['image'].toString()
                                  : '${ApiConfig.baseUrl}${product['image']}')
                              : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.white.withOpacity(0.1),
                                          child: const Icon(Icons.image_not_supported, color: Colors.white38),
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.white.withOpacity(0.1),
                                        child: Icon(Icons.eco, color: primaryGreen),
                                      ),
                              ),
                              title: Text(product['name'], style: const TextStyle(color: Colors.white)),
                              subtitle: Text('Qty: ${item['quantity']} | \$${product['price']}', style: const TextStyle(color: Colors.white70)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _remove(item['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: const Color(0xFF064E3B),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
