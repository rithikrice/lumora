import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:lumora/savedDeals/SavedDeals.dart';
import 'package:lumora/config/ApiConfig.dart';

const Color primaryColor = Color(0xFFF7F8F9);
const Color kAccent = Color(0xFFFF6B2C);
const double kCardRadius = 14.0;

class ComparisonPage extends StatefulWidget {
  final List<Startup> startups;

  const ComparisonPage({super.key, required this.startups});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  Map<String, dynamic>? comparisonData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComparison();
  }

  Future<void> _fetchComparison() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/v1/ui/comparison");
    final payload = {"startup_ids": widget.startups.map((s) => s.id).toList()};

    try {
      final response = await http.post(
        url,
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "X-API-Key": "dev-secret",
        },
        body: jsonEncode(payload),
      );

      debugPrint("Comparison API status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          comparisonData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        debugPrint("Comparison API error: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching comparison: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Startup Comparison',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : comparisonData == null
              ? const Center(child: Text("No comparison data"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 248, 208, 190),
                        Colors.white,
                        Color.fromARGB(255, 248, 208, 190),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComparisonTable(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(flex: 2, child: _buildScoreChart()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildRiskChart()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// 🧩 Comparison Table
  Widget _buildComparisonTable() {
    final comparison = comparisonData?["comparison"] ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: {0: const FixedColumnWidth(140)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: kAccent),
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Metric',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...widget.startups.map(
                (s) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    comparison[s.id]?["name"] ?? s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          _buildRow(
            "Stage",
            widget.startups
                .map((s) => comparison[s.id]?["stage"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Score",
            widget.startups
                .map(
                  (s) =>
                      (comparison[s.id]?["score"]?.toString() ?? "-")
                          .toString(),
                )
                .toList(),
          ),
          _buildRow(
            "Runway (months)",
            widget.startups
                .map((s) => comparison[s.id]?["runway"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Churn (%)",
            widget.startups
                .map((s) => comparison[s.id]?["churn"]?.toString() ?? "-")
                .toList(),
          ),
        ],
      ),
    );
  }

  TableRow _buildRow(String metric, List<String> values) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            metric,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...values.map(
          (v) => Padding(padding: const EdgeInsets.all(12), child: Text(v)),
        ),
      ],
    );
  }

  Widget _buildScoreChart() {
    final comparison = comparisonData?["comparison"] ?? {};

    final scores =
        widget.startups.map((s) {
          final val = comparison[s.id]?["score"];
          return val is num
              ? val.toDouble()
              : double.tryParse(val.toString()) ?? 0;
        }).toList();

    final maxY =
        (scores.isEmpty ? 1 : scores.reduce((a, b) => a > b ? a : b)) * 1.2;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      color: const Color(0xFFFFF6F1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Comparison',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 270,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(widget.startups.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: scores[i],
                          color: kAccent,
                          width: 28,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.2,
                        reservedSize: 32,
                        getTitlesWidget:
                            (v, _) => Text(
                              "${(v * 100).toInt()}%",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < widget.startups.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.startups[idx].name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 0.2,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 0.8,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildRiskChart() {
  //   final riskDistribution =
  //       comparisonData?["risk_distribution"] as Map<String, dynamic>? ?? {};

  //   final colors = [
  //     Colors.redAccent,
  //     Colors.deepOrange,
  //     Colors.amber[700],
  //     Colors.purpleAccent,
  //   ];

  //   final sections =
  //       riskDistribution.entries.map((e) {
  //         final idx = riskDistribution.keys.toList().indexOf(e.key);
  //         return PieChartSectionData(
  //           value: parseDouble(e.value),
  //           color: colors[idx % colors.length],
  //           title: '',
  //           radius: 55,
  //         );
  //       }).toList();

  //   return Card(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(kCardRadius),
  //     ),
  //     elevation: 4,
  //     color: const Color(0xFFFFF6F1),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Risk Distribution',
  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //           ),
  //           const SizedBox(height: 12),
  //           SizedBox(
  //             height: 220,
  //             child: PieChart(
  //               PieChartData(
  //                 sections: sections,
  //                 sectionsSpace: 2,
  //                 centerSpaceRadius: 40,
  //                 borderData: FlBorderData(show: false),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           Wrap(
  //             alignment: WrapAlignment.center,
  //             spacing: 16,
  //             runSpacing: 8,
  //             children: List.generate(riskDistribution.length, (i) {
  //               final key = riskDistribution.keys.elementAt(i);
  //               final value = riskDistribution[key];
  //               return Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Container(
  //                     width: 12,
  //                     height: 12,
  //                     decoration: BoxDecoration(
  //                       color: colors[i % colors.length],
  //                       borderRadius: BorderRadius.circular(3),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 6),
  //                   Text(
  //                     "$key (${value.toString()}%)",
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             }),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRiskChart() {
    // Safely extract the risk distribution from API response
    final riskDistribution =
        (comparisonData?["risk_distribution"] as Map<String, dynamic>?) ?? {};

    if (riskDistribution.isEmpty) {
      return const Center(child: Text("No risk data available"));
    }

    // Define consistent colors for each segment
    final colors = [
      Colors.redAccent,
      Colors.deepOrange,
      Colors.amber[700],
      Colors.purpleAccent,
    ];

    // Calculate total to normalize percentages for the pie chart
    final total = riskDistribution.values.fold<num>(0, (sum, v) {
      final parsed =
          (v is num)
              ? v
              : double.tryParse(v.toString().replaceAll('%', '').trim()) ?? 0;
      return sum + parsed;
    });

    // Build chart sections based on dynamic data
    final sections =
        riskDistribution.entries.map((entry) {
          final idx = riskDistribution.keys.toList().indexOf(entry.key);
          final double value =
              (entry.value is num)
                  ? (entry.value as num).toDouble()
                  : double.tryParse(entry.value.toString()) ?? 0.0;

          final percentage = total == 0 ? 0 : (value / total) * 100;

          return PieChartSectionData(
            value: value,
            color: colors[idx % colors.length],
            title: "${percentage.toStringAsFixed(0)}%",
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList();

    // Calculate overall weighted risk index (optional visual metric)
    final riskIndex = total / riskDistribution.length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      color: const Color(0xFFFFF6F1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Risk Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Risk Index: ${riskIndex.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: List.generate(riskDistribution.length, (i) {
                final key = riskDistribution.keys.elementAt(i);
                final value = riskDistribution[key];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$key (${value.toString()}%)",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
