import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme colors
const Color kAccent1 = Color(0xFFFF6B2C);
const Color kAccent2 = Color(0xFF3E2CFF);
const Color kBackground = Color(0xFFFDFBF9);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class ExecutiveSummary extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ExecutiveSummary({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    // --- Safe fallbacks ---
    final List<String> bullets = List<String>.from(
      data?['bullets'] ??
          [
            "ARR growing 40% QoQ",
            "Low CAC compared to fintech peers",
            "Market expansion planned for SEA",
            "Founding team has prior exit experience",
          ],
    );

    final List<String> evidence = List<String>.from(
      data?['evidence'] ?? ["Evidence 1", "Evidence 2", "Evidence 3"],
    );

    // Alternate icons + colors (like original hardcoded)
    final List<IconData> icons = [
      Icons.trending_up,
      Icons.pie_chart,
      Icons.public,
      Icons.group,
    ];
    final List<Color> colors = [kAccent1, kAccent2, kAccent1, kAccent2];

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
              "Executive Summary",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Bullets
            for (int i = 0; i < bullets.length; i++) ...[
              _buildBullet(
                bullets[i],
                icons[i % icons.length],
                colors[i % colors.length],
              ),
            ],

            const SizedBox(height: 24),

            // Feature Card with Evidence Strip
            FeatureCard(
              title: "Verifiable Evidence Strip",
              description:
                  "Each claim links to slide, transcript snippet, screenshot, or article.",
              gradientColors: const [
                Color.fromARGB(255, 162, 53, 6),
                Color.fromARGB(255, 255, 118, 44),
              ],
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: evidence.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder:
                      (context, index) => Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: kCard.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kTextSecondary.withOpacity(0.15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          evidence[index],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: kTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FeatureCard widget (gradient + shadow + optional child)
class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final List<Color> gradientColors;
  final Widget? child;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.gradientColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kCard,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: kCard.withOpacity(0.85),
            ),
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}
