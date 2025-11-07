import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

const Color primaryColour = Color(0xFFF7F8F9);
const Color kAccent = Color(0xFFFF6B2C);
const Color kText = Color(0xFF120101);
const double kCardRadius = 14.0;

// ===== Mock Data Models =====
class Startup {
  final String name;
  final String sector;
  final String geography;
  final int regulatoryImpactScore; // 0-100
  final int riskLevel; // 1-5
  Startup({
    required this.name,
    required this.sector,
    required this.geography,
    required this.regulatoryImpactScore,
    required this.riskLevel,
  });
}

class Regulation {
  final String title;
  final String sector;
  final String geography;
  final String severity; // High / Medium / Low
  final List<Startup> affectedStartups;
  Regulation({
    required this.title,
    required this.sector,
    required this.geography,
    required this.severity,
    required this.affectedStartups,
  });
}

class NewsSentiment {
  final DateTime date;
  final double positive;
  final double negative;
  NewsSentiment({
    required this.date,
    required this.positive,
    required this.negative,
  });
}

// ===== Mock Data =====
List<Startup> mockStartups = [
  Startup(
    name: 'FinTechX',
    sector: 'Fintech',
    geography: 'India',
    regulatoryImpactScore: 80,
    riskLevel: 4,
  ),
  Startup(
    name: 'HealthAI',
    sector: 'Health',
    geography: 'USA',
    regulatoryImpactScore: 65,
    riskLevel: 3,
  ),
  Startup(
    name: 'AgroNext',
    sector: 'AgriTech',
    geography: 'India',
    regulatoryImpactScore: 50,
    riskLevel: 2,
  ),
  Startup(
    name: 'EduSmart',
    sector: 'EdTech',
    geography: 'UK',
    regulatoryImpactScore: 70,
    riskLevel: 3,
  ),
];

List<Regulation> mockRegulations = [
  Regulation(
    title: 'Fintech Regulation Q1 2026',
    sector: 'Fintech',
    geography: 'India',
    severity: 'High',
    affectedStartups: [mockStartups[0]],
  ),
  Regulation(
    title: 'Health Data Policy Update',
    sector: 'Health',
    geography: 'USA',
    severity: 'Medium',
    affectedStartups: [mockStartups[1]],
  ),
  Regulation(
    title: 'Agri Subsidy Compliance',
    sector: 'AgriTech',
    geography: 'India',
    severity: 'Low',
    affectedStartups: [mockStartups[2]],
  ),
];

List<NewsSentiment> mockSentiment = List.generate(
  7,
  (i) => NewsSentiment(
    date: DateTime.now().subtract(Duration(days: 6 - i)),
    positive: (50 + i * 5).toDouble(),
    negative: (50 - i * 5).toDouble(),
  ),
);

// ===== Regulatory & Market Radar Page =====
class RegulatoryMarketRadarPage extends StatefulWidget {
  const RegulatoryMarketRadarPage({super.key});

  @override
  State<RegulatoryMarketRadarPage> createState() =>
      _RegulatoryMarketRadarPageState();
}

class _RegulatoryMarketRadarPageState extends State<RegulatoryMarketRadarPage> {
  String selectedSector = 'All';
  String selectedGeography = 'All';
  String selectedSeverity = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredRegulations =
        mockRegulations.where((r) {
          final sectorMatch =
              selectedSector == 'All' || r.sector == selectedSector;
          final geoMatch =
              selectedGeography == 'All' || r.geography == selectedGeography;
          final severityMatch =
              selectedSeverity == 'All' || r.severity == selectedSeverity;
          return sectorMatch && geoMatch && severityMatch;
        }).toList();

