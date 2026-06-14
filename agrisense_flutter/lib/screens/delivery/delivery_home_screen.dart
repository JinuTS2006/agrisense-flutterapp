import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/delivery_service.dart';
import 'delivery_assignments_screen.dart';
import 'delivery_profile_screen.dart';
import '../chat/chatbot_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DeliveryDashboardTab(),
    const DeliveryAssignmentsScreen(),
    const DeliveryProfileScreen(),
  ];

  final primaryGreen = const Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Assignments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: const Color(0xFF4ADE80),
        foregroundColor: const Color(0xFF064E3B),
        tooltip: 'AgriBot',
        child: const Text('🌱', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _DeliveryDashboardTab extends StatefulWidget {
  const _DeliveryDashboardTab();

  @override
  State<_DeliveryDashboardTab> createState() => _DeliveryDashboardTabState();
}

class _DeliveryDashboardTabState extends State<_DeliveryDashboardTab> {
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
    if (mounted) {
      setState(() {
        _assignments = assignments;
        _total = assignments.length;
        _pending = pending;
        _delivered = delivered;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
}
