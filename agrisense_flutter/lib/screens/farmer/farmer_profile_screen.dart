import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/farmer_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  final Color primaryGreen = const Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await FarmerService.getProfile();
    if (mounted) {
      if (res['success']) {
        setState(() {
          _profile = res['data'];
          _cityController.text = _profile?['city'] ?? '';
          _stateController.text = _profile?['state'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final success = await FarmerService.updateProfile(_cityController.text, _stateController.text);
    setState(() => _isSaving = false);
    
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.15)))),
          Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)))),
          
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Farmer Profile', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryGreen)),
                      const SizedBox(height: 8),
                      const Text('Manage your account and farm location details.', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 40),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Full Name'),
                                Text(user?.firstName ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                
                                _buildLabel('Username'),
                                Text(user?.username ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 20),
                                
                                _buildLabel('Verification Status'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (_profile?['is_verified'] == true) ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: (_profile?['is_verified'] == true) ? Colors.green : Colors.orange),
                                  ),
                                  child: Text(
                                    (_profile?['is_verified'] == true) ? 'Verified Farmer' : 'Pending Verification',
                                    style: TextStyle(color: (_profile?['is_verified'] == true) ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 30),
                                
                                _buildLabel('Farm City'),
                                TextField(
                                  controller: _cityController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(),
                                ),
                                const SizedBox(height: 20),
                                
                                _buildLabel('Farm State'),
                                TextField(
                                  controller: _stateController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(),
                                ),
                                const SizedBox(height: 30),
                                
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: const Color(0xFF064E3B),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: _isSaving 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF064E3B))) 
                                    : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
    );
  }
}
