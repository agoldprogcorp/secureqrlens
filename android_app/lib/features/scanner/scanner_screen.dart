import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/scan_result.dart';
import '../../models/verdict.dart';
import '../analysis/analysis_screen.dart';
import 'scanner_controller.dart';
import 'scanner_overlay.dart';

const bool kProMode = bool.fromEnvironment('PRO_MODE');

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;
  ScanResult? _lastResult;
  List<Offset> _qrCorners = const [];
  Size _imageSize = Size.zero;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _lastResult != null) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _qrCorners = barcodes.first.corners;
      _imageSize = capture.size;
    });

    final scannerController = context.read<ScannerController>();
    final result = await scannerController.analyzeUrl(code);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastResult = result;
      });
    }
  }

  void _dismiss() => setState(() {
        _lastResult = null;
        _qrCorners = const [];
        _imageSize = Size.zero;
      });

  Future<void> _openUrl(String url) async {
    final actualUrl = url.contains(' → ') ? url.split(' → ').last : url;
    final uri = Uri.tryParse(actualUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _lastResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(kProMode ? 'Secure QR Lens PRO' : 'Secure QR Lens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: ScannerOverlay(
              verdict: result?.verdict,
              qrCorners: _qrCorners,
              imageSize: _imageSize,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: result != null
                ? _ResultPanel(
                    result: result,
                    onDismiss: _dismiss,
                    onOpenUrl: _openUrl,
                    onDetails: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalysisScreen(result: result),
                        ),
                      );
                    },
                  )
                : _HintBar(isProcessing: _isProcessing),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onDismiss;
  final Future<void> Function(String url) onOpenUrl;
  final VoidCallback onDetails;

  const _ResultPanel({
    required this.result,
    required this.onDismiss,
    required this.onOpenUrl,
    required this.onDetails,
  });

  Color get _bgColor {
    switch (result.verdict) {
      case Verdict.safe:
        return const Color(0xFF2E7D32);
      case Verdict.danger:
        return const Color(0xFFC62828);
      case Verdict.suspicious:
        return const Color(0xFFF57F17);
      default:
        return const Color(0xFF37474F);
    }
  }

  IconData get _icon {
    switch (result.verdict) {
      case Verdict.safe:
        return Icons.check_circle;
      case Verdict.danger:
        return Icons.dangerous;
      case Verdict.suspicious:
        return Icons.warning_amber;
      default:
        return Icons.info_outline;
    }
  }

  String get _verdictLabel {
    switch (result.verdict) {
      case Verdict.safe:
        return 'Безопасно';
      case Verdict.danger:
        return 'Опасно';
      case Verdict.suspicious:
        return 'Подозрительно';
      default:
        return 'Не URL';
    }
  }

  bool get _canOpen {
    if (result.verdict != Verdict.safe) return false;
    final url =
        result.url.contains(' → ') ? result.url.split(' → ').last : result.url;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                _verdictLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Подробнее',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (_canOpen) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onOpenUrl(result.url),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _bgColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Перейти'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  final bool isProcessing;

  const _HintBar({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              isProcessing ? 'Анализируем...' : 'Наведите камеру на QR-код',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
