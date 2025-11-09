import 'package:flutter/material.dart';
import 'package:lumora/startupProfile/DashboardAPI.dart';
import 'package:lumora/startupProfile/ProfileHeader.dart';

class DashboardScreen extends StatefulWidget {
  final String startupId;
  const DashboardScreen({super.key, required this.startupId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StartupDetails? startup;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStartupDetails();
  }

  Future<void> _loadStartupDetails() async {
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Error loading startup details:\n$error",
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final s = startup!;

    // ✅ Map backend data to ProfileHeader expected format
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

    return Scaffold(
      appBar: AppBar(
        title: Text(s.identity.companyName),
        backgroundColor: const Color(0xFFFF6B2C),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌟 Header with startup info
            ProfileHeader(data: profileData),

            const SizedBox(height: 20),

            // 🌟 Quick Metrics Overview
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Key Metrics",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow("ARR", s.metrics.arr),
                    _buildMetricRow("Growth Rate", s.metrics.growthRate),
                    _buildMetricRow("CAC", s.metrics.cac),
                    _buildMetricRow("LTV", s.metrics.ltv),
                    _buildMetricRow("CAC/LTV Ratio", s.metrics.cacLtvRatio),
                    _buildMetricRow("Runway", s.metrics.runwayMonths),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🌟 AI Executive Summary
            Card(
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Executive Summary",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.aiAnalysis.executiveSummary,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Recommendation: ${s.aiAnalysis.recommendation}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      "AI Score: ${s.aiAnalysis.score.toStringAsFixed(0)} / 100",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            value.isNotEmpty ? value : "—",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
