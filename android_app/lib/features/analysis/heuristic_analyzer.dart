import '../../core/constants.dart';
import '../../core/utils/entropy.dart';
import '../../core/utils/levenshtein.dart';
import '../../core/utils/punycode.dart';
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
  static final RegExp _cyrillicRegex = RegExp(r'[а-яА-ЯёЁ]');
  static final RegExp _latinRegex = RegExp(r'[a-zA-Z]');

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
    String urlLower = url.toLowerCase();
    String cleanDomain = domain.replaceAll('www.', '');

    for (var ext in AppConstants.malwareExtensions) {
      if (urlLower.contains(ext)) {
        return HeuristicResult(
          verdict: Verdict.danger,
          details: 'Обнаружено опасное расширение: $ext',
          reasons: ['Ссылка ведёт на загрузку файла: $ext'],
        );
      }
    }

    if (url.contains('xn--')) {
      String? decoded = decodePunycode(domain);
      if (decoded != null) {
        bool hasCyrillic = _cyrillicRegex.hasMatch(decoded);
        bool hasLatin = _latinRegex.hasMatch(decoded);
        if (hasCyrillic && hasLatin) {
          return HeuristicResult(
            verdict: Verdict.danger,
            details: 'IDN Homograph Attack: $domain → $decoded',
            reasons: [
              'Кириллица + латиница в одном домене',
              'Домен маскируется под известный сайт',
            ],
          );
        }
        if (hasCyrillic) {
          return HeuristicResult(
            verdict: Verdict.danger,
            details: 'Punycode-подмена: $domain → $decoded',
            reasons: [
              'Домен маскируется под легитимный',
            ],
          );
        }
      }
    }

    if (_cyrillicRegex.hasMatch(domain)) {
      if (_latinRegex.hasMatch(domain)) {
        return HeuristicResult(
          verdict: Verdict.danger,
          details: 'IDN Homograph Attack: смешанные скрипты в домене $domain',
          reasons: [
            'Кириллица + латиница в одном домене',
            'Домен маскируется под известный сайт',
          ],
        );
      }
      return HeuristicResult(
        verdict: Verdict.suspicious,
        details: 'Кириллический домен: $domain',
        reasons: ['Полностью кириллический домен'],
      );
    }

    for (var scheme in AppConstants.deepLinkSchemes) {
      if (urlLower.startsWith(scheme)) {
        return HeuristicResult(
          verdict: Verdict.suspicious,
          details: 'Deep Link: $scheme',
          reasons: [
            'Ссылка минует браузер и открывает приложение напрямую',
            'Невозможно проверить содержимое без контекста приложения',
          ],
        );
      }
    }

    for (var brand in AppConstants.brandWhitelist) {
      if (cleanDomain == brand || cleanDomain.endsWith('.$brand')) {
        return HeuristicResult(
          verdict: Verdict.safe,
          details: 'Домен $domain в whitelist',
          reasons: ['Известный доверенный домен: $brand'],
        );
      }
    }

    final qrlPattern = RegExp(
      r'[?&](token|session_id|session|access_token|auth_code|code|oauth_token|auth|sid)=',
      caseSensitive: false,
    );
    if (qrlPattern.hasMatch(urlLower)) {
      return HeuristicResult(
        verdict: Verdict.suspicious,
        details: 'QRLJacking: параметры авторизации в URL',
        reasons: [
          'Параметры сессии/токена в URL',
          'Возможен перехват сессии',
        ],
      );
    }

    int dotCount = '.'.allMatches(cleanDomain).length;
    if (dotCount >= 4) {
      return HeuristicResult(
        verdict: Verdict.suspicious,
        details: 'Подозрительная вложенность поддоменов: $dotCount уровней',
        reasons: ['Слишком много уровней поддоменов: $dotCount'],
      );
    }

    int minDistance = 999;
    String? closestBrand;
    List<String> domainParts = cleanDomain.split('.');
    String domainBase = domainParts.length > 1
        ? domainParts.sublist(0, domainParts.length - 1).join('.')
        : cleanDomain;

    for (var brand in AppConstants.brandWhitelist) {
      List<String> brandParts = brand.split('.');
      String brandBase = brandParts.length > 1
          ? brandParts.sublist(0, brandParts.length - 1).join('.')
          : brand;
      int dist = levenshtein(domainBase, brandBase);
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
        details: 'Typosquatting: расстояние $minDistance до $closestBrand',
        reasons: [
          'Домен очень похож на известный сайт: $closestBrand',
          'Отличается на $minDistance символ(а)',
        ],
      );
    }

    String domainName = domainParts.isNotEmpty ? domainParts[0] : cleanDomain;
    if (domainName.length >= 5) {
      double entropy = calculateEntropy(domainName);
      if (entropy > AppConstants.entropyThreshold) {
        return HeuristicResult(
          verdict: Verdict.suspicious,
          details: 'Высокая энтропия домена: ${entropy.toStringAsFixed(2)}',
          reasons: [
            'Случайно сгенерированный домен',
            'Энтропия ${entropy.toStringAsFixed(2)} бит/символ (норма: до 3.2)',
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
