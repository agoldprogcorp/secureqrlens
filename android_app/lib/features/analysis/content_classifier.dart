import '../../core/constants.dart';

enum ContentType { url, deepLink, shortUrl, wifi, nonUrl }

class ContentClassification {
  final ContentType type;
  final String raw;
  final String typeLabel;
  final String? deepLinkScheme;

  const ContentClassification({
    required this.type,
    required this.raw,
    required this.typeLabel,
    this.deepLinkScheme,
  });
}

class ContentClassifier {
  static ContentClassification classify(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    for (final scheme in AppConstants.deepLinkSchemes) {
      if (lower.startsWith(scheme)) {
        return ContentClassification(
          type: ContentType.deepLink,
          raw: trimmed,
          typeLabel: 'Deep Link ($scheme)',
          deepLinkScheme: scheme,
        );
      }
    }

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        final host = uri.host.toLowerCase();
        for (final shortener in _shorteners) {
          if (host == shortener) {
            return ContentClassification(
              type: ContentType.shortUrl,
              raw: trimmed,
              typeLabel: 'Сокращённая ссылка ($host)',
            );
          }
        }
        return ContentClassification(
          type: ContentType.url,
          raw: trimmed,
          typeLabel: 'URL',
        );
      } catch (_) {}
    }

    if (lower.startsWith('wifi:')) {
      return ContentClassification(
        type: ContentType.wifi,
        raw: trimmed,
        typeLabel: 'Wi-Fi конфигурация',
      );
    }

    for (final prefix in _nonUrlPrefixes) {
      if (lower.startsWith(prefix)) {
        return ContentClassification(
          type: ContentType.nonUrl,
          raw: trimmed,
          typeLabel: _nonUrlLabel(prefix),
        );
      }
    }

    return ContentClassification(
      type: ContentType.nonUrl,
      raw: trimmed,
      typeLabel: 'Текст',
    );
  }

  static String _nonUrlLabel(String prefix) {
    switch (prefix) {
      case 'wifi:':
        return 'Wi-Fi конфигурация';
      case 'tel:':
        return 'Телефонный номер';
      case 'mailto:':
        return 'E-mail адрес';
      case 'smsto:':
      case 'sms:':
        return 'SMS сообщение';
      case 'begin:vcard':
        return 'Контактная карточка (vCard)';
      case 'geo:':
        return 'Геолокация';
      default:
        return 'Специальный контент';
    }
  }

  static const List<String> _shorteners = [
    'clck.ru', 'vk.cc', 'vk.me', 'ok.me', 'ya.ru', 'go.mail.ru',
    'bit.ly', 'bitly.com', 'goo.gl', 'g.co', 't.co', 'ow.ly',
    'tinyurl.com', 'is.gd', 'v.gd', 'rebrand.ly', 'short.io', 'cutt.ly',
    'aka.ms', 'amzn.to', 'youtu.be', 'fb.me', 'instagr.am', 'lnkd.in', 'redd.it',
  ];

  static Map<String, String> parseWifi(String raw) {
    final result = <String, String>{};
    String body = raw;
    if (body.toLowerCase().startsWith('wifi:')) {
      body = body.substring(5);
    }
    if (body.endsWith(';;')) {
      body = body.substring(0, body.length - 2);
    } else if (body.endsWith(';')) {
      body = body.substring(0, body.length - 1);
    }
    for (final part in body.split(';')) {
      final idx = part.indexOf(':');
      if (idx > 0) {
        result[part.substring(0, idx).toUpperCase()] = part.substring(idx + 1);
      }
    }
    return result;
  }

  static const List<String> _nonUrlPrefixes = [
    'tel:', 'mailto:', 'smsto:', 'sms:', 'begin:vcard', 'geo:',
  ];
}
