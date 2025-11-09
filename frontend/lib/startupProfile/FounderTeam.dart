import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme colors (same as original)
const Color kAccent1 = Color(0xFFFF6B2C);
const Color kAccent2 = Color(0xFF3E2CFF);
const Color kBackground = Color(0xFFFDFBF9);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class FounderTeam extends StatelessWidget {
  /// Pass founders list and metrics; any missing values use defaults
  final Map<String, dynamic>? data;

  const FounderTeam({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    // --- Data with safe fallbacks ---
    final List<Map<String, String>> founders = List<Map<String, String>>.from(
      data?['founders'] ??
          [
            {
              'name': 'Shametha Naidu',
              'role': 'CEO & Co-Founder',
              'initials': 'SN',
              'color': 'accent1',
            },
            {
              'name': 'Rithik Chopra',
              'role': 'CTO & Co-Founder',
              'initials': 'RC',
              'color': 'accent2',
            },
          ],
    );

    final metrics =
        data?['metrics'] ??
        {'integrityScore': '87%', 'culturalFit': 'High Alignment'};

    return Card(
      elevation: 6,
      color: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              "Founding Team",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Team Members
            for (var f in founders) ...[
              _buildTeamMember(
                name: f['name'] ?? 'Shametha',
                role: f['role'] ?? 'Naidu',
                initials: f['initials'] ?? 'Some initials',
                highlightColor: (f['color'] == 'accent2') ? kAccent2 : kAccent1,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Key Metrics
            _metricCard(
              "Founder Integrity Score",
              metrics['integrityScore'] ?? '87%',
              kAccent1,
              Icons.verified_user,
            ),
            _metricCard(
              "Cultural Fit Score",
              metrics['culturalFit'] ?? 'High Alignment',
              kAccent2,
              Icons.handshake,
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable team member card
  Widget _buildTeamMember({
    required String name,
    required String role,
    required String initials,
    required Color highlightColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: highlightColor.withOpacity(0.9),
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kCard,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            Text(
              role,
              style: GoogleFonts.inter(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ),
      ],
    );
  }

  /// Reusable metric card with icon
  Widget _metricCard(
    String title,
    String value,
    Color highlight,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: highlight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: highlight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: kTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight,
            ),
          ),
        ],
      ),
    );
  }
}
