import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scan_result.dart';
import '../../models/verdict.dart';

class HistoryProvider extends ChangeNotifier {
  List<ScanResult> _scans = [];
  Verdict? _filterVerdict;
  String _searchQuery = '';

  List<ScanResult> get scans {
    var filtered = _scans;

    if (_filterVerdict != null) {
      filtered = filtered.where((s) => s.verdict == _filterVerdict).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.url.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Verdict? get filterVerdict => _filterVerdict;
  String get searchQuery => _searchQuery;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('scan_history');

    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _scans = decoded.map((e) => ScanResult.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addScan(ScanResult result) async {
    _scans.insert(0, result);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeScan(ScanResult result) async {
    _scans.remove(result);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _scans.clear();
    await _saveHistory();
    notifyListeners();
  }

  void setFilter(Verdict? verdict) {
    _filterVerdict = verdict;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_scans.map((e) => e.toJson()).toList());
    await prefs.setString('scan_history', encoded);
  }
}
