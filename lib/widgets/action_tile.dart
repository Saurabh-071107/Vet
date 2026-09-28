import 'package:flutter/material.dart';
import '../core/constants.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.asset,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? asset;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VetAppConstants.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060E2C4D),
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: asset == null
                    ? Icon(icon, color: color, size: 26)
                    : Padding(
                        padding: const EdgeInsets.all(9),
                        child: Image.asset(asset!, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VetAppConstants.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VetAppConstants.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
