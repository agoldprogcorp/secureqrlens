import '../../core/constants.dart';
import '../../core/utils/entropy.dart';
import '../../core/utils/levenshtein.dart';
import '../../core/utils/punycode.dart';
import '../../core/utils/redirect_resolver.dart';
import '../../models/verdict.dart';

class HeuristicResult {
  final Verdict verdict;
  final String details;
  final List<String> reasons;

  HeuristicResult({
    required this.verdict,
    required this.details,
    this.reasons = const [],
  });
}

class HeuristicAnalyzer {
  String _extractDomain(String url) {
    try {
      String urlLower = url.toLowerCase();

      for (var scheme in AppConstants.deepLinkSchemes) {
        if (urlLower.startsWith(scheme)) {
          return url
              .split('://')[1]
              .split('/')[0]
              .split('?')[0]
              .toLowerCase();
        }
      }

      Uri? uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        return uri.host.toLowerCase();
      }

      return url.split('/')[0].toLowerCase();
    } catch (e) {
      return url.split('/')[0].toLowerCase();
    }
  }

  HeuristicResult analyze(String url) {
    String domain = _extractDomain(url);

    // 1. Whitelist СБП
    for (var sbpDomain in AppConstants.sbpWhitelist) {
      if (domain == sbpDomain || domain.endsWith('.$sbpDomain')) {
        return HeuristicResult(
          verdict: Verdict.safe,
          details: 'Домен $domain в whitelist СБП',
          reasons: ['СБП whitelist'],
        );
      }
    }

    // 1.5. Проверка основного whitelist (ПЕРЕД typosquatting!)
    String cleanDomain = domain.replaceAll('www.', '');
    for (var brand in AppConstants.brandWhitelist) {
      if (cleanDomain == brand || domain == brand) {
        return HeuristicResult(
          verdict: Verdict.safe,
          details: 'Домен $domain в whitelist',
          reasons: ['Whitelist'],
        );
      }
    }

    // 2. Опасные расширения
    String urlLower = url.toLowerCase();
    for (var ext in AppConstants.malwareExtensions) {
      if (urlLower.endsWith(ext)) {
        return HeuristicResult(
          verdict: Verdict.danger,
          details: 'Обнаружено опасное расширение: $ext',
          reasons: ['Malware расширение: $ext'],
        );
      }
    }

    // 3. Deep Link схемы
    for (var scheme in AppConstants.deepLinkSchemes) {
      if (urlLower.startsWith(scheme)) {
        return HeuristicResult(
          verdict: Verdict.suspicious,
          details: 'Обнаружена Deep Link схема: $scheme',
          reasons: ['Deep Link: $scheme'],
        );
      }
    }

    // 4. Punycode
    if (url.contains('xn--')) {
      String? decoded = decodePunycode(domain);
      if (decoded != null) {
        return HeuristicResult(
          verdict: Verdict.danger,
          details: 'IDN Homograph Attack: $domain',
          reasons: ['Punycode домен'],
        );
      }
    }

    // 4.5. Кириллица в домене (без punycode)
    if (RegExp(r'[а-яА-ЯёЁ]').hasMatch(domain)) {
      return HeuristicResult(
        verdict: Verdict.danger,
        details: 'Обнаружена кириллица в домене: $domain',
        reasons: ['Кириллица в домене'],
      );
    }

    // 5. Typosquatting (ПОСЛЕ проверки whitelist!)
    int minDistance = 999;
    String? closestBrand;

    for (var brand in AppConstants.brandWhitelist) {
      // Пропускаем точные совпадения (уже проверены выше)
      if (cleanDomain == brand) {
        continue;
      }
      int dist = levenshtein(cleanDomain, brand);
      if (dist < minDistance) {
        minDistance = dist;
        closestBrand = brand;
      }
    }

    if (minDistance > 0 &&
        minDistance <= AppConstants.levenshteinThreshold &&
        closestBrand != null) {
      return HeuristicResult(
        verdict: Verdict.danger,
        details:
            'Typosquatting: расстояние Левенштейна = $minDistance до $closestBrand',
        reasons: ['Typosquatting: похож на $closestBrand (дистанция $minDistance)'],
      );
    }

    // 6. Высокая энтропия
    List<String> parts = domain.split('.');
    String domainName = parts.isNotEmpty ? parts[0] : domain;
    
    // Игнорируем короткие домены (меньше 5 символов)
    if (domainName.length >= 5) {
      double entropy = calculateEntropy(domainName);

      if (entropy > AppConstants.entropyThreshold) {
        return HeuristicResult(
          verdict: Verdict.suspicious,
          details:
              'Высокая энтропия домена: ${entropy.toStringAsFixed(2)} (порог ${AppConstants.entropyThreshold})',
          reasons: [
            'Высокая энтропия: ${entropy.toStringAsFixed(2)}'
          ],
        );
      }
    }

    return HeuristicResult(
      verdict: Verdict.unknown,
      details: 'Эвристики не определили вердикт',
      reasons: [],
    );
  }
}
