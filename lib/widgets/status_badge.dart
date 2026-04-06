import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, Color>? colorMap;

  const StatusBadge({
    super.key,
    required this.status,
    this.colorMap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (colorMap != null && colorMap!.containsKey(status)) {
      return colorMap![status]!;
    }

    switch (status.toUpperCase()) {
      // Properties
      case 'AVAILABLE':
        return Colors.green;
      case 'RESERVED':
        return Colors.orange;
      case 'SOLD':
        return Colors.blue;
      case 'RENTED':
        return Colors.purple;
      case 'OFF_MARKET':
        return Colors.grey;

      // Leads
      case 'NEW':
        return Colors.blue;
      case 'CONTACTED':
        return Colors.orange;
      case 'QUALIFIED':
        return Colors.green;
      case 'LOST':
        return Colors.red;
      case 'CLOSED_WON':
        return const Color(0xFF10B981); // Emerald

      // Deals
      case 'DISCOVERY':
        return Colors.blue;
      case 'NEGOTIATION':
        return Colors.orange;
      case 'CLOSED_LOST':
        return Colors.red;

      default:
        return Colors.blueGrey;
    }
  }
}
