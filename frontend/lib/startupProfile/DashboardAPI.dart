import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lumora/config/ApiConfig.dart';

class Dashboard {
  final CompanyProfile companyProfile;
  final List<String> executiveSummary;
  final KpiBenchmarks kpiBenchmarks;
  final InvestmentHighlights investmentHighlights;
  final List<FoundingTeamMember> foundingTeam;
  final List<RedFlag> redFlags;
  final MarketRegulation marketRegulation;
  final List<AiInsight> aiInsights;
  final double score;
  final String recommendation;
  final String? videoId;
  final List<Kpi> kpis;
  final String? kpiAlert;

  Dashboard({
    required this.companyProfile,
    required this.executiveSummary,
    required this.kpiBenchmarks,
    required this.investmentHighlights,
    required this.foundingTeam,
    required this.redFlags,
    required this.marketRegulation,
    required this.aiInsights,
    required this.score,
    required this.recommendation,
    required this.videoId,
    required this.kpis,
    this.kpiAlert,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final kpiBenchmarks = KpiBenchmarks.fromJson(json['kpi_benchmarks']);

    // ✅ Flatten KPI metrics into a simple list
    final List<Kpi> kpisList = [
      Kpi(
        title: "ARR",
        value: kpiBenchmarks.arr.value,
        note: kpiBenchmarks.arr.status,
      ),
      Kpi(
        title: "CAC",
        value: kpiBenchmarks.cac.value,
        note: kpiBenchmarks.cac.status,
      ),
      Kpi(
        title: "Churn",
        value: kpiBenchmarks.churn.value,
        note: kpiBenchmarks.churn.status,
      ),
      Kpi(
        title: "Runway",
        value: kpiBenchmarks.runway.value,
        note: kpiBenchmarks.runway.status,
      ),
      Kpi(
        title: "TAM",
        value: kpiBenchmarks.tam.value,
        note: kpiBenchmarks.tam.status,
      ),
      Kpi(
        title: "GMV",
        value: kpiBenchmarks.gmv.value,
        note: kpiBenchmarks.gmv.status,
      ),
    ];

    return Dashboard(
      companyProfile: CompanyProfile.fromJson(json['company_profile']),
      executiveSummary: List<String>.from(json['executive_summary'] ?? []),
      kpiBenchmarks: KpiBenchmarks.fromJson(json['kpi_benchmarks']),
      investmentHighlights: InvestmentHighlights.fromJson(
        json['investment_highlights'],
      ),
      foundingTeam:
          (json['founding_team'] as List? ?? [])
              .map((e) => FoundingTeamMember.fromJson(e))
              .toList(),
      redFlags:
          (json['red_flags'] as List? ?? [])
              .map((e) => RedFlag.fromJson(e))
              .toList(),
      marketRegulation: MarketRegulation.fromJson(json['market_regulation']),
      aiInsights:
          (json['ai_insights'] as List? ?? [])
              .map((e) => AiInsight.fromJson(e))
              .toList(),
      score: (json['score'] ?? 0).toDouble(),
      recommendation: json['recommendation'] ?? '',
      videoId: json['video_id'],
      kpis: kpisList,
      kpiAlert: json['kpi_alert'] ?? "No alerts",
    );
  }
}

class CompanyProfile {
  final String name;
  final String description;
  final int founded;
  final String headquarters;
  final String industry;
  final String stage;
  final String revenue;
  final String fundingRaised;
  final String runway;
  final int teamSize;
  final String businessModel;

  CompanyProfile({
    required this.name,
    required this.description,
    required this.founded,
    required this.headquarters,
    required this.industry,
    required this.stage,
    required this.revenue,
    required this.fundingRaised,
    required this.runway,
    required this.teamSize,
    required this.businessModel,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      founded: json['founded'] ?? 0,
      headquarters: json['headquarters'] ?? '',
      industry: json['industry'] ?? '',
      stage: json['stage'] ?? '',
      revenue: json['revenue'] ?? '',
      fundingRaised: json['funding_raised'] ?? '',
      runway: json['runway'] ?? '',
      teamSize: json['team_size'] ?? 0,
      businessModel: json['business_model'] ?? '',
    );
  }
}

class KpiBenchmarks {
  final KpiMetric arr;
  final KpiMetric cac;
  final KpiMetric churn;
  final KpiMetric runway;
  final KpiMetric tam;
  final KpiMetric gmv;

  KpiBenchmarks({
    required this.arr,
    required this.cac,
    required this.churn,
    required this.runway,
    required this.tam,
    required this.gmv,
  });

