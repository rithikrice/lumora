import 'package:flutter/material.dart';
import 'package:lumora/config/ApiConfig.dart';
import 'Comparison.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color bgPrimary = Color(0xFFF2F4F7);
const Color cardColor = Colors.white;
const Color accent = Color(0xFFFF6B2C);
const Color textPrimary = Color(0xFF1C1C1E);
const Color textSecondary = Color(0xFF6C6C80);
const double cardRadius = 16.0;

class Startup {
  final String id;
  final String name;
  final String sector;
  final String geography;
  final String funding;
  final String stage;
  final int score;
  final String lastUpdated;
  final List<RiskTag> risks;
  Startup({
    required this.id,
    required this.name,
    required this.sector,
    required this.geography,
    required this.funding,
    required this.stage,
    required this.score,
    required this.lastUpdated,
    required this.risks,
  });
  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['startup_id'] ?? '',
      name: json['name'] ?? '',
      sector: json['sector'] ?? '',
      geography: json['geography'] ?? '',
      funding: json['funding_stage'] ?? '',
      stage: json['funding_stage'] ?? '',
      score: (json['score'] ?? 0).toInt(),
      lastUpdated: json['last_updated'] ?? '-',
      risks:
          (json['risks'] as List<dynamic>? ?? [])
              .map((r) => RiskTag.fromJson(r))
              .toList(),
    );
  }
}

class RiskTag {
  final String name;
  final Color color;
  RiskTag({required this.name, required this.color});
  factory RiskTag.fromJson(Map<String, dynamic> json) {
    final severity = json['severity'] ?? 'low';
    Color color;
    switch (severity) {
      case 'high':
        color = Colors.redAccent;
        break;
      case 'medium':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.green;
    }
    return RiskTag(name: json['type'] ?? 'Risk', color: color);
  }
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});
  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  List<Startup> _allStartups = [];
  Set<String> selectedIds = {};
  String? _error;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchStartups();
  }

  Future<void> _fetchStartups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/v1/ui/startup-directory?limit=50&offset=0",
    );
    try {
      final response = await http.get(
        url,
        headers: {'accept': 'application/json', 'X-API-Key': 'dev-secret'},
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final startupsJson = decoded['startups'] as List<dynamic>;
        setState(() {
          _allStartups = startupsJson.map((e) => Startup.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _error = "Failed to fetch data (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        if (selectedIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare a maximum of 3 startups.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        title: const Text(
          'Portfolio & Saved Deals',
          style: TextStyle(
            color: bgPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const SizedBox(height: 16),
                    ..._allStartups.map((s) => _buildTableRow(s)).toList(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final selectedStartups =
              _allStartups.where((s) => selectedIds.contains(s.id)).toList();
          if (selectedStartups.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Select at least one startup to compare.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonPage(startups: selectedStartups),
            ),
          );
        },
        label: Text(
          'Compare (${selectedIds.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.compare_arrows),
        backgroundColor: accent,
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E5), Color(0xFFFFE6CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: const [
          SizedBox(width: 36),
          Expanded(flex: 3, child: Text('Startup', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Stage', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Score', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Last Updated', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Risks', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildTableRow(Startup s) {
    final isSelected = selectedIds.contains(s.id);
    return GestureDetector(
      onTap: () => _toggleSelection(s.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(s.id),
                activeColor: accent,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0] : "?",
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.name,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                s.stage,
                style: const TextStyle(color: textSecondary),
              ),
            ),
            Expanded(flex: 2, child: _ScoreBar(score: s.score)),
            Expanded(
              flex: 3,
              child: Text(
                s.lastUpdated,
                style: const TextStyle(color: textSecondary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 6,
                children:
                    s.risks
                        .map(
                          (r) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: r.color.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  const _ScoreBar({required this.score});
  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (score > 75) {
      barColor = Colors.greenAccent.shade400;
    } else if (score > 50) {
      barColor = Colors.orangeAccent.shade400;
    } else {
      barColor = Colors.redAccent.shade400;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  color: textPrimary,
  fontWeight: FontWeight.w700,
  fontSize: 14,
);
