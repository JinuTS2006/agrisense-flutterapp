import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/farmer_service.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _nController = TextEditingController(text: '90');
  final _pController = TextEditingController(text: '42');
  final _kController = TextEditingController(text: '43');
  final _phController = TextEditingController(text: '6.5');
  
  bool _isLoading = false;
  List<dynamic>? _results;

  final Color primaryGreen = const Color(0xFF4ADE80);

  Future<void> _getRecommendation() async {
    setState(() => _isLoading = true);
    final res = await FarmerService.getCropRecommendation(
      n: double.tryParse(_nController.text) ?? 0,
      p: double.tryParse(_pController.text) ?? 0,
      k: double.tryParse(_kController.text) ?? 0,
      ph: double.tryParse(_phController.text) ?? 7.0,
    );
    setState(() => _isLoading = false);

    if (res['success']) {
      setState(() {
        _results = res['data']['recommended_crops'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['error']}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.15)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.1)))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Crop Recommendation', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 8),
                  const Text('AI analyzes soil data along with real-time weather to suggest the best crops.', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Nitrogen (N) Content'), TextField(controller: _nController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                                const SizedBox(width: 20),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Phosphorous (P) Content'), TextField(controller: _pController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Potassium (K) Content'), TextField(controller: _kController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                                const SizedBox(width: 20),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Soil pH Level'), TextField(controller: _phController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                              ],
                            ),
                            const SizedBox(height: 30),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _getRecommendation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: const Color(0xFF064E3B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF064E3B))) 
                                : const Text('Get AI Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_results != null) ...[
                    const SizedBox(height: 40),
                    Text('Top Matches', style: TextStyle(color: primaryGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ..._results!.map((crop) => Card(
                      color: Colors.white.withOpacity(0.05),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('🌱', style: TextStyle(fontSize: 24)),
                        ),
                        title: Text(crop['crop'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        trailing: Text('${crop['probability']}% Match', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )).toList(),
                  ]
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
