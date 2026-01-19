import '../../core/utils/entropy.dart';
import '../../models/verdict.dart';

class ScoreResult {
  final Verdict verdict;
  final int score;
  final String details;
  final List<String> reasons;

  ScoreResult({
    required this.verdict,
    required this.score,
    required this.details,
    required this.reasons,
  });
}

class ScoreAnalyzer {
  String _extractDomain(String url) {
    try {
      Uri? uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        return uri.host.toLowerCase();
      }
      return url.split('/')[0].toLowerCase();
    } catch (e) {
      return url.split('/')[0].toLowerCase();
    }
  }

  bool _isIpAddress(String domain) {
    RegExp ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    return ipPattern.hasMatch(domain);
  }

  ScoreResult analyze(String url) {
    int score = 0;
    List<String> reasons = [];

    // 1. Длина URL > 100
    if (url.length > 100) {
      score += 1;
      reasons.add('Длинный URL (${url.length} символов)');
    }

    // 2. Количество точек в домене > 3
    String domain = _extractDomain(url);
    int dotsCount = '.'.allMatches(domain).length;
    if (dotsCount > 3) {
      score += 1;
      reasons.add('Много поддоменов ($dotsCount точек)');
    }

    // 3. IP вместо домена
    if (_isIpAddress(domain)) {
      score += 2;
      reasons.add('IP-адрес вместо домена');
    }

    // 4. Спецсимволы (@, !)
    if (url.contains('@') || url.contains('!')) {
      score += 1;
      reasons.add('Подозрительные символы в URL');
    }

    // 5. Энтропия > 4.0
    List<String> parts = domain.split('.');
    String domainName = parts.isNotEmpty ? parts[0] : domain;
    
    // Игнорируем короткие домены (меньше 5 символов)
    if (domainName.length >= 5) {
      double entropy = calculateEntropy(domainName);
      if (entropy > 4.0) {
        score += 1;
        reasons.add('Повышенная энтропия: ${entropy.toStringAsFixed(2)}');
      }
    }

    // Определение вердикта по score
    Verdict verdict;
    if (score <= 1) {
      verdict = Verdict.safe;
    } else if (score <= 3) {
      verdict = Verdict.suspicious;
    } else {
      verdict = Verdict.danger;
    }

    return ScoreResult(
      verdict: verdict,
      score: score,
      details: 'ML Score: $score баллов',
      reasons: reasons,
    );
  }
}