  factory KpiBenchmarks.fromJson(Map<String, dynamic> json) {
    return KpiBenchmarks(
      arr: KpiMetric.fromJson(json['arr']),
      cac: KpiMetric.fromJson(json['cac']),
      churn: KpiMetric.fromJson(json['churn']),
      runway: KpiMetric.fromJson(json['runway']),
      tam: KpiMetric.fromJson(json['tam']),
      gmv: KpiMetric.fromJson(json['gmv']),
    );
  }
}

class KpiMetric {
  final String value;
  final String benchmark;
  final String status;

  KpiMetric({
    required this.value,
    required this.benchmark,
    required this.status,
  });

  factory KpiMetric.fromJson(Map<String, dynamic> json) {
    return KpiMetric(
      value: json['value'] ?? '',
      benchmark: json['benchmark'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class InvestmentHighlights {
  final String currentAsk;
  final String useOfFunds;
  final String exitStrategy;
  final List<String> keyStrengths;

  InvestmentHighlights({
    required this.currentAsk,
    required this.useOfFunds,
    required this.exitStrategy,
    required this.keyStrengths,
  });

  factory InvestmentHighlights.fromJson(Map<String, dynamic> json) {
    return InvestmentHighlights(
      currentAsk: json['current_ask'] ?? '',
      useOfFunds: json['use_of_funds'] ?? '',
      exitStrategy: json['exit_strategy'] ?? '',
      keyStrengths: List<String>.from(json['key_strengths'] ?? []),
    );
  }
}

class FoundingTeamMember {
  final String? name;
  final String? role;
  final String? avatar;
  final double? integrityScore;
  final String? culturalFit;
  final bool? priorExits;

  FoundingTeamMember({
    this.name,
    this.role,
    this.avatar,
    this.integrityScore,
    this.culturalFit,
    this.priorExits,
  });

  factory FoundingTeamMember.fromJson(Map<String, dynamic> json) {
    return FoundingTeamMember(
      name: json['name'],
      role: json['role'],
      avatar: json['avatar'],
      integrityScore: (json['integrity_score'] as num?)?.toDouble(),
      culturalFit: json['cultural_fit'],
      priorExits: json['prior_exits'],
    );
  }
}

class RedFlag {
  final String type;
  final String severity;
  final String description;

  RedFlag({
    required this.type,
    required this.severity,
    required this.description,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class MarketRegulation {
  final List<Alert> alerts;
  final int riskScore;

  MarketRegulation({required this.alerts, required this.riskScore});

  factory MarketRegulation.fromJson(Map<String, dynamic> json) {
    return MarketRegulation(
      alerts:
          (json['alerts'] as List? ?? [])
              .map((e) => Alert.fromJson(e))
              .toList(),
      riskScore: json['risk_score'] ?? 0,
    );
  }
}

class Alert {
  final String region;
  final String regulation;
  final String severity;

  Alert({
    required this.region,
    required this.regulation,
    required this.severity,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      region: json['region'] ?? '',
      regulation: json['regulation'] ?? '',
      severity: json['severity'] ?? '',
    );
  }
}

class AiInsight {
  final String type;
  final String title;
  final String description;
  final double? score;
  final bool? active;
  final String? status;

  AiInsight({
    required this.type,
    required this.title,
    required this.description,
    this.score,
    this.active,
    this.status,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      score: (json['score'] as num?)?.toDouble(),
      active: json['active'],
      status: json['status'],
    );
  }
}

class Kpi {
  final String title;
  final String value;
  final String note;

  Kpi({required this.title, required this.value, required this.note});

  factory Kpi.fromJson(Map<String, dynamic> json) {
    return Kpi(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class DashboardApi {
  /// Fetch dashboard as a strongly-typed Dashboard object
  static Future<Dashboard> fetchDashboard(String startupId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/v1/ui/dashboard/$startupId");
    debugPrint('Fetching Dashboard: $url');

    try {
      final res = await http.get(
        url,
        headers: {'accept': 'application/json', 'X-API-Key': 'dev-secret'},
      );

      debugPrint('Dashboard status: ${res.statusCode}');
      debugPrint('Dashboard body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        debugPrint('Founding Team data: ${decoded['founding_team']}');
        return Dashboard.fromJson(decoded);
      } else {
        throw Exception("Bad status ${res.statusCode}");
      }
    } catch (e, st) {
      debugPrint("Dashboard fetch error: $e\n$st");
      rethrow;
    }
  }
}
