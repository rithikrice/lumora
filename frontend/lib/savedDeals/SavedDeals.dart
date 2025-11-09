import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Comparison.dart';
import 'package:lumora/config/ApiConfig.dart';

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

const Color kAccent = Color(0xFFFF6B2C);
const Color kAccentBlue = Color.fromARGB(255, 62, 44, 255);
const Color kBackground = Color(0xFFFDFBF9);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

const double kCardRadius = 20.0;

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEDE0), Colors.white, Color(0xFFFFEDE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: kAccent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Portfolio & Saved Deals',
            style: TextStyle(
              color: kBackground,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAccent))
                : _error != null
                ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      ..._allStartups.map((s) => _buildRow(s)).toList(),
                    ],
                  ),
                ),
        floatingActionButton: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            backgroundColor: selectedIds.isEmpty ? Colors.grey[400] : kAccent,
            onPressed:
                selectedIds.isEmpty
                    ? null
                    : () {
                      final selectedStartups =
                          _allStartups
                              .where((s) => selectedIds.contains(s.id))
                              .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ComparisonPage(startups: selectedStartups),
                        ),
                      );
                    },
            icon: const Icon(Icons.compare_arrows, color: Colors.white),
            label: Text(
              'Compare (${selectedIds.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          SizedBox(width: 36),
          Expanded(flex: 4, child: Text('Startup', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Stage', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Score', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildRow(Startup s) {
    final isSelected = selectedIds.contains(s.id);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _toggleSelection(s.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color:
                    isSelected
                        ? kAccent.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                blurRadius: isSelected ? 6 : 2,
              ),
            ],
            border: Border.all(
              color: isSelected ? kAccent.withOpacity(0.5) : Colors.transparent,
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
                  activeColor: kAccent,
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kAccent.withOpacity(0.15),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0] : "?",
                        style: const TextStyle(
                          color: kAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        s.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  s.stage,
                  style: const TextStyle(color: kTextSecondary),
                ),
              ),
              Expanded(flex: 2, child: _AnimatedScoreBar(score: s.score)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedScoreBar extends StatelessWidget {
  final int score;
  const _AnimatedScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [kAccentBlue, kAccent],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  gradient: gradient,
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
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  color: kTextPrimary,
  fontWeight: FontWeight.w800,
  fontSize: 14,
);