    return Scaffold(
      backgroundColor: primaryColour,
      appBar: AppBar(
        backgroundColor: primaryColour,
        elevation: 0,
        title: const Text(
          'Regulatory & Market Radar',
          style: TextStyle(color: kText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlertsPanel(filteredRegulations),
                    const SizedBox(height: 16),
                    _buildTimeline(
                      mockSentiment,
                      filteredRegulations,
                      mockStartups,
                    ),
                    const SizedBox(height: 16),
                    _buildStartupRegulationMatrix(
                      filteredRegulations,
                      mockStartups,
                    ),
                    const SizedBox(height: 16),

                    _buildStackedImpactChart(
                      mockStartups,
                      filteredRegulations,
                      mockSentiment,
                    ),
                    const SizedBox(height: 16),
                    // Add more sections as needed
                    _buildStartupImpactTimeline(
                      mockStartups,
                      filteredRegulations,
                      mockSentiment,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Filters =====
  Widget _buildFilters() {
    return Row(
      children: [
        _buildDropdown(
          'Sector',
          ['All', 'Fintech', 'Health', 'AgriTech', 'EdTech'],
          selectedSector,
          (v) {
            setState(() => selectedSector = v);
          },
        ),
        const SizedBox(width: 12),
        _buildDropdown(
          'Geography',
          ['All', 'India', 'USA', 'UK'],
          selectedGeography,
          (v) {
            setState(() => selectedGeography = v);
          },
        ),
        const SizedBox(width: 12),
        _buildDropdown(
          'Severity',
          ['All', 'High', 'Medium', 'Low'],
          selectedSeverity,
          (v) {
            setState(() => selectedSeverity = v);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kCardRadius),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items:
                  options
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Alerts Panel =====
  Widget _buildAlertsPanel(List<Regulation> regulations) {
    if (regulations.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: regulations.length,
            itemBuilder: (context, index) {
              final reg = regulations[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reg.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Severity: ${reg.severity}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          reg.affectedStartups
                              .map(
                                (s) => Chip(
                                  backgroundColor: Colors.white,
                                  label: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: kText,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== Startup x Regulation Matrix =====
  Widget _buildStartupRegulationMatrix(
    List<Regulation> regulations,
    List<Startup> startups,
  ) {
    if (regulations.isEmpty || startups.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Startup × Regulation Matrix',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Startup')),
              ...regulations.map(
                (r) => DataColumn(
                  label: Container(
                    width: 150,
                    child: Text(
                      r.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
            rows:
                startups.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.name)),
                      ...regulations.map((r) {
                        final affects = r.affectedStartups.contains(s);
                        return DataCell(
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  affects
                                      ? (r.severity == 'High'
                                          ? Colors.red
                                          : r.severity == 'Medium'
                                          ? Colors.orange
                                          : Colors.yellow.shade700)
                                      : Colors.green.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              affects ? r.severity : 'None',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Add these inside the same _RegulatoryMarketRadarPageState class
  // Below _buildStartupRegulationMatrix

  // ===== News + Regulation Timeline =====
  Widget _buildTimeline(
    List<NewsSentiment> sentiments,
    List<Regulation> regulations,
    List<Startup> startups,
  ) {
    // For demo, we’ll mix news + regulations as timeline events
    final events = <Map<String, dynamic>>[];

    // Add regulations
    for (var r in regulations) {
      events.add({
        'type': 'Regulation',
        'title': r.title,
        'date': DateTime.now(), // Mocking today
        'severity': r.severity,
        'affectedStartups': r.affectedStartups.map((s) => s.name).toList(),
      });
    }

    // Add news
    for (var n in sentiments) {
      events.add({
        'type': 'News',
        'title': 'News on ${n.date.month}/${n.date.day}',
        'date': n.date,
        'severity': n.positive >= n.negative ? 'Low' : 'Medium',
        'affectedStartups':
            startups.map((s) => s.name).toList(), // Mock: all affected
      });
    }

    // Sort by date
    events.sort((a, b) => a['date'].compareTo(b['date']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'News & Regulation Timeline',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              Color color;
              switch (e['severity']) {
                case 'High':
                  color = Colors.red;
                  break;
                case 'Medium':
                  color = Colors.orange;
                  break;
                default:
                  color = Colors.green;
              }
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['type'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Affected: ${e['affectedStartups'].join(', ')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${e['date'].month}/${e['date'].day}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== Startup Impact Timeline =====
  Widget _buildStartupImpactTimeline(
    List<Startup> startups,
    List<Regulation> regulations,
    List<NewsSentiment> news,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Startup Impact Timeline',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Column(
          children:
              startups.map((s) {
                final startupRegs =
                    regulations
                        .where((r) => r.affectedStartups.contains(s))
                        .toList();
                final startupNews =
                    news; // For demo, all news affects all startups

                final events = [
                  ...startupRegs.map(
                    (r) => {
                      'type': 'Regulation',
                      'title': r.title,
                      'severity': r.severity,
                      'date': DateTime.now(), // Mock today
                    },
                  ),
                  ...startupNews.map(
                    (n) => {
                      'type': 'News',
                      'title': 'News ${n.date.month}/${n.date.day}',
                      'severity': n.negative > n.positive ? 'High' : 'Low',
                      'date': n.date,
                    },
                  ),
                ];

                // Sort by date with null check
                events.sort((a, b) {
                  final aDate = a['date'] as DateTime?;
                  final bDate = b['date'] as DateTime?;
                  if (aDate == null || bDate == null) return 0;
                  return aDate.compareTo(bDate);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: events.length,
                        itemBuilder: (context, idx) {
                          final e = events[idx];
                          final eDate = e['date'] as DateTime?;
                          Color color;
                          switch (e['severity'] ?? 'Low') {
                            case 'High':
                              color = Colors.red;
                              break;
                            case 'Medium':
                              color = Colors.orange;
                              break;
                            default:
                              color = Colors.green;
                          }
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Column(
                              children: [
                                Tooltip(
                                  message: '${e['type']}: ${e['title']}',
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  eDate != null
                                      ? '${eDate.month}/${eDate.day}'
                                      : '',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }

  // ===== Stacked Regulatory Impact Score Chart =====
  Widget _buildStackedImpactChart(
    List<Startup> startups,
    List<Regulation> regulations,
    List<NewsSentiment> sentiments,
  ) {
    // For demo, we’ll mock cumulative impact:
    // regulationImpact = number of regulations affecting startup * 10
    // newsImpact = sentiment negative > positive ? 10 : 5
    final barGroups =
        startups.asMap().entries.map((e) {
          final regImpact =
              regulations
                  .where((r) => r.affectedStartups.contains(e.value))
                  .length *
              10;
          final newsImpact =
              sentiments.last.negative > sentiments.last.positive ? 10 : 5;
          final baseline = e.value.riskLevel * 10;

          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: baseline.toDouble(),
                color: Colors.green.shade400,
                width: 24,
              ),
              BarChartRodData(
                toY: (baseline + regImpact).toDouble(),
                color: Colors.orange,
                width: 24,
              ),
              BarChartRodData(
                toY: (baseline + regImpact + newsImpact).toDouble(),
                color: Colors.red,
                width: 24,
              ),
            ],
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
              'Stacked Regulatory Impact Score',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          int idx = value.toInt();
                          if (idx < startups.length)
                            return Text(startups[idx].name);
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 20),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                LegendDot(color: Colors.green, label: 'Baseline Risk'),
                SizedBox(width: 12),
                LegendDot(color: Colors.orange, label: 'Regulation Impact'),
                SizedBox(width: 12),
                LegendDot(color: Colors.red, label: 'News Impact'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Legend Dot Widget =====
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
