import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/verdict.dart';

class VerdictCard extends StatelessWidget {
  final Verdict verdict;
  final String details;
  final List<String> reasons;

  const VerdictCard({
    super.key,
    required this.verdict,
    required this.details,
    this.reasons = const [],
  });

  Color _getColor() {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: _getColor().withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Причины:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...reasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
