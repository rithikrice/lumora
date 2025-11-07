import 'package:flutter/material.dart';
import 'package:lumora/aiInsights/AIInsights.dart';
import 'package:lumora/homepage/components/TopNavBar.dart';
import 'package:lumora/homepage/theme.dart';
import 'package:lumora/startupProfile/ActivityTimeline.dart';
import 'package:lumora/startupProfile/DashboardAPI.dart';
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
  Dashboard? dashboard;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardApi.fetchDashboard(widget.startupId);
      setState(() {
        dashboard = data;
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
      return Center(child: Text("Error loading dashboard:\n$error"));
    }

    // Map backend data to ProfileHeader
    final profileData = {
      'name': dashboard!.companyProfile.name,
      'pitch': dashboard!.companyProfile.description,
      'meta':
          "${dashboard!.companyProfile.industry} • ${dashboard!.companyProfile.stage} • ${dashboard!.companyProfile.headquarters}",
      'founded': dashboard!.companyProfile.founded.toString(),
      'revenue': dashboard!.companyProfile.revenue,
      'funding': dashboard!.companyProfile.fundingRaised,
      'runway': dashboard!.companyProfile.runway,
    };

    switch (section) {
      case "Company Profile":
        return SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(data: profileData),
              SizedBox(height: 24),
              // const FounderTeam(),
              FounderTeam(
                data: {
                  'founders':
                      dashboard!.foundingTeam
                          .where(
                            (f) => f.name != null && f.name!.isNotEmpty,
                          ) // Filter only members with names
                          .map(
                            (f) => {
                              'name': f.name!, // We filtered nulls above
                              'role': f.role ?? 'CEO',
                              'initials':
                                  f.name!
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join(),
                              'color': 'accent1',
                            },
                          )
                          .toList(),
                  'metrics': {
                    'integrityScore':
                        dashboard!.foundingTeam.any(
                              (f) => f.integrityScore != null,
                            )
                            ? "${dashboard!.foundingTeam.firstWhere((f) => f.integrityScore != null).integrityScore!.toStringAsFixed(0)}%"
                            : '87%',
                    'culturalFit':
                        dashboard!.foundingTeam.any(
                              (f) => f.culturalFit != null,
                            )
                            ? dashboard!.foundingTeam
                                .firstWhere((f) => f.culturalFit != null)
                                .culturalFit!
                            : 'High Alignment',
                  },
                },
              ),
              SizedBox(height: 24),
              ExecutiveSummary(
                data: {
                  'bullets': dashboard!.executiveSummary,
                  'evidence': [
                    "Analysis based on data",
                    "Domain checks",
                    "Market evidence",
                  ],
                },
              ),
            ],
          ),
        );

      case "Investment Highlights":
        return SingleChildScrollView(
          child: Column(
            children: [
              InvestmentHighlightsPage(
                data: {
                  'currentAsk': dashboard!.investmentHighlights.currentAsk,
                  'useOfFunds': dashboard!.investmentHighlights.useOfFunds,
                  'exitStrategy': dashboard!.investmentHighlights.exitStrategy,
                  'keyStrengths': dashboard!.investmentHighlights.keyStrengths,
                },
              ),
              RegulatoryRadar(
                data: {
                  'alerts':
                      dashboard!.marketRegulation.alerts
                          .map(
                            (a) => {
                              'region': a.region,
                              'regulation': a.regulation,
                              'severity': a.severity,
                            },
                          )
                          .toList(),
                  'risk_score': dashboard!.marketRegulation.riskScore,
                },
              ),
            ],
          ),
        );

      case "KPI BenchMarks":
        return SingleChildScrollView(
          child: Column(
            children: [
              KpiBenchmarksPage(
                data: {
                  'kpis':
                      dashboard!.kpis
                          .map(
                            (k) => {
                              'title': k.title,
                              'value': k.value,
                              'note': k.note,
                            },
                          )
                          .toList(),
                  'alert': dashboard!.kpiAlert,
                },
              ),

              const SizedBox(height: 12),
              RisksRedFlags(),
            ],
          ),
        );

      case "Notifications":
        return const NotificationsPage();
      case "Activity Timeline":
        return StartupTimeline();
      case "AI Insights":
        return const AiInsightsDashboard();
      case "Growth Simulations":
        // fix the error here
        return GrowthSimulation(startupId: widget.startupId);
      default:
        return Center(
          child: Text("Coming soon: $section", style: bodyStyle(16)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color kBackground = const Color.fromARGB(255, 255, 150, 69);
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavBar(),
            Expanded(
              child: Row(
                children: [
                  // Sidebar
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
