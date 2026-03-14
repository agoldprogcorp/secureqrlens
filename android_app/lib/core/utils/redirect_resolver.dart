import 'package:http/http.dart' as http;

class RedirectResolver {
  static const List<String> shorteners = [
    'clck.ru', 'vk.cc', 'vk.me', 'ok.me', 'ya.ru', 'go.mail.ru',
    'bit.ly', 'bitly.com', 'goo.gl', 'g.co', 't.co', 'ow.ly',
    'tinyurl.com', 'is.gd', 'v.gd', 'rebrand.ly', 'short.io', 'cutt.ly',
    'aka.ms', 'amzn.to', 'youtu.be', 'fb.me', 'instagr.am', 'lnkd.in', 'redd.it',
  ];

  static bool isShortenedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();
      return shorteners.any((s) => domain == s);
    } catch (e) {
      return false;
    }
  }

  static Future<RedirectResult> resolveRedirects(
    String url, {
    int maxDepth = 5,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final chain = <String>[url];
    String currentUrl = url;
    final visited = <String>{};
    String? error;

    for (int depth = 0; depth < maxDepth; depth++) {
      if (visited.contains(currentUrl)) {
        error = 'Циклический редирект';
        break;
      }
      visited.add(currentUrl);

      try {
        final uri = Uri.parse(currentUrl);
        if (!uri.scheme.startsWith('http')) break;

        final request = http.Request('HEAD', uri);
        request.headers['User-Agent'] = 'SecureQRLens/1.0';
        request.followRedirects = false;

        final streamedResponse = await request.send().timeout(timeout);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers['location'];
          if (location == null || location.isEmpty) break;

          String nextUrl;
          if (location.startsWith('http://') || location.startsWith('https://')) {
            nextUrl = location;
          } else if (location.startsWith('/')) {
            nextUrl = '${uri.scheme}://${uri.host}$location';
          } else {
            nextUrl = '${uri.scheme}://${uri.host}/$location';
          }

          chain.add(nextUrl);
          currentUrl = nextUrl;
        } else {
          break;
        }
      } catch (e) {
        if (e.toString().contains('TimeoutException')) {
          error = 'Таймаут запроса';
        } else if (e.toString().contains('SocketException')) {
          error = 'Нет подключения к интернету';
        } else {
          error = 'Ошибка сети';
        }
        break;
      }
    }

    return RedirectResult(chain: chain, finalUrl: chain.last, error: error);
  }
}

class RedirectResult {
  final List<String> chain;
  final String finalUrl;
  final String? error;

  RedirectResult({required this.chain, required this.finalUrl, this.error});

  bool get hasRedirects => chain.length > 1;
  bool get hasError => error != null;
}
