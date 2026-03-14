import 'package:flutter/foundation.dart';
import '../../models/scan_result.dart';
import '../../models/verdict.dart';
import '../../core/utils/redirect_resolver.dart';
import '../analysis/heuristic_analyzer.dart';
import '../analysis/ml_analyzer.dart';
import '../analysis/content_classifier.dart';
import '../history/history_provider.dart';

class ScannerController extends ChangeNotifier {
  final HeuristicAnalyzer _heuristicAnalyzer = HeuristicAnalyzer();
  final HistoryProvider _historyProvider;

  ScannerController(this._historyProvider);

  Future<ScanResult> analyzeUrl(String raw) async {
    final startTime = DateTime.now();
    final classification = ContentClassifier.classify(raw);

    if (classification.type == ContentType.wifi) {
      final wifiParams = ContentClassifier.parseWifi(raw);
      final authType = (wifiParams['T'] ?? '').toUpperCase();
      final ssid = wifiParams['S'] ?? 'Неизвестная сеть';
      final hidden = wifiParams['H'] == 'true';

      Verdict wifiVerdict;
      String wifiDetails;
      List<String> wifiReasons;

      if (authType.isEmpty || authType == 'NOPASS' || authType == '' || authType == 'OPEN') {
        wifiVerdict = Verdict.danger;
        wifiDetails = 'Открытая Wi-Fi сеть "$ssid" — без пароля!';
        wifiReasons = [
          'Wi-Fi без шифрования',
          'Трафик может быть перехвачен',
          'Возможна атака Man-in-the-Middle',
        ];
      } else if (authType == 'WEP') {
        wifiVerdict = Verdict.suspicious;
        wifiDetails = 'Wi-Fi "$ssid": устаревшее шифрование WEP';
        wifiReasons = ['WEP взламывается за минуты', 'Рекомендуется WPA2/WPA3'];
      } else {
        wifiVerdict = Verdict.safe;
        wifiDetails = 'Wi-Fi "$ssid" защищена ($authType)';
        wifiReasons = [
          'Шифрование: $authType',
          if (hidden) 'Скрытая сеть',
        ];
      }

      final result = ScanResult(
        url: raw,
        verdict: wifiVerdict,
        details: wifiDetails,
        reasons: wifiReasons,
        timestamp: DateTime.now(),
        analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
      await _historyProvider.addScan(result);
      return result;
    }

    if (classification.type == ContentType.nonUrl) {
      final result = ScanResult(
        url: raw,
        verdict: Verdict.unknown,
        details: '${classification.typeLabel}: содержимое отображено без анализа безопасности',
        reasons: ['Тип: ${classification.typeLabel}', 'Не является URL'],
        timestamp: DateTime.now(),
        analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
      await _historyProvider.addScan(result);
      return result;
    }

    if (classification.type == ContentType.deepLink) {
      final result = ScanResult(
        url: raw,
        verdict: Verdict.suspicious,
        details: 'Deep Link обходит браузер и выполняет действие напрямую',
        reasons: [
          'Deep Link: ${classification.deepLinkScheme}',
          'Минует браузерную защиту',
        ],
        timestamp: DateTime.now(),
        analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
      await _historyProvider.addScan(result);
      return result;
    }

    String urlToAnalyze = raw;
    List<String> redirectChain = [raw];

    if (classification.type == ContentType.shortUrl) {
      try {
        final redirectResult = await RedirectResolver.resolveRedirects(raw);
        if (!redirectResult.hasError && redirectResult.hasRedirects) {
          urlToAnalyze = redirectResult.finalUrl;
          redirectChain = redirectResult.chain;
        } else if (redirectResult.hasError) {
          final result = ScanResult(
            url: raw,
            verdict: Verdict.suspicious,
            details: 'Не удалось раскрыть сокращённую ссылку',
            reasons: [
              'Сокращённая ссылка (${classification.typeLabel})',
              'Ошибка: ${redirectResult.error}',
            ],
            timestamp: DateTime.now(),
            analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          );
          await _historyProvider.addScan(result);
          return result;
        }
      } catch (e) {
        final result = ScanResult(
          url: raw,
          verdict: Verdict.suspicious,
          details: 'Не удалось раскрыть сокращённую ссылку',
          reasons: ['Сокращённая ссылка', 'Ошибка сети'],
          timestamp: DateTime.now(),
          analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
        await _historyProvider.addScan(result);
        return result;
      }
    }

    final heuristicResult = _heuristicAnalyzer.analyze(urlToAnalyze);

    Verdict finalVerdict;
    String finalDetails;
    List<String> allReasons;

    if (heuristicResult.verdict != Verdict.unknown) {
      finalVerdict = heuristicResult.verdict;
      finalDetails = heuristicResult.details;
      allReasons = heuristicResult.reasons;
    } else {
      final mlResult = MlAnalyzer.analyze(urlToAnalyze);
      finalVerdict = mlResult.verdict;
      finalDetails = mlResult.details;
      allReasons = mlResult.probabilities.entries
          .map((e) => '${e.key}: ${(e.value * 100).round()}%')
          .toList();
    }

    if (redirectChain.length > 1) {
      allReasons.insert(0, 'Редиректов: ${redirectChain.length - 1}');
    }

    final analysisTime = DateTime.now().difference(startTime).inMilliseconds;

    final result = ScanResult(
      url: redirectChain.length > 1
          ? '${redirectChain.first} → ${redirectChain.last}'
          : raw,
      verdict: finalVerdict,
      details: finalDetails,
      reasons: allReasons,
      timestamp: DateTime.now(),
      analysisTimeMs: analysisTime,
    );

    await _historyProvider.addScan(result);
    return result;
  }
}
