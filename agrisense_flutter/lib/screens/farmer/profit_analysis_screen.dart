import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/farmer_service.dart';

class ProfitAnalysisScreen extends StatefulWidget {
  const ProfitAnalysisScreen({super.key});

  @override
  State<ProfitAnalysisScreen> createState() => _ProfitAnalysisScreenState();
}

class _ProfitAnalysisScreenState extends State<ProfitAnalysisScreen> {
  String? _selectedState;
  String? _selectedCrop;
  final _areaController = TextEditingController(text: '1.0');
  final _yieldController = TextEditingController(text: '1.0');
  
  List<String> _states = [];
  List<String> _crops = [];
  bool _isLoadingOptions = true;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _results;

  final Color primaryGreen = const Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final opts = await FarmerService.getProfitAnalysisOptions();
    if (mounted) {
      setState(() {
        _states = opts['states']!;
        _crops = opts['crops']!;
        if (_states.isNotEmpty) _selectedState = _states.first;
        if (_crops.isNotEmpty) _selectedCrop = _crops.first;
        _isLoadingOptions = false;
      });
    }
  }

  Future<void> _getProfit() async {
    if (_selectedState == null || _selectedCrop == null) return;
    setState(() => _isAnalyzing = true);
    final res = await FarmerService.calculateProfit(
      state: _selectedState!,
      crop: _selectedCrop!,
      area: double.tryParse(_areaController.text) ?? 1.0,
      yieldAmount: double.tryParse(_yieldController.text) ?? 1.0,
    );
    setState(() => _isAnalyzing = false);

    if (res['success']) {
      setState(() {
        _results = res['data'];
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
          Positioned(top: -100, left: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.15)))),
          Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profit Analysis', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 8),
                  const Text('Enter your harvest data to calculate projected market earnings.', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('State'),
                                      _isLoadingOptions
                                        ? const CircularProgressIndicator()
                                        : DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: _selectedState,
                                            dropdownColor: const Color(0xFF1E293B),
                                            style: const TextStyle(color: Colors.white),
                                            decoration: _inputDecoration(),
                                            items: _states.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                            onChanged: (val) => setState(() => _selectedState = val),
                                          ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Crop Name'),
                                      _isLoadingOptions
                                        ? const CircularProgressIndicator()
                                        : DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: _selectedCrop,
                                            dropdownColor: const Color(0xFF1E293B),
                                            style: const TextStyle(color: Colors.white),
                                            decoration: _inputDecoration(),
                                            items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), overflow: TextOverflow.ellipsis))).toList(),
                                            onChanged: (val) => setState(() => _selectedCrop = val),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Land Area (Hectares)'), TextField(controller: _areaController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                                const SizedBox(width: 20),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Expected Yield (Tonnes/Ha)'), TextField(controller: _yieldController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration())])),
                              ],
                            ),
                            const SizedBox(height: 30),
                            
                            ElevatedButton(
                              onPressed: _isAnalyzing ? null : _getProfit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: const Color(0xFF064E3B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isAnalyzing 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF064E3B))) 
                                : const Text('Generate Financial Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_results != null) ...[
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: primaryGreen),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Calculation Results', style: TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildMetricItem('Total Harvest', '${_results!['total_yield'].toStringAsFixed(2)} Tonnes')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMetricItem('Est. Market Price', '₹${_results!['price'].toStringAsFixed(0)}/T')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildMetricItem('Gross Revenue', '₹${_results!['revenue'].toStringAsFixed(0)}')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMetricItem('Total Costs', '₹${_results!['cost'].toStringAsFixed(0)}')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: (_results!['profit'] > 0) ? primaryGreen.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              border: Border.all(color: (_results!['profit'] > 0) ? primaryGreen : Colors.redAccent),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text((_results!['profit'] > 0) ? 'Projected Net Profit' : 'Projected Net Loss', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_results!['profit'].toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: (_results!['profit'] > 0) ? primaryGreen : Colors.redAccent),
                                )
                              ],
                            ),
                          )
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

  Widget _buildMetricItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
