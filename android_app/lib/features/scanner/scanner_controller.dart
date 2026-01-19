import 'package:flutter/foundation.dart';
import '../../models/scan_result.dart';
import '../../models/verdict.dart';
import '../../core/utils/redirect_resolver.dart';
import '../analysis/heuristic_analyzer.dart';
import '../analysis/score_analyzer.dart';
import '../history/history_provider.dart';

class ScannerController extends ChangeNotifier {
  final HeuristicAnalyzer _heuristicAnalyzer = HeuristicAnalyzer();
  final ScoreAnalyzer _scoreAnalyzer = ScoreAnalyzer();
  final HistoryProvider _historyProvider;

  ScannerController(this._historyProvider);

  Future<ScanResult> analyzeUrl(String url) async {
    final startTime = DateTime.now();

    debugPrint('Analyzing URL: $url');

    // Раскрытие редиректов для сокращённых ссылок
    String urlToAnalyze = url;
    List<String> redirectChain = [url];
    
    if (RedirectResolver.isShortenedUrl(url)) {
      debugPrint('Shortened URL detected, resolving redirects...');
      try {
        final redirectResult = await RedirectResolver.resolveRedirects(url);
        if (!redirectResult.hasError && redirectResult.hasRedirects) {
          urlToAnalyze = redirectResult.finalUrl;
          redirectChain = redirectResult.chain;
          debugPrint('Resolved to: $urlToAnalyze');
          debugPrint('Redirect chain: ${redirectChain.join(' -> ')}');
        } else if (redirectResult.hasError) {
          debugPrint('Redirect resolution error: ${redirectResult.error}');
          // Если не удалось раскрыть - помечаем как подозрительное
          final result = ScanResult(
            url: url,
            verdict: Verdict.suspicious,
            details: 'Короткая ссылка - не удалось раскрыть редирект: ${redirectResult.error}',
            reasons: ['Короткая ссылка', 'Ошибка раскрытия: ${redirectResult.error}'],
            timestamp: DateTime.now(),
            analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          );
          await _historyProvider.addScan(result);
          return result;
        }
      } catch (e) {
        debugPrint('Failed to resolve redirects: $e');
        // Если ошибка - помечаем как подозрительное
        final result = ScanResult(
          url: url,
          verdict: Verdict.suspicious,
          details: 'Короткая ссылка - не удалось раскрыть редирект',
          reasons: ['Короткая ссылка', 'Ошибка раскрытия редиректа'],
          timestamp: DateTime.now(),
          analysisTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
        await _historyProvider.addScan(result);
        return result;
      }
    }

    final heuristicResult = _heuristicAnalyzer.analyze(urlToAnalyze);
    debugPrint('Heuristic verdict: ${heuristicResult.verdict}');
    debugPrint('Heuristic details: ${heuristicResult.details}');

    Verdict finalVerdict;
    String finalDetails;
    List<String> allReasons = [];

    if (heuristicResult.verdict != Verdict.unknown) {
      finalVerdict = heuristicResult.verdict;
      finalDetails = heuristicResult.details;
      allReasons = heuristicResult.reasons;
    } else {
      final scoreResult = _scoreAnalyzer.analyze(urlToAnalyze);
      debugPrint('ML Score verdict: ${scoreResult.verdict}');
      debugPrint('ML Score: ${scoreResult.score}');
      finalVerdict = scoreResult.verdict;
      finalDetails = scoreResult.details;
      allReasons = scoreResult.reasons;
    }

    // Добавляем информацию о редиректах
    if (redirectChain.length > 1) {
      allReasons.insert(0, 'Редиректов: ${redirectChain.length - 1}');
    }

    final endTime = DateTime.now();
    final analysisTime = endTime.difference(startTime).inMilliseconds;

    final result = ScanResult(
      url: redirectChain.length > 1 ? '${redirectChain.first} → ${redirectChain.last}' : url,
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
