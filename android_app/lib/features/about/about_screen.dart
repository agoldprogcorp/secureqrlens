import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secure QR Lens',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Версия 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'О проекте',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Secure QR Lens — система превентивной защиты от Quishing-атак (фишинг через QR-коды).',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Что проверяется',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.verified_user,
              'Whitelist СБП',
              'Проверка доверенных доменов СБП',
            ),
            _buildFeatureItem(
              Icons.bug_report,
              'Malware расширения',
              'Детекция опасных файлов (.apk, .exe)',
            ),
            _buildFeatureItem(
              Icons.link,
              'Deep Link схемы',
              'Анализ подозрительных схем (tg://, sber://)',
            ),
            _buildFeatureItem(
              Icons.language,
              'Punycode атаки',
              'Обнаружение IDN Homograph',
            ),
            _buildFeatureItem(
              Icons.compare_arrows,
              'Typosquatting',
              'Проверка похожих доменов (Levenshtein)',
            ),
            _buildFeatureItem(
              Icons.analytics,
              'Энтропия домена',
              'Детекция DGA-доменов',
            ),
            const SizedBox(height: 24),
            const Text(
              'Вердикты',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildVerdictItem(
              AppTheme.safe,
              'SAFE',
              'Безопасный URL',
            ),
            _buildVerdictItem(
              AppTheme.suspicious,
              'SUSPICIOUS',
              'Подозрительный URL',
            ),
            _buildVerdictItem(
              AppTheme.danger,
              'DANGER',
              'Опасный URL',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.code),
                title: const Text('GitHub'),
                subtitle: const Text('github.com/agoldprogcorp/secureqrlens'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse('https://github.com/agoldprogcorp/secureqrlens');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'MIT License\n© 2025 Secure QR Lens',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictItem(Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.circle,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
