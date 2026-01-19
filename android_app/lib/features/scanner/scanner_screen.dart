import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../analysis/analysis_screen.dart';
import 'scanner_controller.dart';
import 'scanner_overlay.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    final scannerController = context.read<ScannerController>();
    final result = await scannerController.analyzeUrl(code);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(result: result),
        ),
      );
      
      // Сбрасываем флаг после возврата, чтобы можно было сканировать снова
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure QR Lens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          const ScannerOverlay(),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Наведите камеру на QR-код',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
