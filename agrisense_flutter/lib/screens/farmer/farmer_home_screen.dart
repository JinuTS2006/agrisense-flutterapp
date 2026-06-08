import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final primaryGreen = const Color(0xFF4ADE80);

    return Scaffold(
      // A dark, rich background
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Agrisense',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
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
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryGreen.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Hello, ${user?.firstName ?? user?.username ?? 'Farmer'}!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor your farm and sales performance from your command center.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Grid of Glass Cards
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
                        emoji: '👤',
                        title: 'Profile',
                        subtitle: 'Edit your personal and farm details.',
                        buttonText: 'View Profile',
                        onTap: () => Navigator.pushNamed(context, '/farmer_profile'),
                        primaryGreen: primaryGreen,
                      ),
                      _buildGlassCard(
                        context: context,
                        emoji: '🍎',
                        title: 'Products',
                        subtitle: 'Update your harvest and stock levels.',
                        buttonText: 'View products',
                        onTap: () => Navigator.pushNamed(context, '/my_products'),
                        primaryGreen: primaryGreen,
                      ),
                      _buildGlassCard(
                        context: context,
                        emoji: '📊',
                        title: 'Profit Analysis',
                        subtitle: 'Check your expected profits and trends.',
                        buttonText: 'Open Analysis',
                        onTap: () => Navigator.pushNamed(context, '/profit_analysis'),
                        primaryGreen: primaryGreen,
                      ),
                      _buildGlassCard(
                        context: context,
                        emoji: '📦',
                        title: 'Orders',
                        subtitle: 'View and manage incoming buyer requests.',
                        buttonText: 'View Orders',
                        onTap: () => Navigator.pushNamed(context, '/farmer_orders'),
                        primaryGreen: primaryGreen,
                      ),
                      _buildGlassCard(
                        context: context,
                        emoji: '🧠',
                        title: 'Crop Rec.',
                        subtitle: 'AI-powered crop suggestions.',
                        buttonText: 'Get Advice',
                        isPrimaryBtn: true,
                        onTap: () => Navigator.pushNamed(context, '/crop_recommendation'),
                        primaryGreen: primaryGreen,
                      ),
                      _buildGlassCard(
                        context: context,
                        emoji: '🚜',
                        title: 'Yield Predict',
                        subtitle: 'Predict total crop yield for season.',
                        buttonText: 'Predict Now',
                        onTap: () => Navigator.pushNamed(context, '/yield_prediction'),
                        primaryGreen: primaryGreen,
                      ),
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

  Widget _buildGlassCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    required Color primaryGreen,
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
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPrimaryBtn ? primaryGreen : primaryGreen.withOpacity(0.1),
                  foregroundColor: isPrimaryBtn ? const Color(0xFF064E3B) : primaryGreen,
                  elevation: 0,
                  side: BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
