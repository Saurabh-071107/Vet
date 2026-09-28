import 'package:flutter/material.dart';
import '../core/constants.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.riskScore,
    this.severity,
    this.compact = false,
  });

  final int riskScore;
  final String? severity;
  final bool compact;

  Color get _badgeColor {
    if (riskScore >= 75) return VetAppConstants.dangerRed;
    if (riskScore >= 45) return VetAppConstants.warningAmber;
    return VetAppConstants.accentGreen;
  }

  Color get _bgTint => _badgeColor.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    final effectiveSeverity = severity ?? (riskScore >= 75 ? 'Critical' : (riskScore >= 45 ? 'High' : 'Moderate'));
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _bgTint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3.5, backgroundColor: _badgeColor),
            const SizedBox(width: 5),
            Text(
              '$riskScore% · $effectiveSeverity',
              style: TextStyle(
                color: _badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: _badgeColor, size: 14),
          const SizedBox(width: 5),
          Text(
            'AI Risk: $riskScore/100 · $effectiveSeverity',
            style: TextStyle(
              color: _badgeColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
