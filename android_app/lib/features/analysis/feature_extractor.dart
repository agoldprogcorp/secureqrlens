import '../../core/constants.dart';
import '../../core/utils/entropy.dart';
import '../../core/utils/levenshtein.dart';

class UrlFeatureExtractor {
  static const List<String> featureNames = [
    'url_length', 'dots_count', 'special_chars', 'has_ip', 'entropy', 'levenshtein_min',
  ];

  static const List<String> _kSpecialChars = ['-', '_', '@', '&', '=', '?', '%'];

  static final RegExp _ipPattern =
      RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');

  static List<double> extract(String url) {
    final domain = _extractDomain(url);
    final parts = domain.split('.');
    final domainName = parts.length > 1 ? parts[0] : domain;
    final cleanDomain = domain.replaceAll('www.', '');

    return [
      url.length / 200.0,
      (domain.split('.').length - 1).toDouble(),
      _countSpecialChars(url),
      _ipPattern.hasMatch(domain) ? 1.0 : 0.0,
      calculateEntropy(domainName),
      _levenshteinMin(cleanDomain),
    ];
  }

  static double _countSpecialChars(String url) {
    int count = 0;
    for (final c in _kSpecialChars) {
      count += c.allMatches(url).length;
    }
    return count.toDouble();
  }

  static double _levenshteinMin(String cleanDomain) {
    final brands = AppConstants.brandWhitelist;
    if (brands.isEmpty) return 10.0;

    int minDist = 999;
    for (final brand in brands) {
      final dist = levenshtein(cleanDomain, brand);
      if (dist < minDist) minDist = dist;
      if (minDist == 0) break;
    }
    return (minDist == 999 ? 10 : minDist).toDouble();
  }

  static String _extractDomain(String url) {
    try {
      final lower = url.toLowerCase();
      for (final scheme in AppConstants.deepLinkSchemes) {
        if (lower.startsWith(scheme)) {
          return url.split('://')[1].split('/')[0].split('?')[0].toLowerCase();
        }
      }
      final uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        final host = uri.host.toLowerCase();
        return host.contains(':') ? host.split(':')[0] : host;
      }
      return url.split('/')[0].toLowerCase();
    } catch (_) {
      return url.split('/')[0].toLowerCase();
    }
  }
}
