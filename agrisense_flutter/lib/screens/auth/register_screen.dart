import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedRole = 'farmer';
  bool _isLoading = false;

  final primaryGreen = const Color(0xFF4ADE80);
  final bgDark = const Color(0xFF0F172A);

  Future<void> _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.register(
      username: _usernameController.text,
      password: _passwordController.text,
      email: _emailController.text,
      role: _selectedRole,
      fullName: _fullNameController.text,
      city: _cityController.text,
      state: _stateController.text,
      phoneNumber: _phoneController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      _navigateByRole(authProvider.user?.role ?? _selectedRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Registration failed')),
      );
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'farmer':
        Navigator.pushReplacementNamed(context, '/farmer_home');
        break;
      case 'buyer':
        Navigator.pushReplacementNamed(context, '/buyer_home');
        break;
      case 'delivery':
        Navigator.pushReplacementNamed(context, '/delivery_home');
        break;
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin_home');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Text(
                'Agrisense',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to get started.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _buildField(_fullNameController, 'Full Name', Icons.person),
              const SizedBox(height: 14),
              _buildField(_usernameController, 'Username', Icons.account_circle),
              const SizedBox(height: 14),
              _buildField(_emailController, 'Email', Icons.email),
              const SizedBox(height: 14),
              _buildField(_passwordController, 'Password', Icons.lock, obscure: true),
              const SizedBox(height: 14),
              _buildField(_phoneController, 'Phone Number', Icons.phone),
              const SizedBox(height: 14),
              _buildField(_cityController, 'City', Icons.location_city),
              const SizedBox(height: 14),
              _buildField(_stateController, 'State', Icons.map),
              const SizedBox(height: 20),

              // Role selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
                    items: const [
                      DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                      DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                      DropdownMenuItem(value: 'delivery', child: Text('Delivery Agent')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: const Color(0xFF064E3B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: primaryGreen.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
    );
  }
}
