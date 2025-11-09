import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lumora/config/ApiConfig.dart';

class AIChatScreen extends StatefulWidget {
  final String startupId;

  const AIChatScreen({super.key, required this.startupId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("AIChatScreen initialized with startupId: ${widget.startupId}");
  }

  final List<Map<String, dynamic>> _messages = [
    {
      "sender": "Lumora AI",
      "message":
          "Hi there! I'm Lumora, your personal startup assistant. How can I help you today?",
      "isUser": false,
    },
  ];

  // void _addMockAIMessage({
  //   required String answer,
  //   required List<Map<String, dynamic>> evidence,
  //   required double confidence,
  // }) {
  //   final formattedEvidence =
  //       evidence.map((e) {
  //         return {
  //           "text": "• ${e["snippet"]}",
  //           "meta":
  //               "${e["type"].toString().toUpperCase()}${e["location"] != null ? " (${e["location"]})" : ""} · ${(e["confidence"] * 100).toInt()}% confidence",
  //           "confidence": e["confidence"],
  //         };
  //       }).toList();

  //   setState(() {
  //     _messages.add({
  //       "sender": "Lumora AI",
  //       "message": answer,
  //       "isUser": false,
  //       "confidence": confidence,
  //       "evidence": formattedEvidence,
  //     });
  //   });
  // }

  // Future<void> _sendMessage() async {
  //   final text = _controller.text.trim();
  //   if (text.isEmpty) return;

  //   setState(() {
  //     _messages.add({"sender": "You", "message": text, "isUser": true});
  //     _controller.clear();
  //     _isLoading = true;
  //   });

  //   _scrollToBottom();

  //   // --- MOCK INTELLIGENCE STARTS HERE ---
  //   await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
  //   String lower = text.toLowerCase();

  //   if (lower == ("Who are the founders of Data Stride?")) {
  //     _addMockAIMessage(
  //       answer:
  //           "Data Stride was founded by Sumalata Kamat, Divya Krishna, and Karthik Chandrashekhar.",
  //       evidence: [
  //         {
  //           "snippet": "Pitch deck Upload",
  //           "type": "pitch deck",
  //           "location": "Pitch Deck Upload",
  //           "confidence": 1.0,
  //         },
  //       ],
  //       confidence: 1.0,
  //     );
  //   } else if (lower == ("What is the ARR of data stride?")) {
  //     _addMockAIMessage(
  //       answer:
  //           "ARR is not available in pitch deck or founder checklist provided",
  //       evidence: [
  //         {
  //           "snippet": "Pitch deck Upload and Founder checklist",
  //           "type": "pitch deck",
  //           "location": "Pitch Deck Upload",
  //           "confidence": 1.0,
  //         },
  //       ],
  //       confidence: 1.0,
  //     );
  //   } else if (lower == ("What is ARR?")) {
  //     _addMockAIMessage(
  //       answer:
  //           "The acronym \"arr\" most commonly stands for Annual Recurring Revenue, a metric that represents the predictable revenue a company expects to generate from its subscriptions and contracts in a year.",
  //       evidence: [
  //         {
  //           "snippet": "arr",
  //           "type": "information",
  //           "location": "Internal Knowledge Base",
  //           "confidence": 1.0,
  //         },
  //       ],
  //       confidence: 1.0,
  //     );
  //   } else if (lower.contains("data stride")) {
  //     _addMockAIMessage(
  //       answer:
  //           "DataStride is an enterprise data infrastructure startup specializing in real-time analytics pipelines. In its latest funding round, it raised \$18M Series A led by Gradient Ventures, focusing on data observability and AI governance. Based on public signals, DataStride’s ARR has grown 3.1× year-over-year, with significant traction in the FinOps and data lineage market.",
  //       evidence: [
  //         {
  //           "snippet":
  //               "DataStride raised \$18M Series A led by Gradient Ventures (TechCrunch, Aug 2025).",
  //           "type": "pitch deck",
  //           "location": "Pitch Deck Upload",
  //           "confidence": 1.0,
  //         },
  //         {
  //           "snippet":
  //               "ARR grew 3.1× YoY as per investor update (PitchBook, Q3 2025).",
  //           "type": "report",
  //           "location": "lumora/pitchdeck/profile/datastirde",
  //           "confidence": 0.88,
  //         },
  //       ],
  //       confidence: 0.92,
  //     );
  //   } else if (lower.contains("fintech") && lower.contains("news")) {
  //     _addMockAIMessage(
  //       answer:
  //           "The fintech sector has seen a surge in infrastructure deals this quarter. Notably, Stripe announced a new cross-border API stack, while Monzo expanded into the US market. Venture funding in fintech rose 18% QoQ driven by AI-led credit risk models and embedded finance adoption.",
  //       evidence: [
  //         {
  //           "snippet":
  //               "Stripe launches cross-border API stack to simplify multi-currency settlements (Forbes, Oct 2025).",
  //           "type": "news",
  //           "location": "https://forbes.com/stripe-api-2025",
  //           "confidence": 0.9,
  //         },
  //         {
  //           "snippet":
  //               "Monzo expands to the US with a 250k waitlist (Bloomberg, Sep 2025).",
  //           "type": "news",
  //           "location": "https://bloomberg.com/monzo-us-expansion",
  //           "confidence": 0.87,
  //         },
  //       ],
  //       confidence: 0.89,
  //     );
  //   } else if (lower.contains("top startup") ||
  //       lower.contains("best startup")) {
  //     _addMockAIMessage(
  //       answer:
  //           "Based on public traction metrics, the most promising startups in Q4 2025 include:\n\n1. HealthAI – AI-driven health dashboard interface platform (Series B, \$42M).\n2. AgroNext – Sustainable data center cooling using phase-change materials.\n3. **Finion** – Predictive credit analytics for emerging markets, growing 11% MoM ARR.\n\nEach has sustained organic hiring growth >25% and high investor sentiment.",
  //       evidence: [
  //         {
  //           "snippet":
  //               "NeuroWeave closed \$42M Series B backed by Sequoia (TechCrunch, Oct 2025).",
  //           "type": "news",
  //           "location": "https://techcrunch.com/neuro-weave-series-b",
  //           "confidence": 0.9,
  //         },
  //         {
  //           "snippet":
  //               "FinPilot reported 11% MoM ARR growth (Crunchbase, Q3 2025).",
  //           "type": "report",
  //           "location": "https://crunchbase.com/organization/finpilot",
  //           "confidence": 0.86,
  //         },
  //       ],
  //       confidence: 0.91,
  //     );
  //   } else if (lower.contains("market sentiment") ||
  //       lower.contains("ai investing")) {
  //     _addMockAIMessage(
  //       answer:
  //           "AI investing sentiment remains at an all-time high. Over 62% of venture capital deployed in 2025 Q3 involved AI-related startups. However, valuation multiples have started to normalize — median pre-money valuation down 14% from Q2, indicating a return to fundamentals.",
  //       evidence: [
  //         {
  //           "snippet":
  //               "AI startups attracted 62% of VC funding in Q3 2025 (CB Insights Global AI Report).",
  //           "type": "report",
  //           "location": "https://cbinsights.com/reports/ai-funding-q3-2025",
  //           "confidence": 0.93,
  //         },
  //         {
  //           "snippet":
  //               "Median pre-money valuation for AI firms fell 14% (PitchBook, Oct 2025).",
  //           "type": "report",
  //           "location": "https://pitchbook.com/ai-q3-2025",
  //           "confidence": 0.88,
  //         },
  //       ],
  //       confidence: 0.9,
  //     );
  //   } else if (lower.contains("risk") && lower.contains("founder")) {
  //     _addMockAIMessage(
  //       answer:
  //           "Founder risk often manifests through inconsistent messaging or inflated growth claims. In our behavioral intelligence model, low response latency and overuse of qualifiers (e.g., 'we might', 'we plan to') reduce credibility scores by up to 23%. Balanced confidence, clarity, and specificity correlate with higher funding success probability.",
  //       evidence: [
  //         {
  //           "snippet":
  //               "Behavioral AI model trained on 3,000 founder transcripts shows correlation between language precision and funding outcomes (Google Research, 2025).",
  //           "type": "research",
  //           "location": "https://research.google/pubs/founder-behavior-ai/",
  //           "confidence": 0.94,
  //         },
  //       ],
  //       confidence: 0.93,
  //     );
  //   } else {
  //     _addMockAIMessage(
  //       answer:
  //           "I couldn’t find specific evidence on that query. Please refine your question or specify a startup name for better context.",
  //       evidence: [],
  //       confidence: 0.5,
  //     );
  //   }

  //   // End mock path early — skip real API call
  //   setState(() => _isLoading = false);
  //   _scrollToBottom();
  //   return;
  //  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF36B21);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [accent, Color(0xFFFB8441)],
              ).createShader(bounds),
          child: Text(
            "Lumora",
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 76, vertical: 32),
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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  final isUser = msg["isUser"];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment:
                          isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [accent, Color(0xFFFB8441)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? const Color(0xFFF3F4F6)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg["message"],
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),

