import 'package:flutter/services.dart';

class AppConstants {
  static List<String>? _brandWhitelist;

  static const List<String> _defaultBrandWhitelist = [
    'qr.nspk.ru', 'sbp-qr.ru', 'nspk.ru',
    'sberbank.ru', 'alfabank.ru', 'vtb.ru', 'tinkoff.ru',
    'yandex.ru', 'google.com', 'mail.ru', 'vk.com',
  ];

  static List<String> get brandWhitelist => _brandWhitelist ?? _defaultBrandWhitelist;

  static Future<void> loadWhitelists() async {
    try {
      final content = await rootBundle.loadString('assets/whitelist_brands.txt');
      _brandWhitelist = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();
    } catch (e) {
      _brandWhitelist = _defaultBrandWhitelist;
    }
  }

  static const List<String> malwareExtensions = [
    '.apk', '.exe', '.scr', '.bat', '.vbs', '.cmd',
  ];

  static const List<String> deepLinkSchemes = [
    'tg://', 'sber://', 'bank://', 'ton://', 'whatsapp://',
    'tinkoff://', 'alfa://', 'vtb://', 'sberpay://',
  ];

  static const double entropyThreshold = 3.2;
  static const int levenshteinThreshold = 2;
}
