import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/farmer_service.dart';

class YieldPredictionScreen extends StatefulWidget {
  const YieldPredictionScreen({super.key});

  @override
  State<YieldPredictionScreen> createState() => _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends State<YieldPredictionScreen> {
  final _nController = TextEditingController(text: '90');
  final _pController = TextEditingController(text: '42');
  final _kController = TextEditingController(text: '43');
  final _phController = TextEditingController(text: '6.5');
  
  String? _selectedCrop;
  List<String> _crops = [];
  bool _isLoadingCrops = true;
  bool _isPredicting = false;
  double? _predictedYield;

  final Color primaryGreen = const Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final crops = await FarmerService.getYieldPredictionCrops();
    if (mounted) {
      setState(() {
        _crops = crops;
        if (_crops.isNotEmpty) _selectedCrop = _crops.first;
        _isLoadingCrops = false;
      });
    }
  }

  Future<void> _getPrediction() async {
    if (_selectedCrop == null) return;
    setState(() => _isPredicting = true);
    final res = await FarmerService.getYieldPrediction(
      crop: _selectedCrop!,
      n: double.tryParse(_nController.text) ?? 0,
      p: double.tryParse(_pController.text) ?? 0,
      k: double.tryParse(_kController.text) ?? 0,
      ph: double.tryParse(_phController.text) ?? 7.0,
    );
    setState(() => _isPredicting = false);

    if (res['success']) {
      setState(() {
        _predictedYield = res['data']['predicted_yield'];
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
          // Background ambient glows
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.15)))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Yield Prediction', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 8),
                  const Text('AI-driven estimates based on your soil health and crop choice.', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                            _buildLabel('Select Targeted Crop'),
                            _isLoadingCrops
                              ? const CircularProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  value: _selectedCrop,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(),
                                  items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                                  onChanged: (val) => setState(() => _selectedCrop = val),
                                ),
                            const SizedBox(height: 20),
                            
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Nitrogen (N)'), TextField(controller: _nController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                                const SizedBox(width: 20),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Phosphorus (P)'), TextField(controller: _pController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Potassium (K)'), TextField(controller: _kController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                                const SizedBox(width: 20),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Soil pH Level'), TextField(controller: _phController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                              ],
                            ),
                            const SizedBox(height: 30),
                            
                            ElevatedButton(
                              onPressed: _isPredicting ? null : _getPrediction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: const Color(0xFF064E3B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isPredicting 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF064E3B))) 
                                : const Text('Analyze & Predict Yield', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_predictedYield != null) ...[
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        border: Border.all(color: primaryGreen),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text('Estimated Yield for ${_selectedCrop?.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: _predictedYield!.toStringAsFixed(2), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryGreen)),
                                const TextSpan(text: ' tonnes/ha', style: TextStyle(fontSize: 20, color: Colors.white70)),
                              ]
                            )
                          ),
                          const SizedBox(height: 10),
                          const Text('*Based on current soil nutrient parameters', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    )
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