                                if (!isUser && msg["confidence"] != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.psychology,
                                        size: 16,
                                        color: accent.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Confidence: ${(msg["confidence"] * 100).toInt()}%",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: accent.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (!isUser &&
                                    msg["evidence"] != null &&
                                    (msg["evidence"] as List).isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accent.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.source_outlined,
                                              size: 16,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Sources",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...((msg["evidence"] as List).map(
                                          (e) => Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e["text"],
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 12,
                                                  top: 4,
                                                  bottom: 8,
                                                ),
                                                child: Text(
                                                  e["meta"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Thinking...",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.inter(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Ask me about this startup...",
                          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              _controller.text.trim().isEmpty
                                  ? [Colors.grey[300]!, Colors.grey[400]!]
                                  : [accent, const Color(0xFFFB8441)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.white,
                        onPressed:
                            _controller.text.trim().isEmpty
                                ? null
                                : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "Powered by Flash2.5",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "You", "message": text, "isUser": true});
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/v1/ask/grounded");
      final payload = {"question": text, "startup_id": widget.startupId};

      print("Sending grounded AI query for startup: ${widget.startupId}");
      print("Payload: ${jsonEncode(payload)}");

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-Key': 'dev-secret',
        },
        body: jsonEncode(payload),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final answer =
            data["answer"] ??
            "No clear answer found. Try rephrasing your question.";
        final confidence =
            data["confidence"]?.toString().toLowerCase() ?? "unknown";

