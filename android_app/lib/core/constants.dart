import 'package:flutter/services.dart';

class AppConstants {
  // Загружаемые whitelist'ы
  static List<String>? _sbpWhitelist;
  static List<String>? _brandWhitelist;

  // Дефолтные значения (если файлы не загрузятся)
  static const List<String> _defaultSbpWhitelist = [
    'qr.nspk.ru',
    'sbp-qr.ru',
    'qr.nspk.org',
    'sbp.nspk.ru',
    'nspk.ru',
  ];

  static const List<String> _defaultBrandWhitelist = [
    'sberbank.ru',
    'alfabank.ru',
    'vtb.ru',
    'tinkoff.ru',
    'yandex.ru',
    'google.com',
    'mail.ru',
    'vk.com',
  ];

  // Геттеры
  static List<String> get sbpWhitelist => _sbpWhitelist ?? _defaultSbpWhitelist;
  static List<String> get brandWhitelist => _brandWhitelist ?? _defaultBrandWhitelist;

  // Загрузка whitelist'ов из assets
  static Future<void> loadWhitelists() async {
    try {
      // Загрузка СБП whitelist
      final sbpContent = await rootBundle.loadString('assets/sbp_whitelist.txt');
      _sbpWhitelist = sbpContent
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();

      // Загрузка brands whitelist
      final brandsContent = await rootBundle.loadString('assets/whitelist_brands.txt');
      _brandWhitelist = brandsContent
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();
    } catch (e) {
      // Если не удалось загрузить - используем дефолтные
      _sbpWhitelist = _defaultSbpWhitelist;
      _brandWhitelist = _defaultBrandWhitelist;
    }
  }

  static const List<String> malwareExtensions = [
    '.apk',
    '.exe',
    '.scr',
    '.bat',
    '.vbs',
    '.cmd',
  ];

  static const List<String> deepLinkSchemes = [
    'tg://',
    'sber://',
    'bank://',
    'ton://',
    'whatsapp://',
    'tinkoff://',
    'alfa://',
    'vtb://',
    'sberpay://',
  ];

  static const double entropyThreshold = 4.5;
  static const int levenshteinThreshold = 2;
}
