// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AiInsightsDashboard extends StatefulWidget {
//   const AiInsightsDashboard({super.key});

//   @override
//   State<AiInsightsDashboard> createState() => _AiInsightsDashboardState();
// }

// class _AiInsightsDashboardState extends State<AiInsightsDashboard>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   late AnimationController _controller;

//   final Color kOrange = const Color(0xFFFF6B2C);
//   final Color kSapphire = const Color(0xFF3E2CFF);
//   final Color kLightBg = const Color(0xFFF7F8FA);
//   // --- Refined Theme Colors ---
//   final Color kAccent = const Color(0xFFF35B04);
//   final Color kBackgroundTop = const Color(0xFFF6F7FA);
//   final Color kBackgroundBottom = const Color(0xFFEFF1F5);
//   final Color kCard = Colors.white;
//   static const Color kTextPrimary = Color(0xFF1B1F27);
//   static const Color kTextSecondary = Color(0xFF6B7280);

//   Widget _buildTabBar() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: TabBar(
//         controller: _tabController,
//         indicatorSize: TabBarIndicatorSize.tab,
//         indicator: BoxDecoration(
//           color: kAccent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         labelColor: Colors.white,
//         unselectedLabelColor: kTextPrimary.withOpacity(0.9),
//         labelStyle: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           fontSize: 12,
//         ),
//         tabs: const [
//           Tab(icon: Icon(Icons.analytics), text: "  Behavioral Intelligence  "),
//           Tab(
//             icon: Icon(Icons.show_chart_rounded),
//             // reduce the font size slightly to fit longer text
//             text: "  Stress Testing & KPIs  ",
//           ),
//           Tab(
//             icon: Icon(Icons.public_rounded),
//             text: "  Market & Ecosystem Intelligence  ",
//           ),
//           Tab(
//             icon: Icon(Icons.dashboard_rounded),
//             text: "  Decision Support & Simulations  ",
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kLightBg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // --- Header ---
//             Container(
//               padding: const EdgeInsets.all(24),
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [kOrange, kSapphire],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(32),
//                   bottomRight: Radius.circular(32),
//                 ),
//               ),
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (_, child) {
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       ShaderMask(
//                         shaderCallback:
//                             (bounds) => LinearGradient(
//                               colors: [
//                                 Colors.white,
//                                 Colors.orangeAccent,
//                                 Colors.white,
//                               ],
//                               stops: [0, _controller.value, 1],
//                             ).createShader(bounds),
//                         child: Text(
//                           "AI Insights",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 32,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Where AI does the magic for Venture Capital due diligence ✨",
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.85),
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.only(top: 20),
//               child: _buildTabBar(),
//             ),

//             // --- Tab Contents ---
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: const [
//                   _Section(features: _behavioralFeatures),
//                   _Section(features: _stressFeatures),
//                   _Section(features: _marketFeatures),
//                   _Section(features: _decisionFeatures),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // --- Section + Feature Tiles ---
// class _Section extends StatelessWidget {
//   final List<Feature> features;
//   const _Section({required this.features});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//       itemCount: features.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 20),
//       itemBuilder: (context, i) => FeatureTile(feature: features[i]),
//     );
//   }
// }

// class FeatureTile extends StatefulWidget {
//   final Feature feature;
//   const FeatureTile({super.key, required this.feature});

//   @override
//   State<FeatureTile> createState() => _FeatureTileState();
// }

// class _FeatureTileState extends State<FeatureTile> {
//   bool expanded = false;

//   @override
//   Widget build(BuildContext context) {
//     final f = widget.feature;
//     final Color kOrange = const Color(0xFFFF6B2C);

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 100),
//       curve: Curves.easeInOut,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: f.highlight ? 12 : 6,
//             // offset: const Offset(0, f.highlight ? 6 : 3),
//           ),
//         ],
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: () => setState(() => expanded = !expanded),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Icon + title
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: kOrange.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(f.icon, color: kOrange, size: 28),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Text(
//                       f.title,
//                       style: TextStyle(
//                         color: Colors.black87,
//                         fontSize: 17,
//                         fontWeight:
//                             f.highlight ? FontWeight.bold : FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   AnimatedRotation(
//                     turns: expanded ? 0.5 : 0,
//                     duration: const Duration(milliseconds: 300),
//                     child: const Icon(Icons.keyboard_arrow_down),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               AnimatedCrossFade(
//                 firstChild: const Text(
//                   "Tap to expand",
//                   style: TextStyle(color: Colors.grey, fontSize: 13),
//                 ),
//                 secondChild: Text(
//                   f.insight,
//                   style: const TextStyle(color: Colors.black87, fontSize: 14),
//                 ),
//                 crossFadeState:
//                     expanded
//                         ? CrossFadeState.showSecond
//                         : CrossFadeState.showFirst,
//                 duration: const Duration(milliseconds: 250),
//               ),
//               if (f.highlight) ...[
//                 const SizedBox(height: 12),
//                 Container(
//                   height: 4,
//                   width: 60,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [kOrange, Colors.deepOrangeAccent],
//                     ),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lumora/config/ApiConfig.dart';

// ------------------ MAIN SCREEN ------------------

class AiInsightsDashboard extends StatefulWidget {
  final String startupId;
  const AiInsightsDashboard({super.key, required this.startupId});

  @override
  State<AiInsightsDashboard> createState() => _AiInsightsDashboardState();
}

class _AiInsightsDashboardState extends State<AiInsightsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _controller;

  final Color kOrange = const Color(0xFFFF6B2C);
  final Color kSapphire = const Color(0xFF3E2CFF);
  final Color kLightBg = const Color(0xFFF7F8FA);
  final Color kAccent = const Color(0xFFF35B04);
  final Color kBackgroundTop = const Color(0xFFF6F7FA);
  final Color kBackgroundBottom = const Color(0xFFEFF1F5);
  final Color kCard = Colors.white;
  static const Color kTextPrimary = Color(0xFF1B1F27);

  bool loading = true;
  String? error;

  // --- Dynamic API Data ---
  List<Feature> behavioralFeatures = _behavioralFeatures;
  List<Feature> stressFeatures = _stressFeatures;
  List<Feature> marketFeatures = _marketFeatures;
  List<Feature> decisionFeatures = _decisionFeatures;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetchAiInsights();
  }

  Future<void> _fetchAiInsights() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/v1/ai-insights/${widget.startupId}",
    );
    try {
      final res = await http.get(
        url,
        headers: {'accept': 'application/json', 'X-API-Key': 'dev-secret'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          behavioralFeatures = _mapBehavioralFeatures(data);
          stressFeatures = _mapStressFeatures(data);
          marketFeatures = _mapMarketFeatures(data);
          decisionFeatures = _mapDecisionFeatures(data);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          error = "Bad response: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // --- MAPPING FUNCTIONS ---

  List<Feature> _mapBehavioralFeatures(Map<String, dynamic> json) {
    final fb = json['founder_behavioral_fingerprint'];
    final ts = json['founder_truth_signature'];
    final cf = json['cultural_fit_alignment'];

    if (fb == null && ts == null && cf == null) return _behavioralFeatures;

    final list = <Feature>[];
    if (fb != null) {
      list.add(
        Feature(
          title: "Founder Behavioral Fingerprint",
          insights: [
            fb['summary'],
            ...List<String>.from(fb['key_findings'] ?? []),
          ],
          icon: Icons.fingerprint,
          highlight: true,
        ),
      );
    }
    if (ts != null) {
      list.add(
        Feature(
          title: "Founder Truth Signature",
          insights: [
            ts['summary'],
            ...List<String>.from(ts['key_findings'] ?? []),
          ],
          icon: Icons.track_changes,
        ),
      );
    }
    if (cf != null) {
      list.add(
        Feature(
          title: "Cultural Fit & Vision Alignment",
          insights: [
            cf['summary'],
            ...List<String>.from(cf['key_findings'] ?? []),
          ],
          icon: Icons.handshake,
        ),
      );
    }
    return list.isNotEmpty ? list : _behavioralFeatures;
  }

  List<Feature> _mapStressFeatures(Map<String, dynamic> json) {
    final sist = List<Map<String, dynamic>>.from(
      json['synthetic_investor_stress_test'] ?? [],
    );
    final counter = List<String>.from(
      json['counterfactual_explanations'] ?? [],
    );

    if (sist.isEmpty && counter.isEmpty) return _stressFeatures;

    final list = <Feature>[];
    if (sist.isNotEmpty) {
      list.add(
        Feature(
          title: "Synthetic Investor Stress Test (SIST)",
          insights:
              sist.map((s) {
                return "${s['scenario']} — Impact: ${s['impact']}\nMitigation: ${s['mitigation']}";
              }).toList(),
          icon: Icons.trending_down,
          highlight: true,
        ),
      );
    }

    if (counter.isNotEmpty) {
      list.add(
        Feature(
          title: "Counterfactual Explanations",
          insights: counter,
          icon: Icons.sync_alt,
        ),
      );
    }
    return list.isNotEmpty ? list : _stressFeatures;
  }

  List<Feature> _mapMarketFeatures(Map<String, dynamic> json) {
    final radar = List<Map<String, dynamic>>.from(
      json['market_sentiment_radar'] ?? [],
    );
    final peers = List<String>.from(json['peer_shock_detector'] ?? []);
    final invisible = List<String>.from(json['invisible_signals'] ?? []);
    final regulatory = List<String>.from(json['regulatory_radar'] ?? []);

    if (radar.isEmpty && peers.isEmpty && invisible.isEmpty)
      return _marketFeatures;

    final list = <Feature>[];

    if (radar.isNotEmpty) {
      list.add(
        Feature(
          title: "Dynamic Market Sentiment Radar",
          insights:
              radar.map((r) {
                return "${r['signal_type']} (${r['strength']}) — ${r['description']}\nAction: ${r['actionable_insight']}";
              }).toList(),
          icon: Icons.radar,
          highlight: true,
        ),
      );
    }

    if (peers.isNotEmpty) {
      list.add(
        Feature(
          title: "Peer Shock Detector",
          insights: peers,
          icon: Icons.groups,
        ),
      );
    }

    if (invisible.isNotEmpty) {
      list.add(
        Feature(
          title: "Invisible Signals Scanner",
          insights: invisible,
          icon: Icons.bolt,
        ),
      );
    }

    if (regulatory.isNotEmpty) {
      list.add(
        Feature(
          title: "Regulatory & Market Radar",
          insights: regulatory,
          icon: Icons.gavel,
        ),
      );
    }

    return list.isNotEmpty ? list : _marketFeatures;
  }

  List<Feature> _mapDecisionFeatures(Map<String, dynamic> json) {
    final termSheet = List<String>.from(json['auto_term_sheet_bullets'] ?? []);
    final redTeam = List<String>.from(json['red_team_analysis'] ?? []);
    final responses = Map<String, dynamic>.from(
      json['founder_response_simulation'] ?? {},
    );

    if (termSheet.isEmpty && redTeam.isEmpty && responses.isEmpty)
      return _decisionFeatures;

    final list = <Feature>[];
    if (termSheet.isNotEmpty) {
      list.add(
        Feature(
          title: "Auto-Term Sheet Assistant",
          insights: termSheet,
          icon: Icons.article,
        ),
      );
    }

    if (redTeam.isNotEmpty) {
      list.add(
        Feature(
          title: "One-click Red Team",
          insights: redTeam,
          icon: Icons.warning_amber,
          highlight: true,
        ),
      );
    }

    if (responses.isNotEmpty) {
      list.add(
        Feature(
          title: "Founder Response Simulator",
          insights:
              responses.entries
                  .map((e) => "${e.key.toUpperCase()}:\n${e.value}")
                  .toList(),
          icon: Icons.smart_toy,
        ),
      );
    }
    return list.isNotEmpty ? list : _decisionFeatures;
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- UI ---
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: kTextPrimary.withOpacity(0.9),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.analytics), text: "  Behavioral Intelligence  "),
          Tab(
            icon: Icon(Icons.show_chart_rounded),
            text: "  Stress Testing & KPIs  ",
          ),
          Tab(
            icon: Icon(Icons.public_rounded),
            text: "  Market & Ecosystem Intelligence  ",
          ),
          Tab(
            icon: Icon(Icons.dashboard_rounded),
            text: "  Decision Support & Simulations  ",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text("Error loading AI Insights:\n$error")),
      );
    }

    return Scaffold(
      backgroundColor: kLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kOrange, kSapphire],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.orangeAccent,
                                Colors.white,
                              ],
                              stops: [0, _controller.value, 1],
                            ).createShader(bounds),
                        child: const Text(
                          "AI Insights",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Where AI does the magic for Venture Capital due diligence ✨",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildTabBar(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _Section(features: behavioralFeatures),
                  _Section(features: stressFeatures),
                  _Section(features: marketFeatures),
                  _Section(features: decisionFeatures),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Existing UI Components (unchanged) ----------------
class _Section extends StatelessWidget {
  final List<Feature> features;
  const _Section({required this.features});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: features.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => FeatureTile(feature: features[i]),
    );
  }
}

