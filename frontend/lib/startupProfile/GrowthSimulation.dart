import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lumora/config/ApiConfig.dart';

final apiUrl = Uri.parse("${ApiConfig.baseUrl}/v1/finance/model");

const Color kAccent1 = Color(0xFFFF6B2C); // Orange
const Color kAccent2 = Color(0xFF3E2CFF); // Sapphire Blue
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class GrowthSimulation extends StatefulWidget {
  final String startupId;

  const GrowthSimulation({super.key, required this.startupId});

  @override
  State<GrowthSimulation> createState() => _GrowthSimulationState();
}

class _GrowthSimulationState extends State<GrowthSimulation> {
  bool isLoading = true;
  Map<String, dynamic>? data;
  String selectedScenario = "base";

  @override
  void initState() {
    super.initState();
    // fetchGrowthData();
    mockGrowthData();
  }

  void mockGrowthData() {
    final mock = {
      "startup_id": widget.startupId,
      "current_metrics": {
        "arr": 2500000,
        "growth_rate": 85,
        "burn_rate": 1200000,
        "gross_margin": 65,
      },
      "projections": {
        "scenarios": {
          "base": [
            {"year": 2025, "revenue": 2000000},
            {"year": 2026, "revenue": 4000000},
            {"year": 2027, "revenue": 8000000},
            {"year": 2028, "revenue": 12000000},
            {"year": 2029, "revenue": 17000000},
          ],
          "optimistic": [
            {"year": 2025, "revenue": 2500000},
            {"year": 2026, "revenue": 6000000},
            {"year": 2027, "revenue": 12000000},
            {"year": 2028, "revenue": 20000000},
            {"year": 2029, "revenue": 30000000},
          ],
          "pessimistic": [
            {"year": 2025, "revenue": 1500000},
            {"year": 2026, "revenue": 2500000},
            {"year": 2027, "revenue": 4000000},
            {"year": 2028, "revenue": 6000000},
            {"year": 2029, "revenue": 8000000},
          ],
        },
      },
    };

    setState(() {
      data = mock;
      isLoading = false;
    });
  }

  Future<void> fetchGrowthData() async {
    setState(() => isLoading = true);

    final body = {
      "startup_id": widget.startupId,
      "years": 5,
      "scenarios": ["base", "optimistic", "pessimistic"],
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "X-API-Key": "dev-secret",
        },
        body: jsonEncode(body),
      );

      debugPrint(response.body);

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      debugPrint("Error fetching growth data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: kAccent1.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : data == null
                ? const Text("Error loading simulation data")
                : _buildSimulationContent(),
      ),
    );
  }

  Widget _buildSimulationContent() {
    final scenarios = data!["projections"]["scenarios"];
    final currentScenarioData = scenarios[selectedScenario] as List<dynamic>;

    final spots =
        currentScenarioData
            .asMap()
            .entries
            .map(
              (e) => FlSpot(
                e.key.toDouble(),
                (e.value["revenue"] / 1000000)
                    .toDouble(), // Convert to millions
              ),
            )
            .toList();

    final years = currentScenarioData.map((e) => e["year"].toString()).toList();

    final currentMetrics = data!["current_metrics"];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Text(
            "📈 AI Growth Simulation",
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Scenario-based projections for ${data!["startup_id"]}",
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // 🔹 Scenario Selector
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  ["base", "optimistic", "pessimistic"]
                      .map(
                        (scenario) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(
                              scenario.toUpperCase(),
                              style: TextStyle(
                                color:
                                    selectedScenario == scenario
                                        ? Colors.white
                                        : kTextPrimary,
                              ),
                            ),
                            selected: selectedScenario == scenario,
                            selectedColor: kAccent2,
                            backgroundColor: Colors.grey[100],
                            onSelected:
                                (_) =>
                                    setState(() => selectedScenario = scenario),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Animated Chart
          Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kAccent1.withOpacity(0.05),
                  kAccent2.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, meta) => Text(
                            "\$${value.toInt()}M",
                            style: const TextStyle(fontSize: 11),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < years.length) {
                          return Text(
                            years[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kAccent1,
                    belowBarData: BarAreaData(
                      show: true,
                      color: kAccent1.withOpacity(0.2),
                    ),
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Key Metrics Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCard("ARR", "\$${_formatNumber(currentMetrics["arr"])}"),
              _metricCard("Growth", "${currentMetrics["growth_rate"]}%"),
              _metricCard(
                "Burn",
                "\$${_formatNumber(currentMetrics["burn_rate"])}",
              ),
              _metricCard("Margin", "${currentMetrics["gross_margin"]}%"),
            ],
          ),
          const SizedBox(height: 20),

          // 🔹 AI Insight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kAccent1.withOpacity(0.07),
                  kAccent2.withOpacity(0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "💡 AI Insights:\n"
              "• ${selectedScenario == "base"
                  ? "Stable 100% YoY growth expected."
                  : selectedScenario == "optimistic"
                  ? "Aggressive scaling with 150% YoY revenue growth."
                  : "Cautious 50% YoY growth under stress."}\n"
              "• Profitability improves post-2027.\n"
              "• Healthy burn margin maintained for 5 years.",
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(num n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }
}
