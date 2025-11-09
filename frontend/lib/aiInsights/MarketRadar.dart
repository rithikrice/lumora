import 'package:flutter/material.dart';

class _Startup {
  final String name;
  final String sector;
  final String geography;
  final int regulatoryImpactScore;
  final int riskLevel;
  const _Startup({
    required this.name,
    required this.sector,
    required this.geography,
    required this.regulatoryImpactScore,
    required this.riskLevel,
  });
}

class _Regulation {
  final String title;
  final String sector;
  final String geography;
  final String severity;
  final List<String> affectedStartups;
  const _Regulation({
    required this.title,
    required this.sector,
    required this.geography,
    required this.severity,
    required this.affectedStartups,
  });
}

class _NewsSentiment {
  final DateTime date;
  final double positive;
  final double negative;
  const _NewsSentiment({
    required this.date,
    required this.positive,
    required this.negative,
  });
}

class RegulatoryMarketRadarPage extends StatefulWidget {
  const RegulatoryMarketRadarPage({super.key});

  @override
  State<RegulatoryMarketRadarPage> createState() =>
      _RegulatoryMarketRadarPageState();
}

class _RegulatoryMarketRadarPageState extends State<RegulatoryMarketRadarPage> {
  // ---- Filters ----
  String selectedSector = 'All';
  String selectedGeography = 'All';
  String selectedSeverity = 'All';

  Color kAccent = Color(0xFFFF6B2C);
  Color kAccentBlue = Color.fromARGB(255, 62, 44, 255);
  Color kBackground = Color(0xFFFDFBF9);
  Color kCard = Colors.white;
  Color kTextPrimary = Color(0xFF0D1724);
  Color kTextSecondary = Color(0xFF6B7280);
  double kCardRadius = 16;

  // ---- Mock Models (kept local so copying this class works immediately) ----

  // ---- Mock data (visible on the UI) ----
  final List<_Startup> mockStartups = const [
    _Startup(
      name: 'FinTechX',
      sector: 'Fintech',
      geography: 'India',
      regulatoryImpactScore: 80,
      riskLevel: 4,
    ),
    _Startup(
      name: 'HealthAI',
      sector: 'Health',
      geography: 'USA',
      regulatoryImpactScore: 65,
      riskLevel: 3,
    ),
    _Startup(
      name: 'AgroNext',
      sector: 'AgriTech',
      geography: 'India',
      regulatoryImpactScore: 50,
      riskLevel: 2,
    ),
    _Startup(
      name: 'EduSmart',
      sector: 'EdTech',
      geography: 'UK',
      regulatoryImpactScore: 70,
      riskLevel: 3,
    ),
  ];

  late final List<_Regulation> mockRegulations = [
    _Regulation(
      title: 'Fintech Regulation Q1 2026',
      sector: 'Fintech',
      geography: 'India',
      severity: 'High',
      affectedStartups: ['FinTechX'],
    ),
    _Regulation(
      title: 'Health Data Policy Update',
      sector: 'Health',
      geography: 'USA',
      severity: 'Medium',
      affectedStartups: ['HealthAI'],
    ),
    _Regulation(
      title: 'Agri Subsidy Compliance',
      sector: 'AgriTech',
      geography: 'India',
      severity: 'Low',
      affectedStartups: ['AgroNext'],
    ),
    // extra regulation to show matrix scrolling
    _Regulation(
      title: 'Global Data Privacy Draft',
      sector: 'Fintech',
      geography: 'Global',
      severity: 'Medium',
      affectedStartups: ['FinTechX', 'HealthAI'],
    ),
  ];

  late final List<_NewsSentiment> mockSentiment = List.generate(
    7,
    (i) => _NewsSentiment(
      date: DateTime.now().subtract(Duration(days: 6 - i)),
      positive: (50 + i * 5).toDouble(),
      negative: (50 - i * 5).toDouble(),
    ),
  );

  // ---- Helpers ----
  Color _severityColor(String? sev) {
    switch (sev) {
      case 'High':
        return Colors.red.shade600;
      case 'Medium':
        return Colors.orange.shade600;
      case 'Low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  // ---- Build ----
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 251, 209, 189),
              Colors.white,
              const Color.fromARGB(255, 251, 209, 189),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      color: Colors.black,
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 48),
                    Text(
                      'Regulatory Market Radar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 20),
                _buildFilterBar(),
                const SizedBox(height: 20),
                _sectionHeader('Alerts'),
                const SizedBox(height: 8),
                _buildAlertsPanel(filteredRegulations),
                const SizedBox(height: 22),

                _sectionHeader('Startup × Regulation Heat Map'),
                const SizedBox(height: 8),
                _buildCustomMatrix(filteredRegulations, mockStartups),
                const SizedBox(height: 22),

                _sectionHeader('News & Regulation Timeline'),
                const SizedBox(height: 8),
                _buildTimeline(filteredRegulations),
                const SizedBox(height: 22),

                _sectionHeader('Startup Impact Timeline'),
                const SizedBox(height: 8),
                _buildStartupImpactTimeline(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: kTextPrimary,
    ),
  );

