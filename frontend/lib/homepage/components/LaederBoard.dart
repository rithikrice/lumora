import 'package:flutter/material.dart';

// 🎨 Theme
const Color kCard = Colors.white;
const Color kAccent = Color(0xFFFF6B2C);
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> leaders = [
      {"name": "HealthAI", "score": 90},
      {"name": "FinTechX", "score": 82},
      {"name": "AgroNext", "score": 74},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Top Startups",
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Leader cards
        Column(
          children:
              leaders
                  .asMap()
                  .entries
                  .map((entry) => _leaderCard(entry.key, entry.value))
                  .toList(),
        ),
      ],
    );
  }

  Widget _leaderCard(int index, Map<String, dynamic> leader) {
    // rank badge
    final badges = ["🥇", "🥈", "🥉"];
    final badge = index < 3 ? badges[index] : "⭐";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with name + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(badge, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    leader["name"],
                    style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                "${leader["score"]}",
                style: TextStyle(
                  color: kAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar (animated)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: leader["score"] / 100),
            builder:
                (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: kTextSecondary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(kAccent),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                ),
          ),
        ],
      ),
    );
  }
}
