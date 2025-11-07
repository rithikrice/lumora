import 'package:flutter/material.dart';
import 'package:lumora/startupProfile/DashboardAPI.dart';
import 'package:lumora/startupProfile/ProfileHeader.dart'; // your DashboardApi & model classes

class DashboardScreen extends StatefulWidget {
  final String startupId;
  const DashboardScreen({super.key, required this.startupId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text("Error loading dashboard:\n$error")),
      );
    }

    // Map backend data to ProfileHeader expected format
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Startup Dashboard"),
        backgroundColor: const Color(0xFFFF6B2C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileHeader(data: profileData),
            const SizedBox(height: 20),
            // You can add other sections here, like KPIs, Team, etc.
          ],
        ),
      ),
    );
  }
}
