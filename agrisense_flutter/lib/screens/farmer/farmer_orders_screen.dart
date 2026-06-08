import 'package:flutter/material.dart';
import '../../services/farmer_service.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await FarmerService.getOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String currentStatus) async {
    String? newStatus;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              leading: Radio<String>(value: 'pending', groupValue: currentStatus, onChanged: (v) { newStatus = v; Navigator.pop(ctx); }),
            ),
            ListTile(
              title: const Text('Accepted'),
              leading: Radio<String>(value: 'accepted', groupValue: currentStatus, onChanged: (v) { newStatus = v; Navigator.pop(ctx); }),
            ),
            ListTile(
              title: const Text('Completed'),
              leading: Radio<String>(value: 'completed', groupValue: currentStatus, onChanged: (v) { newStatus = v; Navigator.pop(ctx); }),
            ),
            ListTile(
              title: const Text('Cancelled'),
              leading: Radio<String>(value: 'cancelled', groupValue: currentStatus, onChanged: (v) { newStatus = v; Navigator.pop(ctx); }),
            ),
          ],
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      final success = await FarmerService.updateOrderStatus(orderId, newStatus!);
      if (success) {
        _loadOrders();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty
          ? const Center(child: Text('No orders yet.', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(order['status'])),
                              ),
                              child: Text(
                                order['status'].toString().toUpperCase(),
                                style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Product: ${order['product_name']}', style: const TextStyle(fontSize: 16)),
                        Text('Quantity: ${order['quantity']}'),
                        Text('Total Amount: ₹${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(order['id'], order['status']),
                            child: const Text('Update Status'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
