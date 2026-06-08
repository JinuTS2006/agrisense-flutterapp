import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/farmer/farmer_home_screen.dart';
import 'screens/farmer/crop_recommendation_screen.dart';
import 'screens/farmer/yield_prediction_screen.dart';
import 'screens/farmer/profit_analysis_screen.dart';
import 'screens/farmer/my_products_screen.dart';
import 'screens/farmer/add_product_screen.dart';
import 'screens/farmer/farmer_orders_screen.dart';
import 'screens/farmer/farmer_profile_screen.dart';

// Buyer screens
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/buyer/browse_products_screen.dart';
import 'screens/buyer/cart_screen.dart';
import 'screens/buyer/buyer_orders_screen.dart';
import 'screens/buyer/buyer_profile_screen.dart';

// Delivery screens
import 'screens/delivery/delivery_home_screen.dart';
import 'screens/delivery/delivery_assignments_screen.dart';
import 'screens/delivery/delivery_profile_screen.dart';

// Admin screens
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_users_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrisense',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Farmer routes
        '/farmer_home': (context) => const FarmerHomeScreen(),
        '/crop_recommendation': (context) => const CropRecommendationScreen(),
        '/yield_prediction': (context) => const YieldPredictionScreen(),
        '/profit_analysis': (context) => const ProfitAnalysisScreen(),
        '/my_products': (context) => const MyProductsScreen(),
        '/add_product': (context) => const AddProductScreen(),
        '/farmer_orders': (context) => const FarmerOrdersScreen(),
        '/farmer_profile': (context) => const FarmerProfileScreen(),
        // Buyer routes
        '/buyer_home': (context) => const BuyerHomeScreen(),
        '/browse_products': (context) => const BrowseProductsScreen(),
        '/cart': (context) => const CartScreen(),
        '/buyer_orders': (context) => const BuyerOrdersScreen(),
        '/buyer_profile': (context) => const BuyerProfileScreen(),
        // Delivery routes
        '/delivery_home': (context) => const DeliveryHomeScreen(),
        '/delivery_assignments': (context) => const DeliveryAssignmentsScreen(),
        '/delivery_profile': (context) => const DeliveryProfileScreen(),
        // Admin routes
        '/admin_home': (context) => const AdminHomeScreen(),
        '/admin_users': (context) => const AdminUsersScreen(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.initAuth();
      if (!mounted) return;
      if (auth.isAuthenticated) {
        if (auth.user?.role == 'farmer') {
          Navigator.pushReplacementNamed(context, '/farmer_home');
        } else if (auth.user?.role == 'buyer') {
          Navigator.pushReplacementNamed(context, '/buyer_home');
        } else if (auth.user?.role == 'delivery') {
          Navigator.pushReplacementNamed(context, '/delivery_home');
        } else if (auth.user?.role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          auth.logout();
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
