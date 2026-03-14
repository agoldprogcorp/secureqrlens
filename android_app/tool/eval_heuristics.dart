import 'dart:io';
import 'dart:math';

void main() {
  final base = _projectRoot();
  final whitelist = _loadLines('$base/data/whitelist_brands.txt');
  final rows = _loadCsv('$base/data/test_urls.csv');

  final results = <Map<String, String>>[];
  for (final row in rows) {
    final predicted = _analyze(row['url']!, whitelist);
    results.add({...row, 'predicted': predicted});
  }

  _printMetrics(results);
}

String _analyze(String url, List<String> whitelist) {
  final domain = _extractDomain(url);
  final clean = domain.replaceAll('www.', '');

  for (final ext in ['.apk', '.exe', '.scr', '.bat', '.vbs', '.cmd']) {
    if (url.toLowerCase().contains(ext)) return 'danger';
  }

  if (url.contains('xn--')) {
    final decoded = _decodePunycode(domain);
    if (decoded != null) {
      final hasCyr = RegExp(r'[а-яА-ЯёЁ]').hasMatch(decoded);
      if (hasCyr) return 'danger';
    }
  }

  if (RegExp(r'[а-яА-ЯёЁ]').hasMatch(domain)) {
    if (RegExp(r'[a-zA-Z]').hasMatch(domain)) return 'danger';
    return 'suspicious';
  }

  for (final s in ['tg://', 'sber://', 'bank://', 'ton://', 'whatsapp://',
      'tinkoff://', 'alfa://', 'vtb://', 'sberpay://']) {
    if (url.toLowerCase().startsWith(s)) return 'suspicious';
  }

  for (final brand in whitelist) {
    if (clean == brand || clean.endsWith('.$brand')) return 'safe';
  }

  if (RegExp(r'[?&](token|session_id|session|access_token|auth_code|code|sid)=',
      caseSensitive: false).hasMatch(url)) return 'suspicious';

  if ('.'.allMatches(clean).length >= 4) return 'suspicious';

  int minDist = 999;
  final parts = clean.split('.');
  final base2 = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : clean;
  for (final brand in whitelist) {
    final bp = brand.split('.');
    final bb = bp.length > 1 ? bp.sublist(0, bp.length - 1).join('.') : brand;
    final d = _levenshtein(base2, bb);
    if (d < minDist) minDist = d;
  }
  if (minDist > 0 && minDist <= 2) return 'danger';

  final name = parts.isNotEmpty ? parts[0] : clean;
  if (name.length >= 5 && _entropy(name) > 3.2) return 'suspicious';

  return 'unknown';
}

String _extractDomain(String url) {
  try {
    for (final s in ['tg://', 'sber://', 'bank://', 'ton://', 'whatsapp://',
        'tinkoff://', 'alfa://', 'vtb://', 'sberpay://']) {
      if (url.toLowerCase().startsWith(s)) {
        return url.split('://')[1].split('/')[0].split('?')[0].toLowerCase();
      }
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) return uri.host.toLowerCase();
  } catch (_) {}
  return url.split('/')[0].toLowerCase();
}

String? _decodePunycode(String domain) {
  try {
    return Uri(host: domain).host;
  } catch (_) {
    return null;
  }
}

double _entropy(String s) {
  if (s.isEmpty) return 0;
  final freq = <String, int>{};
  for (final c in s.split('')) {
    freq[c] = (freq[c] ?? 0) + 1;
  }
  final n = s.length;
  return freq.values.fold(0.0, (e, c) {
    final p = c / n;
    return e - p * log(p) / ln2;
  });
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (int i = 0; i < a.length; i++) {
    final curr = [i + 1, ...List<int>.filled(b.length, 0)];
    for (int j = 0; j < b.length; j++) {
      curr[j + 1] = [curr[j] + 1, prev[j + 1] + 1,
          prev[j] + (a[i] == b[j] ? 0 : 1)].reduce(min);
    }
    prev = curr;
  }
  return prev[b.length];
}

List<String> _loadLines(String path) {
  try {
    return File(path)
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
  } catch (_) {
    return [];
  }
}

List<Map<String, String>> _loadCsv(String path) {
  final lines = _loadLines(path);
  if (lines.isEmpty) return [];
  final headers = lines[0].split(',');
  return lines.skip(1).map((line) {
    final cols = line.split(',');
    return Map.fromIterables(headers, cols.map((c) => c.trim()));
  }).toList();
}

void _printMetrics(List<Map<String, String>> results) {
  final total = results.length;
  final correct = results.where((r) => r['predicted'] == r['expected']).length;
  final classes = results.map((r) => r['expected']!).toSet()..remove('unknown');

  int tp = 0, fp = 0, fn = 0;
  for (final r in results) {
    final e = r['expected']!, p = r['predicted']!;
    if (e != 'safe' && p != 'safe') tp++;
    else if (e == 'safe' && p != 'safe') fp++;
    else if (e != 'safe' && p == 'safe') fn++;
  }
  final precision = (tp + fp) > 0 ? tp / (tp + fp) : 0.0;
  final recall = (tp + fn) > 0 ? tp / (tp + fn) : 0.0;
  final f1 = (precision + recall) > 0 ? 2 * precision * recall / (precision + recall) : 0.0;

  print('Total:     $total');
  print('Correct:   $correct');
  print('Accuracy:  ${(correct / total * 100).toStringAsFixed(1)}%');
  print('Precision: ${(precision * 100).toStringAsFixed(1)}%');
  print('Recall:    ${(recall * 100).toStringAsFixed(1)}%');
  print('F1-score:  ${(f1 * 100).toStringAsFixed(1)}%');

  print('\nPer-class:');
  for (final cls in classes.toList()..sort()) {
    final subset = results.where((r) => r['expected'] == cls).toList();
    final hits = subset.where((r) => r['predicted'] == cls).length;
    print('  ${cls.padRight(12)}: $hits/${subset.length} '
        '(${(hits / subset.length * 100).toStringAsFixed(1)}%)');
  }

  final errors = results.where((r) => r['predicted'] != r['expected']).toList();
  if (errors.isNotEmpty) {
    print('\nErrors (${errors.length}):');
    for (final e in errors) {
      final cat = (e['category'] ?? '').isNotEmpty ? ' [${e['category']}]' : '';
      print('  ${e['expected']!.padRight(10)} -> ${e['predicted']!.padRight(10)}$cat  ${e['url']}');
    }
  }
}

String _projectRoot() {
  var dir = Directory.current.path.replaceAll('\\', '/');
  if (dir.contains('/android_app/tool')) {
    return dir.replaceAll(RegExp(r'/android_app/tool.*$'), '');
  }
  if (dir.endsWith('/android_app')) {
    return dir.replaceAll(RegExp(r'/android_app$'), '');
  }
  if (dir.endsWith('/tool')) {
    return dir.replaceAll(RegExp(r'/tool$'), '').replaceAll(RegExp(r'/android_app$'), '');
  }
  return dir;
}
