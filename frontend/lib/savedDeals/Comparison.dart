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
    final payload = {
      "startup_ids": widget.startups.map((s) => s.id).toList(),
      "metrics": ["score", "stage", "risks", "revenue", "customers", "runway"],
    };

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
      debugPrint(response.body);

      if (response.statusCode == 200) {
        setState(() {
          comparisonData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        debugPrint("Comparison error: ${response.body}");
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComparisonTable(),
                    const SizedBox(height: 24),
                    _buildAdditionalCharts(),
                    const SizedBox(height: 24),
                    _buildScoreChart(),
                    const SizedBox(height: 24),
                    _buildRiskChart(),
                  ],
                ),
              ),
    );
  }

  Widget _buildComparisonTable() {
    final comparison = comparisonData?["comparison"] ?? {};
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: {0: const FixedColumnWidth(150)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: kAccent),
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
                    s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildRow("Stage", widget.startups.map((s) => s.stage).toList()),
          _buildRow(
            "Score",
            widget.startups
                .map((s) => comparison[s.id]?["score"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Burn Rate",
            widget.startups
                .map((s) => comparison[s.id]?["burn_rate"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Funding Raised",
            widget.startups
                .map((s) => comparison[s.id]?["customers"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Runway",
            widget.startups
                .map((s) => comparison[s.id]?["runway"]?.toString() ?? "-")
                .toList(),
          ),
          _buildRow(
            "Risks",
            widget.startups
                .map(
                  (s) =>
                      (comparison[s.id]?["risks"] as List?)?.join(", ") ?? "-",
                )
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
          return parseDouble(comparison[s.id]?["score"]);
        }).toList();

    final maxY =
        (scores.isEmpty ? 100 : scores.reduce((a, b) => a > b ? a : b)) * 1.2;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Comparison',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
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
                          width: 24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          int idx = v.toInt();
                          if (idx < widget.startups.length)
                            return Text(widget.startups[idx].name);
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalCharts() {
    final comparison = comparisonData?["comparison"] ?? {};

    final scores =
        widget.startups.map((s) {
          final val = comparison[s.id]?["score"];
          return val != null ? (val as num).toDouble() : 0.0;
        }).toList();

    final burn =
        widget.startups.map((s) {
          final val = comparison[s.id]?["burn_rate"];
          return val != null ? (val as num).toDouble() : 0.0;
        }).toList();

    final funding =
        widget.startups.map((s) {
          final val = comparison[s.id]?["customers"];
          return val != null ? (val as num).toDouble() : 0.0;
        }).toList();

    final runway =
        widget.startups.map((s) {
          final val = comparison[s.id]?["runway"];
          return val != null ? (val as num).toDouble() : 0.0;
        }).toList();

    return Column(children: [_buildCombinedChart()]);
  }

  Widget _buildBarChart(String title, List<double> values) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (values.isEmpty
                          ? 0
                          : values.reduce((a, b) => a > b ? a : b)) *
                      1.2,
                  barGroups:
                      values.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: kAccent,
                              width: 24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 20),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          int idx = v.toInt();
                          if (idx < widget.startups.length)
                            return Text(widget.startups[idx].name);
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskChart() {
    final riskDistribution =
        comparisonData?["risk_distribution"] as Map<String, dynamic>? ?? {};

    final sections =
        riskDistribution.entries.map((e) {
          final idx = riskDistribution.keys.toList().indexOf(e.key);
          return PieChartSectionData(
            value: parseDouble(e.value),
            color: Colors.primaries[idx % Colors.primaries.length],
            title: e.key,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedChart() {
    final comparison = comparisonData?["comparison"] ?? {};

    List<double> getMetric(String key) {
      return widget.startups.map((s) {
        final val = comparison[s.id]?[key];
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }).toList();
    }

    final scores = getMetric("score");
    final burn = getMetric("burn_rate");
    final funding = getMetric("customers");
    final runway = getMetric("runway");

    final maxY =
        [
          ...scores,
          ...burn,
          ...funding,
          ...runway,
        ].fold(0.0, (prev, e) => e > prev ? e : prev) *
        1.2;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Combined Metrics",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  groupsSpace: 20,
                  barGroups: List.generate(widget.startups.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: scores[i],
                          color: Colors.blue,
                          width: 10,
                        ),
                        BarChartRodData(
                          toY: burn[i],
                          color: Colors.green,
                          width: 10,
                        ),
                        BarChartRodData(
                          toY: funding[i],
                          color: Colors.orange,
                          width: 10,
                        ),
                        BarChartRodData(
                          toY: runway[i],
                          color: Colors.purple,
                          width: 10,
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          int idx = v.toInt();
                          if (idx < widget.startups.length)
                            return Text(widget.startups[idx].name);
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LegendDot(color: Colors.blue, label: "Score"),
                _LegendDot(color: Colors.green, label: "Burn Rate"),
                _LegendDot(color: Colors.orange, label: "Funding"),
                _LegendDot(color: Colors.purple, label: "Runway"),
              ],
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
