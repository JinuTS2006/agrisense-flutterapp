import 'package:flutter/material.dart';
import '../../services/delivery_service.dart';

class DeliveryAssignmentsScreen extends StatefulWidget {
  const DeliveryAssignmentsScreen({super.key});

  @override
  State<DeliveryAssignmentsScreen> createState() => _DeliveryAssignmentsScreenState();
}

class _DeliveryAssignmentsScreenState extends State<DeliveryAssignmentsScreen> {
  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);
  
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    final assignments = await DeliveryService.getAssignments();
    setState(() {
      _assignments = assignments;
      _isLoading = false;
    });
  }

  Future<void> _sendOtpAndVerify(int assignmentId) async {
    // Step 1: Generate & send OTP to buyer's email
    setState(() => _isLoading = true);
    final genResult = await DeliveryService.generateDeliveryOTP(assignmentId);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (!genResult['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${genResult['error']}')),
      );
      return;
    }

    // Get the OTP from API response
    final otpFromServer = genResult['data']['otp']?.toString() ?? '';

    // Step 2: Show OTP verification dialog with auto-filled OTP
    final otpController = TextEditingController(text: otpFromServer);
    final otpSubmitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP has been auto-filled. Tap "Confirm Delivery" to complete.',
                      style: TextStyle(color: primaryGreen, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The buyer will also receive this OTP via email for verification.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 10),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.white24),
                counterText: '',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (otpSubmitted != true || !mounted) return;

    // Step 3: Send OTP verification → auto-set status to "delivered"
    setState(() => _isLoading = true);
    final result = await DeliveryService.updateAssignmentStatus(assignmentId, 'delivered', otpController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Delivery confirmed successfully!')),
      );
      _fetchAssignments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${result['error']}')),
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
        title: Text('My Assignments', style: TextStyle(color: primaryGreen)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(child: Text('No assignments yet.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    final currentStatus = assignment['status']?.toString().toLowerCase() ?? '';
                    final orderDetails = assignment['order_details'];
                    final isDelivered = currentStatus == 'delivered';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${assignment['order']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(currentStatus).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    currentStatus.toUpperCase(),
                                    style: TextStyle(color: _getStatusColor(currentStatus), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (orderDetails != null) ...[
                              Text('Product: ${orderDetails['product_name'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                              Text('Buyer: ${orderDetails['buyer_name'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                              if (orderDetails['delivery_address'] != null)
                                Text('Address: ${orderDetails['delivery_address']}', style: const TextStyle(color: Colors.white70)),
                              if (orderDetails['contact_number'] != null)
                                Text('Phone: ${orderDetails['contact_number']}', style: const TextStyle(color: Colors.white70)),
                            ],
                            Text('Assigned: ${assignment['assigned_at']?.toString().substring(0, 10) ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 16),
                            if (!isDelivered)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _sendOtpAndVerify(assignment['id']),
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send OTP & Complete Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: bgDark,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text('Delivery Completed', style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'picked_up': return Colors.blue;
      case 'in_transit': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.white;
    }
  }
}
