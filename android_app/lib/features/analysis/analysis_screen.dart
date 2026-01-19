import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/scan_result.dart';
import '../../models/verdict.dart';
import '../../widgets/verdict_badge.dart';
import '../../widgets/verdict_card.dart';
import '../../widgets/url_display.dart';

class AnalysisScreen extends StatelessWidget {
  final ScanResult result;

  const AnalysisScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат анализа'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            VerdictBadge(verdict: result.verdict),
            const SizedBox(height: 24),
            UrlDisplay(url: result.url),
            const SizedBox(height: 16),
            VerdictCard(
              verdict: result.verdict,
              details: result.details,
              reasons: result.reasons,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Время анализа:'),
                    Text(
                      '${result.analysisTimeMs} мс',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (result.verdict == Verdict.suspicious)
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(result.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Всё равно перейти'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканировать ещё'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
