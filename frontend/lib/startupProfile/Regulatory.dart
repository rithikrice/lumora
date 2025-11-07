import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lumora/startupProfile/WorldMap.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

const Color kAccent1 = Color(0xFFFF6B2C); // Orange
const Color kAccent2 = Color(0xFF3E2CFF); // Electric Blue
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class RegulatoryRadar extends StatelessWidget {
  final Map<String, dynamic> data;
  const RegulatoryRadar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> alerts = data['alerts'] ?? [];
    final int riskScore = (data['risk_score'] ?? 0).clamp(0, 100);
    // trend_values: list<double> 0-100; trend_labels: list<String>
    final List<double> trendValues =
        (data['trend_values'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [50, 55, 60, 58, 65, 62, riskScore.toDouble()];
    final List<String> trendLabels =
        (data['trend_labels'] as List?)?.map((e) => e.toString()).toList() ??
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    // Map data: list of {'country': 'IND', 'risk': 80}  (ISO3 or ISO2 depending on shapes)
    final List<Map<String, dynamic>> mapData =
        (data['map'] as List?)?.cast<Map<String, dynamic>>() ??
        [
          {"code": "IND", "name": "India", "risk": 78},
          {"code": "DEU", "name": "Germany", "risk": 72},
          {"code": "SGP", "name": "Singapore", "risk": 45},
          {"code": "USA", "name": "United States", "risk": 50},
        ];

    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Regulatory & Market Radar",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                _riskBadge(riskScore),
              ],
            ),
            const SizedBox(height: 18),

            // Bounded line chart (explicit axes)
            SizedBox(
              height: 220,
              child: _riskLineChart(trendValues, trendLabels),
            ),
            const SizedBox(height: 20),

            // // Choropleth map - bounded height
            // SizedBox(height: 330, child: _choroplethMap(mapData)),
            SizedBox(height: 630, child: WorldMap(data: mapData)),

            const SizedBox(height: 18),

            // Alerts
            Text(
              "Regulatory Alerts",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            alerts.isNotEmpty
                ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      alerts.map((a) {
                        final region = a['region'] ?? 'Unknown';
                        final reg = a['regulation'] ?? '';
                        final sev = a['severity'] ?? 'info';
                        return _alertChip("$region: $reg", sev);
                      }).toList(),
                )
                : Text(
                  "✅ No active regulatory alerts detected.",
                  style: TextStyle(color: kTextSecondary),
                ),
          ],
        ),
      ),
    );
  }

  // ================= Line chart builder =================
  Widget _riskLineChart(List<double> values, List<String> labels) {
    final int n = values.length;
    final double minY = 0;
    final double maxY = 100;
    final double minX = 0;
    final double maxX = (n - 1).toDouble();

    final spots = List.generate(
      n,
      (i) => FlSpot(i.toDouble(), values[i].clamp(minY, maxY)),
    );

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          // Only show left & bottom titles; hide top & right
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                final label =
                    (idx >= 0 && idx < labels.length) ? labels[idx] : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    label,
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget:
                  (val, meta) => Text(
                    val.toInt().toString(),
                    style: TextStyle(color: kTextSecondary),
                  ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(bottom: BorderSide(), left: BorderSide()),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: kAccent2,
            belowBarData: BarAreaData(
              show: true,
              color: kAccent2.withOpacity(0.18),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((t) {
                return LineTooltipItem(
                  "${t.y.toStringAsFixed(0)}",
                  TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ================= Choropleth map builder =================

  /// mapData: List<Map<String,dynamic>> with keys: code (ISO_A3), name, risk (0-100)
  Widget _choroplethMap(List<Map<String, dynamic>> mapData) {
    // MapShapeSource: load geojson, map shapeDataField to our primaryValueMapper (ISO_A3 codes)
    final MapShapeSource dataSource = MapShapeSource.asset(
      'world_map.json',
      // The property name in the GeoJSON feature that contains the country code (ISO_A3)
      shapeDataField: 'ISO_A3',
      // number of data items in our list
      dataCount: mapData.length,
      // primaryValueMapper maps our data index to the code that matches shapeDataField values
      primaryValueMapper: (int index) => mapData[index]['code'],
      // value used for color mapping (numeric)
      shapeColorValueMapper: (int index) => mapData[index]['risk'],
      // Define ranges/colors for the choropleth legend
      shapeColorMappers: const <MapColorMapper>[
        MapColorMapper(from: 0, to: 30, color: Colors.green, text: 'Low'),
        MapColorMapper(from: 31, to: 60, color: Colors.orange, text: 'Medium'),
        MapColorMapper(from: 61, to: 100, color: Colors.red, text: 'High'),
      ],
    );

    // The MapShapeLayer will render shapes and automatically use the shapeColorMappers from source.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Constrain height so this widget is safe inside scroll views
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SfMaps(
              layers: <MapLayer>[
                MapShapeLayer(
                  source: dataSource,
                  showDataLabels: false,
                  // show the built-in legend (renders colors from shapeColorMappers)
                  legend: const MapLegend(MapElement.shape),
                  strokeColor: Colors.white,
                  strokeWidth: 0.5,
                  shapeTooltipBuilder: (BuildContext context, int index) {
                    // MapShapeLayer will pass index for the matched shape (index corresponds to
                    // the order of dataCount passed to MapShapeSource)
                    final mapItem = mapData[index];
                    final name = mapItem['name'] ?? mapItem['code'];
                    final risk = mapItem['risk'] ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "$name\nRisk: $risk",
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Optional custom legend UI (in case you want a compact legend)
        Row(
          children: [
            _legendSwatch(Colors.green, 'Low (0-30)'),
            const SizedBox(width: 12),
            _legendSwatch(Colors.orange, 'Medium (31-60)'),
            const SizedBox(width: 12),
            _legendSwatch(Colors.red, 'High (61-100)'),
          ],
        ),
      ],
    );
  }

  Widget _legendSwatch(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ================= Helper widgets =================
Widget _riskBadge(int score) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: (score > 70 ? kAccent1 : kAccent2).withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: score > 70 ? kAccent1 : kAccent2),
  ),
  child: Text(
    "$score / 100",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: score > 70 ? kAccent1 : kAccent2,
      fontSize: 15,
    ),
  ),
);

Widget _alertChip(String text, String severity) {
  Color color;
  switch (severity.toLowerCase()) {
    case "high":
    case "critical":
      color = kAccent1;
      break;
    case "medium":
    case "warning":
      color = Colors.amber[700]!;
      break;
    default:
      color = kAccent2;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      border: Border.all(color: color.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