        // Extract citations and context for evidence display
        final citations = (data["citations"] as List?) ?? [];
        final contextUsed = (data["context_used"] as List?) ?? [];

        //Format Evidence List
        final formattedEvidence = [
          ...citations.map((c) {
            final snippet = c["snippet"] ?? "";
            final source = c["source"] ?? "unknown";
            final page = c["page"];
            return {
              "text": "• ${_extractSnippet(snippet)}",
              "meta":
                  "${source.toString().toUpperCase()}${page != null ? " (p.$page)" : ""}",
              "confidence": 1.0,
            };
          }),
          ...contextUsed.map((ctx) {
            final type = ctx["type"] ?? "context";
            final page = ctx["page"];
            return {
              "text": "Referenced $type",
              "meta":
                  "From ${type.toString().toUpperCase()}${page != null ? " (p.$page)" : ""}",
              "confidence": 0.7,
            };
          }),
        ];

        setState(() {
          _messages.add({
            "sender": "Lumora AI",
            "message": answer,
            "isUser": false,
            "confidence": _mapConfidence(confidence),
            "evidence": formattedEvidence,
          });
        });
      } else {
        final err =
            jsonDecode(response.body)["detail"] ?? "Unknown server error";
        setState(() {
          _messages.add({
            "sender": "Lumora AI",
            "message": "⚠️ Error ${response.statusCode}: $err",
            "isUser": false,
            "isError": true,
          });
        });
      }
    } catch (e, st) {
      print("AIChatScreen API error: $e\n$st");
      setState(() {
        _messages.add({
          "sender": "Lumora AI",
          "message": "Something went wrong while fetching AI response.",
          "isUser": false,
          "isError": true,
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // --- Helper: extract readable snippet text from JSON string ---
  String _extractSnippet(dynamic rawSnippet) {
    if (rawSnippet == null) return "";
    try {
      final parsed = jsonDecode(rawSnippet);
      if (parsed is Map && parsed.containsKey("metrics")) {
        return "ARR: ${parsed["metrics"]["arr"] ?? "N/A"}";
      }
    } catch (_) {
      // ignore invalid JSON, just return the string
    }
    return rawSnippet.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // --- Helper: map textual confidence to numeric (0.0–1.0) ---
  double _mapConfidence(String conf) {
    switch (conf.toLowerCase()) {
      case "high":
        return 0.9;
      case "medium":
        return 0.7;
      case "low":
        return 0.5;
      default:
        return 0.6;
    }
  }
}
