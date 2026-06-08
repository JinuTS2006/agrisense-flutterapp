import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/delivery_service.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);

  List<dynamic> _assignments = [];
  bool _isLoading = true;

  int _total = 0;
  int _pending = 0;
  int _delivered = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final assignments = await DeliveryService.getAssignments();
    int pending = 0;
    int delivered = 0;
    for (var a in assignments) {
      if (a['status'].toString().toLowerCase() == 'delivered') {
        delivered++;
      } else {
        pending++;
      }
    }
    setState(() {
      _assignments = assignments;
      _total = assignments.length;
      _pending = pending;
      _delivered = delivered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Delivery Agent', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
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
                        Text(
                          'Welcome, ${user?.firstName ?? user?.username ?? 'Agent'}!',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryGreen),
                        ),
                        const SizedBox(height: 8),
                        const Text('Manage your delivery tasks effectively.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 40),
                        
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total', _total.toString(), Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Pending', _pending.toString(), Colors.orange)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Delivered', _delivered.toString(), Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 40),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.85,
                          children: [
                            _buildGlassCard(
                              context: context,
                              emoji: '📦',
                              title: 'Assignments',
                              subtitle: 'View and update task statuses.',
                              buttonText: 'My Tasks',
                              onTap: () => Navigator.pushNamed(context, '/delivery_assignments'),
                              isPrimaryBtn: true,
                            ),
                            _buildGlassCard(
                              context: context,
                              emoji: '👤',
                              title: 'Profile',
                              subtitle: 'Edit your agent details.',
                              buttonText: 'View Profile',
                              onTap: () => Navigator.pushNamed(context, '/delivery_profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool isPrimaryBtn = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPrimaryBtn ? primaryGreen : primaryGreen.withOpacity(0.1),
                  foregroundColor: isPrimaryBtn ? const Color(0xFF064E3B) : primaryGreen,
                  elevation: 0,
                  side: BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
