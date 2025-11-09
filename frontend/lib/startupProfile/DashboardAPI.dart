import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lumora/config/ApiConfig.dart';

class StartupDetails {
  final Identity identity;
  final List<String> founders;
  final Metrics metrics;
  final Market market;
  final Traction traction;
  final Fundraising fundraising;
  final Business business;
  final List<Document> documents;
  final AiAnalysis aiAnalysis;

  StartupDetails({
    required this.identity,
    required this.founders,
    required this.metrics,
    required this.market,
    required this.traction,
    required this.fundraising,
    required this.business,
    required this.documents,
    required this.aiAnalysis,
  });

  factory StartupDetails.fromJson(Map<String, dynamic> json) {
    return StartupDetails(
      identity: Identity.fromJson(json['identity']),
      founders: List<String>.from(json['founders'] ?? []),
      metrics: Metrics.fromJson(json['metrics']),
      market: Market.fromJson(json['market']),
      traction: Traction.fromJson(json['traction']),
      fundraising: Fundraising.fromJson(json['fundraising']),
      business: Business.fromJson(json['business']),
      documents:
          (json['documents'] as List? ?? [])
              .map((e) => Document.fromJson(e))
              .toList(),
      aiAnalysis: AiAnalysis.fromJson(json['ai_analysis']),
    );
  }
}

class Identity {
  final String startupId;
  final String name;
  final String companyName;
  final String stage;
  final String sector;
  final String location;
  final String foundedYear;
  final String website;

  Identity({
    required this.startupId,
    required this.name,
    required this.companyName,
    required this.stage,
    required this.sector,
    required this.location,
    required this.foundedYear,
    required this.website,
  });

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      startupId: json['startup_id'] ?? '',
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      stage: json['stage'] ?? '',
      sector: json['sector'] ?? '',
      location: json['location'] ?? '',
      foundedYear: json['founded_year'] ?? '',
      website: json['website'] ?? '',
    );
  }
}

class Metrics {
  final String arr;
  final String growthRate;
  final String grossMargin;
  final String burnRate;
  final String runwayMonths;
  final String cac;
  final String ltv;
  final String cacLtvRatio;

  Metrics({
    required this.arr,
    required this.growthRate,
    required this.grossMargin,
    required this.burnRate,
    required this.runwayMonths,
    required this.cac,
    required this.ltv,
    required this.cacLtvRatio,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      arr: json['arr'] ?? '',
      growthRate: json['growth_rate'] ?? '',
      grossMargin: json['gross_margin'] ?? '',
      burnRate: json['burn_rate'] ?? '',
      runwayMonths: json['runway_months'] ?? '',
      cac: json['cac'] ?? '',
      ltv: json['ltv'] ?? '',
      cacLtvRatio: json['cac_ltv_ratio'] ?? '',
    );
  }
}

class Market {
  final List<String> highlights;

  Market({required this.highlights});

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(highlights: List<String>.from(json['highlights'] ?? []));
  }
}

class Traction {
  final List<String> highlights;

  Traction({required this.highlights});

  factory Traction.fromJson(Map<String, dynamic> json) {
    return Traction(highlights: List<String>.from(json['highlights'] ?? []));
  }
}

class Fundraising {
  final List<String> highlights;
  final String ask;
  final String raisedToDate;
  final String valuation;

  Fundraising({
    required this.highlights,
    required this.ask,
    required this.raisedToDate,
    required this.valuation,
  });

  factory Fundraising.fromJson(Map<String, dynamic> json) {
    return Fundraising(
      highlights: List<String>.from(json['highlights'] ?? []),
      ask: json['ask'] ?? '',
      raisedToDate: json['raised_to_date'] ?? '',
      valuation: json['valuation'] ?? '',
    );
  }
}

class Business {
  final String problem;
  final String solution;
  final String businessModel;
  final String targetAudience;
  final String competitiveAdvantage;
  final String techStack;
  final String pricing;

  Business({
    required this.problem,
    required this.solution,
    required this.businessModel,
    required this.targetAudience,
    required this.competitiveAdvantage,
    required this.techStack,
    required this.pricing,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      problem: json['problem'] ?? '',
      solution: json['solution'] ?? '',
      businessModel: json['business_model'] ?? '',
      targetAudience: json['target_audience'] ?? '',
      competitiveAdvantage: json['competitive_advantage'] ?? '',
      techStack: json['tech_stack'] ?? '',
      pricing: json['pricing'] ?? '',
    );
  }
}

class Document {
  final String type;
  final String filename;
  final String documentId;
  final int pages;
  final String? uploadedAt;

  Document({
    required this.type,
    required this.filename,
    required this.documentId,
    required this.pages,
    this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      type: json['type'] ?? '',
      filename: json['filename'] ?? '',
      documentId: json['document_id'] ?? '',
      pages: json['pages'] ?? 0,
      uploadedAt: json['uploaded_at'],
    );
  }
}

class AiAnalysis {
  final String executiveSummary;
  final Map<String, String> kpis;
  final List<Risk> risks;
  final String recommendation;
  final double score;

  AiAnalysis({
    required this.executiveSummary,
    required this.kpis,
    required this.risks,
    required this.recommendation,
    required this.score,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      executiveSummary: json['executive_summary'] ?? '',
      kpis: Map<String, String>.from(json['kpis'] ?? {}),
      risks:
          (json['risks'] as List? ?? []).map((e) => Risk.fromJson(e)).toList(),
      recommendation: json['recommendation'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
    );
  }
}

class Risk {
  final String type;
  final String severity;
  final String description;
  final String mitigation;

  Risk({
    required this.type,
    required this.severity,
    required this.description,
    required this.mitigation,
  });

  factory Risk.fromJson(Map<String, dynamic> json) {
    return Risk(
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      description: json['description'] ?? '',
      mitigation: json['mitigation'] ?? '',
    );
  }
}

class StartupDetailsApi {
  static Future<StartupDetails> fetchStartupDetails(String startupId) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/v1/startups/$startupId/details",
    );
    debugPrint('Fetching Startup Details: $url');

    try {
      final res = await http.get(
        url,
        headers: {'accept': 'application/json', 'X-API-Key': 'dev-secret'},
      );

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        return StartupDetails.fromJson(decoded);
      } else {
        throw Exception("Bad status ${res.statusCode}");
      }
    } catch (e, st) {
      debugPrint("Startup details fetch error: $e\n$st");
      rethrow;
    }
  }
}
