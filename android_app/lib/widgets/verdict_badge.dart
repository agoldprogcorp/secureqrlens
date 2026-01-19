import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/verdict.dart';

class VerdictBadge extends StatelessWidget {
  final Verdict verdict;
  final double size;

  const VerdictBadge({
    super.key,
    required this.verdict,
    this.size = 60,
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

  IconData _getIcon() {
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

  String _getLabel() {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIcon(),
          size: size,
          color: _getColor(),
        ),
        const SizedBox(height: 8),
        Text(
          _getLabel(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getColor(),
          ),
        ),
      ],
    );
  }
}
