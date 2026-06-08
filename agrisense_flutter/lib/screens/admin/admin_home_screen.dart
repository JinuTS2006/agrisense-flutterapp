import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final result = await AdminService.getDashboardStats();
    if (result['success']) {
      setState(() {
        _stats = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Admin Dashboard', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.15)),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text('System Overview', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 40),
                        
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard('Total Users', _stats['total_users']?.toString() ?? '0', Colors.blue, Icons.people),
                            _buildStatCard('Farmers', _stats['total_farmers']?.toString() ?? '0', Colors.green, Icons.agriculture),
                            _buildStatCard('Buyers', _stats['total_buyers']?.toString() ?? '0', Colors.orange, Icons.shopping_bag),
                            _buildStatCard('Delivery', _stats['total_delivery']?.toString() ?? '0', Colors.purple, Icons.local_shipping),
                            _buildStatCard('Products', _stats['total_products']?.toString() ?? '0', Colors.cyan, Icons.inventory),
                            _buildStatCard('Orders', _stats['total_orders']?.toString() ?? '0', Colors.redAccent, Icons.receipt_long),
                            _buildStatCard('Pending Delivery', _stats['pending_deliveries']?.toString() ?? '0', Colors.amber, Icons.pending_actions),
                          ],
                        ),
                        const SizedBox(height: 40),
                        
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/admin_users'),
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Manage Users'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: const Color(0xFF064E3B),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
