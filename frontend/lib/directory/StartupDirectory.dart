import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lumora/config/ApiConfig.dart';
import 'package:lumora/startupProfile/StartupProfileMain.dart';

// Model
class Startup {
  final String id;
  final String name;
  final String sector;
  final String geography;
  final String funding;

  Startup({
    required this.id,
    required this.name,
    required this.sector,
    required this.geography,
    required this.funding,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['startup_id'] ?? '',
      name: json['name'] ?? '',
      sector: json['sector'] ?? '',
      geography: json['geography'] ?? '',
      funding: json['funding_stage'] ?? '',
    );
  }
}

class StartupDirectoryPage extends StatefulWidget {
  const StartupDirectoryPage({super.key});

  @override
  State<StartupDirectoryPage> createState() => _StartupDirectoryPageState();
}

class _StartupDirectoryPageState extends State<StartupDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Startup> _allStartups = [];
  List<String> _sectors = ["All"];
  List<String> _geographies = ["All"];
  String _selectedSector = "All";
  String _selectedGeo = "All";
  String? _error;

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
        final sectorsJson = decoded['sectors'] as List<dynamic>;
        final geosJson = decoded['geographies'] as List<dynamic>;

        setState(() {
          _allStartups = startupsJson.map((e) => Startup.fromJson(e)).toList();
          _sectors = ["All", ...sectorsJson.cast<String>()];
          _geographies = ["All", ...geosJson.cast<String>()];
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

  List<Startup> get _filteredStartups {
    final query = _searchController.text.toLowerCase();
    return _allStartups.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(query);
      final matchesSector =
          _selectedSector == "All" || s.sector == _selectedSector;
      final matchesGeo = _selectedGeo == "All" || s.geography == _selectedGeo;
      return matchesSearch && matchesSector && matchesGeo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Startup Directory",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStartups,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 🔍 Search + Filters
                    _buildFilters(),
                    const SizedBox(height: 12),
                    // 📊 Table
                    Expanded(child: _buildTable()),
                  ],
                ),
              ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search startups...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSector,
                  decoration: InputDecoration(
                    labelText: "Sector",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items:
                      _sectors
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedSector = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGeo,
                  decoration: InputDecoration(
                    labelText: "Geography",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items:
                      _geographies
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedGeo = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final filtered = _filteredStartups;
    if (filtered.isEmpty) {
      return const Center(child: Text("No startups found"));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Name",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Sector",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Geography",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Funding",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 0),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder:
                  (_, __) => Divider(height: 0, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final s = filtered[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StartupProfilePage(startupId: s.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(s.name)),
                        Expanded(flex: 2, child: Text(s.sector)),
                        Expanded(flex: 2, child: Text(s.geography)),
                        Expanded(flex: 2, child: Text(s.funding)),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
