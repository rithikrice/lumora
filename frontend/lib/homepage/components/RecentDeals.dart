// lib/homepage/components/RecentDeals.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/homepage/theme.dart';

class RecentDeals extends StatelessWidget {
  const RecentDeals({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> deals = [
      {"name": "FinTechX", "stage": "Seed", "score": 82, "updated": "2d ago"},
      {
        "name": "HealthAI",
        "stage": "Series A",
        "score": 90,
        "updated": "1d ago",
      },
      {
        "name": "AgroNext",
        "stage": "Pre-Seed",
        "score": 74,
        "updated": "3d ago",
      },
    ];

    return Semantics(
      container: true,
      label: 'Recent Evaluations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Evaluations', style: heading(22)),
          const SizedBox(height: 12),
          Column(children: deals.map((d) => _DealCard(deal: d)).toList()),
        ],
      ),
    );
  }
}

class _DealCard extends StatefulWidget {
  final Map<String, dynamic> deal;
  const _DealCard({required this.deal});

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 234, 221),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _hover
                    ? const Color.fromARGB(255, 255, 128, 44).withOpacity(0.4)
                    : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                255,
                143,
                44,
              ).withOpacity(_hover ? 0.10 : 0.04),
              blurRadius: _hover ? 18 : 10,
              offset: Offset(0, _hover ? 10 : 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Stage: ${deal['stage']}', style: bodyStyle(13)),
              ],
            ),
            // right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Score: ${deal['score']}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: kAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Updated: ${deal['updated']}', style: bodyStyle(12)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: deal['score'] / 100),
                  duration: const Duration(milliseconds: 800),
                  builder:
                      (context, val, _) => Container(
                        width: 120,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kTextSecondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: val,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
