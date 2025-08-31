import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpecialtyTile extends StatelessWidget {
  final String specialty;

  const SpecialtyTile({super.key, required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet or icon
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Color.fromARGB(255, 162, 71, 11),
          ),
          const SizedBox(width: 12),

          // Specialty Text
          Expanded(
            child: Text(
              specialty,
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
