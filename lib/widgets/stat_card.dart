import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.count,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.icon,
    this.asset,
    this.onTap,
  });

  final String count;
  final String title;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String? asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withValues(alpha: 0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: asset == null
                    ? Icon(icon, color: Colors.white, size: 22)
                    : Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(asset!, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        color: VetAppConstants.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VetAppConstants.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