  // ---- Filters bar (pill-style) ----
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _compactDropdown(
            'Sector',
            ['All', 'Fintech', 'Health', 'AgriTech', 'EdTech'],
            selectedSector,
            (v) => setState(() => selectedSector = v),
          ),
          const SizedBox(width: 12),
          _compactDropdown(
            'Geography',
            ['All', 'India', 'USA', 'UK'],
            selectedGeography,
            (v) => setState(() => selectedGeography = v),
          ),
          const SizedBox(width: 12),
          _compactDropdown(
            'Severity',
            ['All', 'High', 'Medium', 'Low'],
            selectedSeverity,
            (v) => setState(() => selectedSeverity = v),
          ),
          const Spacer(),
          // small legend / quick actions
          ElevatedButton.icon(
            icon: const Icon(Icons.filter_list, size: 16),
            label: const Text('Reset', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                selectedSector = 'All';
                selectedGeography = 'All';
                selectedSeverity = 'All';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _compactDropdown(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items:
                  options
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            o,
                            style: TextStyle(color: kTextPrimary, fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Alerts panel (keeps mock data visible) ----
  Widget _buildAlertsPanel(List<_Regulation> regulations) {
    if (regulations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
        child: Text(
          'No alerts for selected filters.',
          style: TextStyle(color: kTextSecondary),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: regulations.length,
        itemBuilder: (context, idx) {
          final r = regulations[idx];
          final color = _severityColor(r.severity);
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // keep simple: show details bottom sheet
                showModalBottomSheet(
                  context: context,
                  backgroundColor: kCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  builder:
                      (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sector: ${r.sector}',
                              style: TextStyle(color: kTextSecondary),
                            ),
                            Text(
                              'Geography: ${r.geography}',
                              style: TextStyle(color: kTextSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children:
                                  r.affectedStartups
                                      .map((s) => Chip(label: Text(s)))
                                      .toList(),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccent,
                                ),
                                child: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                      ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 14),
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kCardRadius),
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.severity,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.geography,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          r.affectedStartups
                              .map(
                                (s) => Chip(
                                  label: Text(
                                    s,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Timeline ----
  Widget _buildTimeline(List<_Regulation> regulations) {
    // Build events mixing mockSentiment and regulations
    final events = <Map<String, dynamic>>[];
    for (var r in regulations) {
      events.add({
        'type': 'Regulation',
        'title': r.title,
        'date': DateTime.now(),
        'severity': r.severity,
      });
    }
    for (var n in mockSentiment) {
      events.add({
        'type': 'News',
        'title': 'News — ${n.date.month}/${n.date.day}',
        'date': n.date,
        'severity': n.positive >= n.negative ? 'Low' : 'Medium',
      });
    }
    events.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final e = events[i];
          final color = _severityColor(e['severity']);
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['type'],
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(e['date'] as DateTime).month}/${(e['date'] as DateTime).day}',
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Custom matrix: startup rows with regulation "columns" as scrollable chips/cards ----
  Widget _buildCustomMatrix(
    List<_Regulation> regulations,
    List<_Startup> startups,
  ) {
    if (startups.isEmpty || regulations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
        child: Text('No data', style: TextStyle(color: kTextSecondary)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER ROW =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Startup',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          regulations.map((r) {
                            return SizedBox(
                              width: 240,
                              child: Container(
                                margin: const EdgeInsets.only(right: 14),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  r.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.6),

          // ===== BODY ROWS =====
          Column(
            children:
                startups.map((s) {
                  final rowRegs = regulations;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade100,
                          width: 0.7,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ==== STARTUP DETAILS ====
                        SizedBox(
                          width: 200,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: kAccent.withOpacity(0.12),
                                child: Text(
                                  s.name
                                      .splitMapJoin(
                                        RegExp(r'[A-Z]'),
                                        onMatch: (m) => m.group(0) ?? '',
                                        onNonMatch: (_) => '',
                                      )
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: kAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kTextPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${s.sector} • ${s.geography}',
                                      style: TextStyle(
                                        color: kTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==== REGULATION CELLS ====
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  rowRegs.map((r) {
                                    final affects = r.affectedStartups.contains(
                                      s.name,
                                    );
                                    final sev = affects ? r.severity : 'None';
                                    final color =
                                        affects
                                            ? _severityColor(r.severity)
                                            : Colors.grey.shade300;
                                    return SizedBox(
                                      width: 240,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          width: 180,
                                          decoration: BoxDecoration(
                                            color:
                                                affects
                                                    ? color.withOpacity(0.1)
                                                    : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  affects
                                                      ? color.withOpacity(0.25)
                                                      : Colors.grey.shade200,
                                            ),
                                            boxShadow: [
                                              if (affects)
                                                BoxShadow(
                                                  color: color.withOpacity(
                                                    0.08,
                                                  ),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: kTextPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 8,
                                                    width: 8,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    sev,
                                                    style: TextStyle(
                                                      color:
                                                          affects
                                                              ? kTextPrimary
                                                              : kTextSecondary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    affects ? 'Affected' : '—',
                                                    style: TextStyle(
                                                      color: kTextSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ---- Startup impact timeline (simple, visible) ----
  Widget _buildStartupImpactTimeline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        children:
            mockStartups.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          ...List.generate(7, (i) {
                            // determine a mock severity from news & regs to color the dot
                            final n = mockSentiment[i];
                            final severity =
                                n.negative > n.positive ? 'High' : 'Low';
                            final color = _severityColor(severity);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${n.date.month}/${n.date.day}',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
