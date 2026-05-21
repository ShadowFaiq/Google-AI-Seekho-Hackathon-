import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = const Color(0xFF6CF8BB); // Secondary container
        textColor = const Color(0xFF00714D); // On secondary container
        break;
      case 'pending':
        bgColor = const Color(0xFFFFDDB8); // Tertiary fixed
        textColor = const Color(0xFF653E00); // On tertiary fixed variant
        break;
      case 'in_progress':
      case 'accepted':
        bgColor = const Color(0xFFDAE2FD); // Primary fixed
        textColor = const Color(0xFF131B2E); // On primary fixed
        break;
      default:
        bgColor = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
