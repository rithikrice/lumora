import 'package:flutter/material.dart';
import 'package:lumora/startupProfile/GrowthSimulation.dart';

class RisksRedFlags extends StatelessWidget {
  const RisksRedFlags({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kAccent1 = Color(0xFFFF6B2C);
    const Color kAccent2 = Color.fromARGB(255, 62, 44, 255);
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🚩 Risks & Red Flags",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B2C), // Orange accent
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Risk Heatmap Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Risk Heatmap",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2CFF), // blue accent
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRiskHeatmap(),
                ],
              ),
              const SizedBox(height: 25),

              // 🔹 Evidence Highlights Header
              const Text(
                "Evidence Highlights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kAccent2, // Blue highlight
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _evidenceTag("Inconsistent ARR reporting", Icons.bar_chart),
                  _evidenceTag(
                    "Founder churn concerns",
                    Icons.people_alt_rounded,
                  ),
                  _evidenceTag("Regulatory risk in SEA", Icons.gavel),
                  _evidenceTag("Delayed fundraise detected", Icons.access_time),
                  _evidenceTag("Churn anomaly in Q2", Icons.trending_down),
                  _evidenceTag(
                    "Supply chain instability",
                    Icons.local_shipping,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 🔹 AI Risk Insight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kAccent1.withOpacity(0.1),
                      kAccent2.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFFF6B2C).withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  "💡 AI Insight: Risk levels elevated due to delayed fundraising and market volatility. "
                  "AI recommends closer monitoring of ARR consistency and founder retention strategies.",
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Evidence Tag Widget (Light Theme)
  Widget _evidenceTag(String text, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(
            255,
            227,
            226,
            245,
          ), // light blue background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kAccent2.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF007BFF), size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Simple Heatmap builder (dynamic color grid)
  Widget _buildRiskHeatmap() {
    final List<List<int>> heatData = [
      [20, 40, 60, 80, 100],
      [35, 55, 75, 85, 95],
      [10, 30, 50, 70, 90],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔸 Heatmap Grid
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF4EE), // soft orange base
                Color(0xFFF3F5FF), // soft blue tint
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                heatData
                    .map(
                      (row) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            row.map((v) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                margin: const EdgeInsets.all(4),
                                width: 40,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _getHeatColor(v),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(1, 2),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    )
                    .toList(),
          ),
        ),

        const SizedBox(height: 10),

        // 🔸 Legend Section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, "Low Risk (<30)"),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, "Medium Risk (30–60)"),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red, "High Risk (>60)"),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Color _getHeatColor(int value) {
    if (value < 30) return Colors.green.withOpacity(0.8);
    if (value < 60) return Colors.orange.withOpacity(0.8);
    return Colors.red.withOpacity(0.8);
  }
}
