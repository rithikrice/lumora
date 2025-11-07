import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ================= THEME =================
const Color kPrimary = Color(0xFF1E1E2F);
const Color kSurface = Color(0xFFF8F9FB);
const Color kAccent1 = Color(0xFF6751E9);
const Color kAccent2 = Color(0xFFFF7043);
const Color kNeutral = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kSuccess = Color(0xFF22C55E);
const Color kWarning = Color(0xFFF59E0B);

class InvestmentHighlightsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const InvestmentHighlightsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List strengths = data['keyStrengths'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Investment Highlights"),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _highlightCard(
                    "Current Ask",
                    data['currentAsk'] ?? "-",
                    kAccent2,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _highlightCard(
                    "Use of Funds",
                    data['useOfFunds'] ?? "-",
                    kAccent1,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _highlightCard(
                    "Exit Strategy",
                    data['exitStrategy'] ?? "-",
                    kAccent2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _keyStrengths(strengths),
          ],
        ),
      ),
    );
  }

  // ================= SECTIONS =================
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: kPrimary,
      ),
    );
  }

  Widget _highlightCard(String title, String value, Color accent) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: kNeutral,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: kPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyStrengths(List strengths) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Key Strengths",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...strengths.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(color: kAccent1)),
                  Expanded(
                    child: Text(
                      s.toString(),
                      style: GoogleFonts.inter(fontSize: 14, color: kNeutral),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
