import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/verdict.dart';
import '../analysis/analysis_screen.dart';
import 'history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          Expanded(
            child: Consumer<HistoryProvider>(
              builder: (context, provider, child) {
                final scans = provider.scans;

                if (scans.isEmpty) {
                  return const Center(
                    child: Text('История пуста'),
                  );
                }

                return ListView.builder(
                  itemCount: scans.length,
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    return Dismissible(
                      key: Key(scan.timestamp.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        provider.removeScan(scan);
                      },
                      child: ListTile(
                        leading: Icon(
                          _getVerdictIcon(scan.verdict),
                          color: _getVerdictColor(scan.verdict),
                        ),
                        title: Text(
                          scan.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('dd.MM.yyyy HH:mm').format(scan.timestamp),
                        ),
                        trailing: Chip(
                          label: Text(
                            _getVerdictLabel(scan.verdict),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              _getVerdictColor(scan.verdict).withValues(alpha: 0.2),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalysisScreen(result: scan),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Поиск по URL',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          context.read<HistoryProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Все'),
            selected: provider.filterVerdict == null,
            onSelected: (_) => provider.setFilter(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('SAFE'),
            selected: provider.filterVerdict == Verdict.safe,
            onSelected: (_) => provider.setFilter(Verdict.safe),
            backgroundColor: AppTheme.safe.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('SUSPICIOUS'),
            selected: provider.filterVerdict == Verdict.suspicious,
            onSelected: (_) => provider.setFilter(Verdict.suspicious),
            backgroundColor: AppTheme.suspicious.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('DANGER'),
            selected: provider.filterVerdict == Verdict.danger,
            onSelected: (_) => provider.setFilter(Verdict.danger),
            backgroundColor: AppTheme.danger.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все записи будут удалены'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  IconData _getVerdictIcon(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return Icons.check_circle;
      case Verdict.danger:
        return Icons.dangerous;
      case Verdict.suspicious:
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getVerdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return AppTheme.safe;
      case Verdict.danger:
        return AppTheme.danger;
      case Verdict.suspicious:
        return AppTheme.suspicious;
      default:
        return Colors.grey;
    }
  }

  String _getVerdictLabel(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return 'SAFE';
      case Verdict.danger:
        return 'DANGER';
      case Verdict.suspicious:
        return 'SUSPICIOUS';
      default:
        return 'UNKNOWN';
    }
  }
}
