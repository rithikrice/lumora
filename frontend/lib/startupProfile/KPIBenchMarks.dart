import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// 🎨 Color palette
const Color kAccent1 = Color(0xFFFF6B2C);
const Color kAccent2 = Color(0xFF3E2CFF);
const Color kBackground = Color(0xFFF8F9FC);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class KpiBenchmarksPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const KpiBenchmarksPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Prefer backend KPIs but if they are all empty/zero, use the nicer fallback set
    var kpis = data['kpis'] as List<dynamic>? ?? _fallbackKpis;
    bool _hasAnyMeaningfulValue(List<dynamic> list) {
      for (final k in list) {
        if (k == null) continue;
        final v = k['value'];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isEmpty) continue;
        // formatted values
        if (s.contains('\$') ||
            s.contains('%') ||
            s.toLowerCase().contains('mo'))
          return true;
        // numeric > 0
        final n = double.tryParse(s.replaceAll(RegExp('[^0-9\.]'), ''));
        if (n != null && n > 0) return true;
      }
      return false;
    }

    if (!(_hasAnyMeaningfulValue(kpis))) {
      kpis = _fallbackKpis;
    }
    final String alert =
        data['alert'] ?? "Churn rate slightly above industry average.";

    return Container(
      color: kBackground,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Card(
          elevation: 10,
          color: kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📈 KPI Benchmarks",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kAccent1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: kAccent1,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Q3 FY25",
                            style: GoogleFonts.inter(
                              color: kAccent1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔹 KPI cards grid
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children:
                      kpis.map((k) {
                        // Defensive extraction: backend may return null/missing fields
                        final String title = (k?['title'] ?? 'N/A').toString();
                        final String rawValue = (k?['value'] ?? '').toString();
                        final String note = (k?['note'] ?? '').toString();
                        final String trend = (k?['trend'] ?? '').toString();
                        final Color color =
                            (k != null && k['color'] is Color)
                                ? k['color'] as Color
                                : kAccent1;

                        // Try to derive a numeric fallback from peer data (values are in millions for ARR/GMV/TAM)
                        final double? fallbackMetric = _getPeerMetricForTitle(
                          title,
                        );
                        final String displayValue = _formatKpiDisplay(
                          title,
                          rawValue,
                          fallbackMetric,
                        );

                        return _kpiCard(
                          title,
                          displayValue,
                          note,
                          trend,
                          color,
                        );
                      }).toList(),
                ),

                const SizedBox(height: 40),

                // 🔹 Peer comparison chart
                Text(
                  "Peer Comparison",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: SfCartesianChart(
                    backgroundColor: Colors.transparent,
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: GoogleFonts.inter(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: MajorGridLines(
                        width: 1,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      labelStyle: GoogleFonts.inter(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y',
                      textStyle: GoogleFonts.inter(fontSize: 12),
                      color: Colors.white,
                      borderColor: kAccent1,
                      borderWidth: 1,
                    ),
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      textStyle: GoogleFonts.inter(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    series: <CartesianSeries<_PeerData, String>>[
                      ColumnSeries<_PeerData, String>(
                        dataSource: _peerData,
                        xValueMapper: (_PeerData p, _) => p.category,
                        yValueMapper: (_PeerData p, _) => p.value,
                        name: 'Your Startup',
                        color: kAccent2,
                        width: 0.4,
                        spacing: 0.2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      ColumnSeries<_PeerData, String>(
                        dataSource: _peerDataCompetitors,
                        xValueMapper: (_PeerData p, _) => p.category,
                        yValueMapper: (_PeerData p, _) => p.value,
                        name: 'Peer Avg',
                        color: kAccent1.withOpacity(0.7),
                        width: 0.4,
                        spacing: 0.2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Try to find a numeric metric value for a KPI title from the peer data
  double? _getPeerMetricForTitle(String title) {
    String normalize(String s) =>
        s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final String key = normalize(title);

    // First try exact matches in primary peer data
    for (final p in _peerData) {
      if (normalize(p.category) == key && p.value > 0) return p.value;
    }

    // Try competitors list
    for (final p in _peerDataCompetitors) {
      if (normalize(p.category) == key && p.value > 0) return p.value;
    }

    // Try partial matches (category contains title or vice versa)
    for (final p in _peerData) {
      final np = normalize(p.category);
      if ((np.contains(key) || key.contains(np)) && p.value > 0) return p.value;
    }
    for (final p in _peerDataCompetitors) {
      final np = normalize(p.category);
      if ((np.contains(key) || key.contains(np)) && p.value > 0) return p.value;
    }

    // If no single non-zero found, try averaging peer + competitor values for that category
    double sum = 0;
    int count = 0;
    for (final p in _peerData) {
      if (normalize(p.category) == key) {
        sum += p.value;
        count++;
      }
    }
    for (final p in _peerDataCompetitors) {
      if (normalize(p.category) == key) {
        sum += p.value;
        count++;
      }
    }
    if (count > 0) return sum / count;

    return null;
  }

  // Format display string for KPI card. Uses rawValue if present, otherwise falls back to numeric metric.
  String _formatKpiDisplay(
    String title,
    String rawValue,
    double? fallbackMetric,
  ) {
    final String t = title.toLowerCase();
    final String rv = rawValue.trim();

    // If backend provided a meaningful formatted value (contains $ or % or 'mo'), use it
    if (rv.isNotEmpty &&
        (rv.contains('\$') ||
            rv.contains('%') ||
            rv.toLowerCase().contains('mo'))) {
      return rv;
    }

    // If backend provided a plain numeric string, try to parse and format according to KPI type
    if (rv.isNotEmpty) {
      final numeric = double.tryParse(rv.replaceAll(RegExp('[^0-9\.]'), ''));
      if (numeric != null && numeric > 0) {
        if (t == 'arr' || t == 'gmv' || t == 'tam') {
          // assume number given in millions
          return '\$${numeric.toStringAsFixed(1)}M';
        }
        if (t == 'cac') return '\$${numeric.toStringAsFixed(0)}';
        if (t == 'churn') return '${numeric.toStringAsFixed(1)}%';
        if (t == 'runway') return '${numeric.toStringAsFixed(0)} mo';
        return numeric.toString();
      }
    }

    // Fallback: derive from peer metric if available
    if (fallbackMetric != null) {
      if (t == 'arr' || t == 'gmv' || t == 'tam')
        return '\$${fallbackMetric.toStringAsFixed(1)}M';
      if (t == 'cac') return '\$${fallbackMetric.toStringAsFixed(0)}';
      if (t == 'churn') return '${fallbackMetric.toStringAsFixed(1)}%';
      if (t == 'runway') return '${fallbackMetric.toStringAsFixed(0)} mo';
      return fallbackMetric.toString();
    }

    // Last resort
    return 'N/A';
  }

  // 🔸 KPI Card
  Widget _kpiCard(
    String title,
    String value,
    String note,
    String trend,
    Color color,
  ) {
    final bool isPositive = trend.contains("↑");
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
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
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Simple Heatmap representation
  Widget _buildHeatmap() {
    final List<List<int>> heatData = [
      [20, 40, 60, 80, 100],
      [35, 55, 75, 85, 95],
      [10, 30, 50, 70, 90],
    ];

    return Column(
      children:
          heatData
              .map(
                (row) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      row
                          .map(
                            (v) => Container(
                              margin: const EdgeInsets.all(4),
                              width: 40,
                              height: 25,
                              decoration: BoxDecoration(
                                color: _getHeatColor(v),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          )
                          .toList(),
                ),
              )
              .toList(),
    );
  }

  Color _getHeatColor(int value) {
    if (value < 30) return Colors.green.withOpacity(0.8);
    if (value < 60) return Colors.orange.withOpacity(0.8);
    return Colors.red.withOpacity(0.8);
  }

  // 🔹 Fallback KPI data — realistic placeholder values
  static const List<Map<String, dynamic>> _fallbackKpis = [
    {
      'title': 'ARR',
      // Annual Recurring Revenue
      'value': '\$12,000,000',
      'note': '40% QoQ growth (annualized)',
      'trend': '↑ 40%',
      'color': kAccent2,
    },
    {
      'title': 'CAC',
      // Customer Acquisition Cost
      'value': '\$120',
      'note': 'Lower than peer median',
      'trend': '↓ 8%',
      'color': kAccent1,
    },
    {
      'title': 'Churn',
      // Monthly churn rate
      'value': '4.0%',
      'note': 'Slightly above fintech benchmark',
      'trend': '↑ 0.5%',
      'color': kAccent1,
    },
    {
      'title': 'Runway',
      // Runway in months
      'value': '18 mo',
      'note': 'Cash runway at current burn',
      'trend': '↔',
      'color': kAccent2,
    },
    {
      'title': 'TAM',
      // Total Addressable Market
      'value': '\$2.5B',
      'note': 'Market opportunity (TAM)',
      'trend': '↑',
      'color': kAccent2,
    },
    {
      'title': 'GMV',
      // Gross Merchandise Value
      'value': '\$45,000,000',
      'note': '60% YoY growth',
      'trend': '↑ 60%',
      'color': kAccent1,
    },
  ];
}

// 🔸 Dummy data for Peer Comparison
class _PeerData {
  final String category;
  final double value;
  _PeerData(this.category, this.value);
}

final List<_PeerData> _peerData = [
  _PeerData('ARR', 12),
  _PeerData('CAC', 8),
  _PeerData('Churn', 4),
  _PeerData('GMV', 45),
  _PeerData('Runway', 18),
];

final List<_PeerData> _peerDataCompetitors = [
  _PeerData('ARR', 10),
  _PeerData('CAC', 9),
  _PeerData('Churn', 3.2),
  _PeerData('GMV', 38),
  _PeerData('Runway', 16),
];
