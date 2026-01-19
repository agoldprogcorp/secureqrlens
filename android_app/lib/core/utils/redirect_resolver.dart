import 'package:http/http.dart' as http;

class RedirectResolver {
  // Список популярных сокращателей ссылок
  static const List<String> shorteners = [
    // Российские
    'clck.ru',
    'vk.cc',
    'vk.me',
    'ok.me',
    't.me',
    'ya.ru',
    'go.mail.ru',
    
    // Международные
    'bit.ly',
    'bitly.com',
    'goo.gl',
    'g.co',
    't.co',
    'ow.ly',
    'tinyurl.com',
    'is.gd',
    'v.gd',
    'rebrand.ly',
    'short.io',
    'cutt.ly',
    
    // Корпоративные
    'aka.ms',
    'amzn.to',
    'youtu.be',
    'fb.me',
    'instagr.am',
    'lnkd.in',
    'redd.it',
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
      // Проверка на циклический редирект
      if (visited.contains(currentUrl)) {
        error = 'Циклический редирект';
        break;
      }
      visited.add(currentUrl);

      try {
        final uri = Uri.parse(currentUrl);
        
        // Проверяем только http/https
        if (!uri.scheme.startsWith('http')) {
          break;
        }

        // HEAD запрос для получения редиректа (не следуем автоматически)
        final request = http.Request('HEAD', uri);
        request.headers['User-Agent'] = 'SecureQRLens/1.0';
        request.followRedirects = false;
        
        final streamedResponse = await request.send().timeout(timeout);
        final response = await http.Response.fromStream(streamedResponse);

        // Проверяем статус редиректа
        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers['location'];
          if (location == null || location.isEmpty) {
            break;
          }

          // Обработка относительных URL
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
          // Не редирект - завершаем
          break;
        }
      } catch (e) {
        if (e.toString().contains('TimeoutException')) {
          error = 'Таймаут запроса';
        } else if (e.toString().contains('SocketException')) {
          error = 'Нет подключения к интернету';
        } else {
          error = 'Ошибка сети: ${e.toString()}';
        }
        break;
      }
    }

    return RedirectResult(
      chain: chain,
      finalUrl: chain.last,
      error: error,
    );
  }
}

class RedirectResult {
  final List<String> chain;
  final String finalUrl;
  final String? error;

  RedirectResult({
    required this.chain,
    required this.finalUrl,
    this.error,
  });

  bool get hasRedirects => chain.length > 1;
  bool get hasError => error != null;
}
