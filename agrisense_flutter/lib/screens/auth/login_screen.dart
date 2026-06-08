import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _adminTaps = 0;
  bool _adminMode = false;

  void _handleTitleTap() {
    setState(() {
      _adminTaps++;
      if (_adminTaps >= 5 && !_adminMode) {
        _adminMode = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin Mode Enabled')),
        );
      }
    });
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      if (!mounted) return;
      // Navigate based on role
      final role = authProvider.user?.role;
      if (role == 'farmer') {
        Navigator.pushReplacementNamed(context, '/farmer_home');
      } else if (role == 'buyer') {
        Navigator.pushReplacementNamed(context, '/buyer_home');
      } else if (role == 'delivery') {
        Navigator.pushReplacementNamed(context, '/delivery_home');
      } else if (role == 'admin') {
        if (_adminMode) {
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          await authProvider.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Check credentials.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown role: $role')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Check credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _handleTitleTap,
                child: Text(
                  _adminMode ? 'Agrisense Admin' : 'Agrisense',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _adminMode ? Colors.redAccent : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back to the smart agriculture platform.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                child: Text(
                  'Don\'t have an account? Register',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