class FeatureTile extends StatefulWidget {
  final Feature feature;
  const FeatureTile({super.key, required this.feature});

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    final Color kOrange = const Color(0xFFFF6B2C);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: f.highlight ? 12 : 6),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(f.icon, color: kOrange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      f.title,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight:
                            f.highlight ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                firstChild: const Text(
                  "Tap to expand",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                secondChild: Text(
                  f.insight,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                crossFadeState:
                    expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              if (f.highlight) ...[
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrange, Colors.deepOrangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Feature {
  final String title;
  final List<String> insights;
  final IconData icon;
  final bool highlight;
  const Feature({
    required this.title,
    required this.insights,
    required this.icon,
    this.highlight = false,
  });
  String get insight => (List.of(insights)..shuffle()).first;
}

// ---------------- Features ----------------

// class Feature {
//   final String title;
//   final List<String> insights;
//   final IconData icon;
//   final bool highlight;

//   const Feature({
//     required this.title,
//     required this.insights,
//     required this.icon,
//     this.highlight = false,
//   });

//   // Helper to get a random insight each time screen loads
//   String get insight => (List.of(insights)..shuffle()).first;
// }

const _behavioralFeatures = [
  Feature(
    title: "Founder Behavioral Fingerprint",
    insights: [
      "Behavioral AI triangulates across 22 founder communication samples — including investor calls, customer demos, and email threads — to compute a Founder Integrity Score of 91%. The high linguistic alignment between strategic statements and execution plans indicates cognitive stability and low decision volatility.",
      "Temporal tone analytics show consistent cadence and low linguistic entropy, suggesting a deliberate thought process rather than rehearsed optimism. Such pacing patterns are correlated with leaders who sustain operational clarity under scaling pressure.",
      "Microexpression variance remains within the 8–10% stability band across stress contexts, signaling composure under analytical challenge. This suggests that leadership demeanor remains authentic even in high-pressure fundraising situations.",
      "Semantic coherence modeling reveals that the founder’s values, strategic intent, and action narratives exhibit 0.89 alignment — minimizing cultural dissonance between communication and execution.",
      "Cross-verification with team sentiment data confirms authenticity markers, with less than 5% discrepancy in tone perception. This indicates congruence between self-perception and team experience, a key predictor of sustainable leadership trust.",
    ],
    icon: Icons.fingerprint,
    highlight: true,
  ),
  Feature(
    title: "Founder Truth Signature",
    insights: [
      "Voice analytics using prosody and micro-hesitation metrics assign an 88% truth confidence score, placing the founder within the top quartile for authenticity among early-stage founders. Minimal tonal distortion under questioning reinforces factual alignment.",
      "Latency variance analysis during financial projections shows sub-second stability, implying the absence of cognitive stress cues typically linked with overstatement. This suggests confidence derived from actual operational traction.",
      "Linguistic polarity and factual density remain statistically consistent across narrative and Q&A formats — an indicator of transparent cognitive framing. AI models categorize this as ‘high-trust discourse’.",
      "Emotion-to-semantic coherence mapping detects mild enthusiasm inflation when discussing valuation, interpreted as promotional optimism rather than deceptive intent — a positive signal if balanced with quantifiable data.",
      "Lexical entropy across interviews remains low, indicating emotional regulation and narrative discipline. Founders in this cluster historically exhibit stronger investor trust retention over multiple funding rounds.",
    ],
    icon: Icons.track_changes,
  ),
  Feature(
    title: "Cultural Fit & Vision Alignment",
    insights: [
      "Vision document embeddings show 93% alignment with impact-oriented investor archetypes, emphasizing ethical innovation and sustainable scaling — signaling strong fund-founder value congruence.",
      "Cross-lingual tone analysis indicates that mission articulation carries a collaborative and transparent undertone, commonly associated with founders who build long-term compounding businesses rather than short-term valuation plays.",
      "Purpose-to-performance linkage shows minimal mission drift, as operational KPIs reflect the same priorities emphasized in public communications. This coherence enhances investor confidence in founder intent.",
      "Cultural compatibility modeling matches the founder’s leadership profile with analytical, product-led investors — optimizing fit for data-centric venture ecosystems.",
      "Narrative heatmapping reveals emotional resonance around customer impact and technical craftsmanship, reflecting authentic conviction rather than narrative engineering.",
    ],
    icon: Icons.handshake,
  ),
];

const _stressFeatures = [
  Feature(
    title: "Synthetic Investor Stress Test (SIST)",
    insights: [
      "Downside scenario modeling simulates a 25% revenue contraction over two quarters, reducing runway to 13 months but showing rapid burn adaptation through deferred hiring levers — demonstrating fiscal elasticity and resilience.",
      "Monte Carlo simulations indicate 78% survival probability under combined churn and funding delay stressors, outperforming SaaS peer medians by 1.5x, largely due to variable cost control efficiency.",
      "Revenue sensitivity mapping highlights customer acquisition volatility as the highest leverage point — optimizing paid acquisition strategy could enhance shock tolerance by up to 22%.",
      "Macro-correlated stress tests show minimal dependency on single-market exposure, confirming robust diversification and strategic resilience across regions.",
      "Liquidity vector analysis predicts full recovery within two quarters post-downturn, suggesting adaptive operational governance comparable to top-performing seed-to-Series A transitions.",
    ],
    icon: Icons.trending_down,
    highlight: true,
  ),
  Feature(
    title: "Emotion-Driven KPI Weighting",
    insights: [
      "Affective computing models detect enthusiasm bias inflating projected growth metrics by 9%. After sentiment normalization, adjusted KPI weighting reduces optimism bias from 18% to 7%, yielding more realistic forecasts.",
      "Emotion-to-metric coupling analysis redistributes emphasis from vanity metrics (GMV) toward retention and burn efficiency, improving predictive reliability by 12%.",
      "Tone-based attention scoring identifies subconscious stress cues when discussing HR costs, implying sensitivity around hiring velocity — now weighted 1.3x in resilience evaluation.",
      "Integrating real-time affective signals with financial models refines investor perception accuracy, capturing founder psychology as a variable in performance risk prediction.",
      "Emotionally contextualized KPI scoring positions the founder’s conviction as an asset when moderated by data-driven governance, enhancing holistic risk-adjusted assessment.",
    ],
    icon: Icons.auto_graph,
  ),
  Feature(
    title: "Counterfactual Explanations",
    insights: [
      "AI counterfactual models reveal that a 3% improvement in gross margin would elevate valuation probability tier from pre-Series A to readiness, demonstrating strong leverage in efficiency optimization.",
      "Retention elasticity analysis shows that a 1.5x increase in customer stickiness neutralizes 80% of observed downside risk in stress simulations — a high-return improvement target.",
      "Sensitivity mapping identifies customer LTV expansion as the most efficient lever to raise investor confidence scores, followed by marginal CAC compression.",
      "Adjusting hiring velocity by ±10% changes the resilience index by 0.6 points, confirming that human capital scaling directly governs survival dynamics.",
      "Operational efficiency improvements of 4% yield equivalent confidence gains as 15% marketing spend cuts, validating process refinement as a superior capital allocation path.",
    ],
    icon: Icons.sync_alt,
  ),
];

const _marketFeatures = [
  Feature(
    title: "Dynamic Market Sentiment Radar",
    insights: [
      "Aggregating data from 47 market sources, sentiment polarity rose 12% week-on-week within mobility-tech verticals, forecasting sustained investor attention for two subsequent quarters.",
      "Social signal fatigue in peer narratives presents a white-space opportunity for differentiated brand storytelling, particularly around sustainability positioning.",
      "Funding velocity modeling shows 0.78 correlation between sustainability keyword density and investor momentum, signaling a near-term window for PR amplification.",
      "Patent issuance in adjacent domains increased 14%, indicating accelerated innovation cycles and potential partnership opportunities with ecosystem incumbents.",
      "Regulatory chatter analysis predicts mild friction risk in EU markets by Q3 next year, but positive sentiment momentum offsets systemic exposure.",
    ],
    icon: Icons.radar,
    highlight: true,
  ),
  Feature(
    title: "Peer Shock Detector",
    insights: [
      "Early warning analytics detect anomalous hiring freezes across two peer companies, suggesting capital conservation cycles likely tied to delayed funding rounds.",
      "Open-source contribution velocity among competitors dropped 8%, signaling potential internal reprioritization or product plateauing — advantageous timing for strategic differentiation.",
      "Network graph dynamics show several executives in the sector migrating toward B2G contracts, hinting at a defensive market pivot trend.",
      "LinkedIn and job post deltas reveal a 17% rise in lateral hiring for similar technical roles, indicating growing competition in mid-level engineering talent.",
      "Despite short-term peer volatility, macro-level signal coherence indicates medium-term market stabilization — favorable for measured capital deployment.",
    ],
    icon: Icons.groups,
  ),
  Feature(
    title: "Invisible Signals Scanner",
    insights: [
      "Cross-network metadata identifies repeated fund mentions across closed investor channels, implying stealth diligence interest from Tier-1 firms.",
      "Topic recurrence in co-founder interviews matches pre-acquisition narrative structures observed in historical M&A datasets, suggesting latent strategic alignment.",
      "Calendar co-occurrence mapping detects overlapping meetings with three strategic investors, consistent with secondary negotiation phases.",
      "LinkedIn graph density increased 22% over eight weeks, indicating accelerating investor network penetration and visibility lift.",
      "Conference attendance overlap analysis uncovers early coalition signals among complementary startups — predictive of ecosystem co-acceleration.",
    ],
    icon: Icons.bolt,
  ),
  Feature(
    title: "Regulatory & Market Radar",
    insights: [
      "Geo-compliance AI forecasts minimal exposure to upcoming EU data localization mandates, though a proactive audit by Q2 is advised.",
      "Regulatory sentiment tracking detects rising scrutiny on fintech verticals, but low contagion risk for the B2B SaaS segment under review.",
      "Regional risk heatmaps classify Southeast Asia as medium-risk due to fragmented enforcement, warranting gradual expansion pacing.",
      "Home-market policy alignment scores 85% compliance readiness, confirming strong governance fundamentals for enterprise onboarding.",
      "ESG narrative sentiment dips below peer average by 7%, suggesting early remediation opportunities through transparent impact reporting.",
    ],
    icon: Icons.gavel,
  ),
];

const _decisionFeatures = [
  Feature(
    title: "Auto-Term Sheet Assistant",
    insights: [
      "AI benchmarking across 120 comparable deals recommends a 12% option pool and 1.8x liquidation preference to balance investor downside protection with founder retention.",
      "Governance simulation models identify a 4-year vesting schedule with 1-year cliff as optimal for execution continuity without increasing churn probability.",
      "SAFE-to-equity conversion at a 25% discount improves round transparency and enhances signaling for follow-on investors by 14%.",
      "Negotiation scenario modeling shows founders retain 6% more equity when MFN clauses are structured with capped triggers rather than open-ended rights.",
      "Weighted equity allocation modeling highlights the benefit of early key-hire equity rebalancing, improving operational velocity scores by 9%.",
    ],
    icon: Icons.article,
  ),
  Feature(
    title: "Interactive Ask-the-Analyst",
    insights: [
      "AI synthesis of 118 investor Q&As reveals that 76% of clarifications target revenue attribution and retention modeling — preemptive disclosure reduces due diligence friction.",
      "Transcript-based semantic clustering identifies recurring questions on pricing defensibility; automated generation of comparative pricing tables accelerates investor comprehension.",
      "Predictive insight engine advises positioning customer acquisition efficiency metrics early in decks, decreasing investor follow-up churn by 18%.",
      "Investor tone analytics show higher trust formation when quantified growth metrics are stated within the first 45 seconds of a pitch response.",
      "AI brief summaries reduced investor comprehension time by 22% in pilot reviews, enhancing perceived founder preparedness and information accessibility.",
    ],
    icon: Icons.question_answer,
  ),
  Feature(
    title: "One-click Red Team",
    insights: [
      "Dependency on a single enterprise client driving 43% of revenue constitutes primary concentration risk; diversification within 2 quarters recommended to preserve valuation stability.",
      "Emerging open-source entrants present potential pricing compression risk within 9 months — competitive moat reinforcement through proprietary integrations advised.",
      "Operational process mapping exposes a 19-day onboarding lag against industry median of 11, signaling cash cycle optimization opportunity.",
      "Pricing elasticity modeling identifies customer sensitivity thresholds beyond ±12% variance, beyond which churn risk escalates sharply.",
      "Founder overextension risk rated moderate; cross-domain workload diffusion analysis suggests immediate delegation to sustain execution focus.",
    ],
    icon: Icons.warning_amber,
    highlight: true,
  ),
  Feature(
    title: "Founder Response Simulator",
    insights: [
      "Scenario replay models show optimistic response framing improves investor confidence but risks perceived deflection under stress; balanced data-led tone recommended.",
      "Simulation outcomes reveal 15% higher investor trust when founders lead with quantified metrics instead of narrative storytelling.",
      "Neutral persona mode increases perceived transparency, especially when founders acknowledge data gaps directly — improving credibility signal strength.",
      "Evasive answer detection models show deliberate pause before uncertain metrics boosts perceived honesty more than continuous improvisation.",
      "Empathetic framing (‘what we’re learning’) during adverse updates increases investor goodwill by 11%, reinforcing relational capital resilience.",
    ],
    icon: Icons.smart_toy,
  ),
];
