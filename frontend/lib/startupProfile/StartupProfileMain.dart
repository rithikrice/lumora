import 'package:flutter/material.dart';
import 'package:lumora/aiInsights/AIInsights.dart';
import 'package:lumora/homepage/components/TopNavBar.dart';
import 'package:lumora/homepage/theme.dart';
import 'package:lumora/startupProfile/ActivityTimeline.dart';
import 'package:lumora/startupProfile/DashboardAPI.dart'; // contains StartupDetailsApi
import 'package:lumora/startupProfile/ExecutiveSummary.dart';
import 'package:lumora/startupProfile/FounderTeam.dart';
import 'package:lumora/startupProfile/GrowthSimulation.dart';
import 'package:lumora/startupProfile/InvestmentHighlights.dart';
import 'package:lumora/startupProfile/KPIBenchMarks.dart';
import 'package:lumora/startupProfile/Notifications.dart';
import 'package:lumora/startupProfile/ProfileHeader.dart';
import 'package:lumora/startupProfile/RedFlags.dart';
import 'package:lumora/startupProfile/Regulatory.dart';
import 'package:lumora/startupProfile/SideNavBar.dart';

class StartupProfilePage extends StatefulWidget {
  final String startupId;

  const StartupProfilePage({super.key, required this.startupId});

  @override
  State<StartupProfilePage> createState() => _StartupProfilePageState();
}

class _StartupProfilePageState extends State<StartupProfilePage> {
  String _activeSection = "Company Profile";
  StartupDetails? startup;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStartup();
  }

  Future<void> _loadStartup() async {
    try {
      final data = await StartupDetailsApi.fetchStartupDetails(
        widget.startupId,
      );
      setState(() {
        startup = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget _buildSection(String section) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text("Error loading startup details:\n$error"));
    }

    final s = startup!; // shorthand

    // ✅ Map backend data to ProfileHeader
    final profileData = {
      'name': s.identity.name,
      'pitch': s.business.solution,
      'meta':
          "${s.identity.sector} • ${s.identity.stage} • ${s.identity.location}",
      'founded': s.identity.foundedYear,
      'revenue': s.metrics.arr,
      'funding': s.fundraising.raisedToDate,
      'runway': s.metrics.runwayMonths,
      'valuation': s.fundraising.valuation,
      'website': s.identity.website,
    };

    switch (section) {
      // ------------------ COMPANY PROFILE ------------------
      case "Company Profile":
        return SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(data: profileData),
              const SizedBox(height: 24),

              // Founding team
              FounderTeam(
                data: {
                  'founders':
                      s.founders
                          .map(
                            (name) => {
                              'name': name,
                              'role': 'Founder',
                              'initials':
                                  name
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join(),
                              'color': 'accent1',
                            },
                          )
                          .toList(),
                  'metrics': {
                    'integrityScore': '87%',
                    'culturalFit': 'High Alignment',
                  },
                },
              ),
              const SizedBox(height: 24),

              // Executive summary (AI)
              ExecutiveSummary(
                data: {
                  'bullets': [
                    s.aiAnalysis.executiveSummary,
                    "Recommendation: ${s.aiAnalysis.recommendation}",
                    "Score: ${s.aiAnalysis.score.toStringAsFixed(0)} / 100",
                  ],
                  'evidence': [
                    "AI insights generated from pitch deck & checklist",
                    "Market & financial validation",
                    "Regulatory and risk analysis",
                  ],
                },
              ),
            ],
          ),
        );

      // ------------------ INVESTMENT HIGHLIGHTS ------------------
      case "Investment Highlights":
        return SingleChildScrollView(
          child: Column(
            children: [
              InvestmentHighlightsPage(
                data: {
                  'currentAsk': s.fundraising.ask,
                  'useOfFunds': s.fundraising.highlights.join("\n"),
                  'exitStrategy': "Not specified",
                  'keyStrengths': [
                    "Valuation: ${s.fundraising.valuation}",
                    "Raised: ${s.fundraising.raisedToDate}",
                    "Recommendation: ${s.aiAnalysis.recommendation}",
                  ],
                },
              ),
              const SizedBox(height: 24),
              RegulatoryRadar(
                data: {
                  'alerts':
                      s.aiAnalysis.risks
                          .map(
                            (r) => {
                              'region': r.type,
                              'regulation': r.description,
                              'severity': r.severity,
                            },
                          )
                          .toList(),
                  'risk_score': s.aiAnalysis.score.toInt(),
                },
              ),
            ],
          ),
        );

      // ------------------ KPI BENCHMARKS ------------------
      case "KPI BenchMarks":
        return SingleChildScrollView(
          child: Column(
            children: [
              KpiBenchmarksPage(
                data: {
                  'kpis': [
                    {
                      'title': 'ARR',
                      'value': s.metrics.arr,
                      'note': 'Annual Recurring Revenue',
                    },
                    {
                      'title': 'Growth Rate',
                      'value': s.metrics.growthRate,
                      'note': 'YoY growth',
                    },
                    {
                      'title': 'CAC',
                      'value': s.metrics.cac,
                      'note': 'Customer Acquisition Cost',
                    },
                    {
                      'title': 'LTV',
                      'value': s.metrics.ltv,
                      'note': 'Lifetime Value',
                    },
                    {
                      'title': 'CAC/LTV Ratio',
                      'value': s.metrics.cacLtvRatio,
                      'note': 'Efficiency',
                    },
                    {
                      'title': 'Runway',
                      'value': s.metrics.runwayMonths,
                      'note': 'Months remaining',
                    },
                  ],
                  'alert': s.aiAnalysis.recommendation,
                },
              ),
              const SizedBox(height: 12),
              RisksRedFlags(
                // data: {
                //   'risks': s.aiAnalysis.risks
                //       .map((r) => {
                //             'type': r.type,
                //             'severity': r.severity,
                //             'description': r.description,
                //             'mitigation': r.mitigation,
                //           })
                //       .toList(),
                // },
              ),
            ],
          ),
        );

      // ------------------ MARKET & TRACTION ------------------
      case "Market & Traction":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Market Highlights", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ...s.market.highlights
                  .map(
                    (h) => ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(h, style: bodyStyle(14)),
                    ),
                  )
                  .toList(),
              const Divider(),
              Text("Traction Highlights", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ...s.traction.highlights
                  .map(
                    (h) => ListTile(
                      leading: const Icon(Icons.bolt),
                      title: Text(h, style: bodyStyle(14)),
                    ),
                  )
                  .toList(),
            ],
          ),
        );

      // ------------------ NOTIFICATIONS ------------------
      case "Notifications":
        return const NotificationsPage();

      // ------------------ ACTIVITY TIMELINE ------------------
      case "Activity Timeline":
        return StartupTimeline();

      // ------------------ AI INSIGHTS ------------------
      case "AI Insights":
        return AiInsightsDashboard(startupId: widget.startupId);

      // ------------------ GROWTH SIMULATIONS ------------------
      case "Growth Simulations":
        return GrowthSimulation(startupId: widget.startupId);

      // ------------------ DEFAULT ------------------
      default:
        return Center(
          child: Text("Coming soon: $section", style: bodyStyle(16)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBackground = Color.fromARGB(255, 255, 150, 69);
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavBar(),
            Expanded(
              child: Row(
                children: [
                  SidebarNav(
                    activeSection: _activeSection,
                    onSelect: (s) => setState(() => _activeSection = s),
                    startupId: widget.startupId,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildSection(_activeSection),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
