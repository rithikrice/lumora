import 'package:flutter/material.dart';

// --- Theme tokens ---
const Color kAccent1 = Color(0xFFFF6B2C); // orange
const Color kAccent2 = Color(0xFF3E2CFF); // sapphire blue
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class NotificationItem {
  final String id;
  final String type; // Funding, Growth, Partnership, Product, Media
  final String severity; // Critical, Warning, Info, Positive
  final String title;
  final String description;
  final DateTime date;

  NotificationItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.date,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _VCNotificationsPageState();
}

class _VCNotificationsPageState extends State<NotificationsPage> {
  // Your NotificationItem data remains unchanged
  final List<NotificationItem> allNotifications = [
    NotificationItem(
      id: 'n1',
      type: 'Funding',
      severity: 'Critical',
      title: 'Series A Closed — HealthAI',
      description:
          'HealthAI raised \$15M led by Sequoia; strong traction in chronic care vertical.',
      date: DateTime.now(),
    ),
    NotificationItem(
      id: 'n2',
      type: 'Growth',
      severity: 'Positive',
      title: '40% MoM Active User Growth — FinTechX',
      description:
          'Organic growth + referral campaigns drove spike; retention holding steady.',
      date: DateTime.now(),
    ),
    NotificationItem(
      id: 'n3',
      type: 'Partnership',
      severity: 'Info',
      title: 'Strategic Cloud Partnership — AgroNext',
      description:
          'AgroNext partners with Microsoft to accelerate AI crop analytics go-to-market.',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: 'n4',
      type: 'Product',
      severity: 'Warning',
      title: 'Product Launch Delayed — EduTechPro',
      description:
          'AI tutor regulatory review pushed beta launch by ~8 weeks; watch runway impact.',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: 'n5',
      type: 'Media',
      severity: 'Info',
      title: 'Featured: CryptoSafe in TechCrunch',
      description:
          'CryptoSafe spotlighted for fraud detection — good PR for series A momentum.',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NotificationItem(
      id: 'n6',
      type: 'Team',
      severity: 'Critical',
      title: 'Founder Resignation — RetailBot',
      description:
          'Co-founder resigned abruptly; interim leadership changes announced.',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  String selectedType = 'All';
  String selectedSeverity = 'All';
  String searchQuery = '';

  List<String> get availableTypes {
    final set = <String>{};
    for (var n in allNotifications) set.add(n.type);
    return ['All', ...set.toList()..sort()];
  }

  List<String> get availableSeverities {
    final set = <String>{};
    for (var n in allNotifications) set.add(n.severity);
    return ['All', ...set.toList()..sort()];
  }

  List<NotificationItem> get filteredNotifications {
    return allNotifications.where((n) {
      if (selectedType != 'All' && n.type != selectedType) return false;
      if (selectedSeverity != 'All' && n.severity != selectedSeverity)
        return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!n.title.toLowerCase().contains(q) &&
            !n.description.toLowerCase().contains(q) &&
            !n.type.toLowerCase().contains(q))
          return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<NotificationItem>> groupNotifications(
    List<NotificationItem> list,
  ) {
    final Map<String, List<NotificationItem>> m = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    final now = DateTime.now();
    for (var n in list) {
      final d = n.date;
      final diff =
          DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(DateTime(d.year, d.month, d.day)).inDays;
      if (diff == 0)
        m['Today']!.add(n);
      else if (diff == 1)
        m['Yesterday']!.add(n);
      else
        m['Earlier']!.add(n);
    }
    return m;
  }

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange;
      case 'positive':
        return Colors.green;
      case 'info':
      default:
        return kAccent2;
    }
  }

  Color typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'funding':
        return kAccent1;
      case 'growth':
        return kAccent2;
      case 'partnership':
        return Colors.green.shade700;
      case 'product':
        return Colors.purple;
      case 'media':
        return Colors.blueGrey;
      case 'team':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupNotifications(filteredNotifications);

    return Scaffold(
      body: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  _countBadge(filteredNotifications.length),
                ],
              ),
              const SizedBox(height: 16),

              // --- Filters & Search ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: _dropdownFilter(
                      label: "Type",
                      value: selectedType,
                      items: availableTypes,
                      onChanged:
                          (v) => setState(() => selectedType = v ?? 'All'),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _dropdownFilter(
                      label: "Severity",
                      value: selectedSeverity,
                      items: availableSeverities,
                      onChanged:
                          (v) => setState(() => selectedSeverity = v ?? 'All'),
                    ),
                  ),
                  SizedBox(width: 300, child: _searchField()),
                ],
              ),
              const SizedBox(height: 16),

              // --- Notification list ---
              Expanded(
                child: ListView(
                  children: [
                    for (var section in ['Today', 'Yesterday', 'Earlier'])
                      if ((grouped[section] ?? []).isNotEmpty) ...[
                        _sectionHeader(section),
                        ...grouped[section]!.map(_buildCard),
                      ],
                    if (filteredNotifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Text(
                            'No notifications',
                            style: TextStyle(color: kTextSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search startup, title, description...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kTextSecondary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items:
              items
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kAccent1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count Notifications',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: kTextSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCard(NotificationItem n) {
    final Color tColor = typeColor(n.type);
    final Color sColor = severityColor(n.severity);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color.fromARGB(255, 248, 242, 239),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Type and Severity
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    n.type,
                    style: TextStyle(
                      color: tColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    n.severity,
                    style: TextStyle(
                      color: sColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Middle: Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(n.description, style: TextStyle(color: kTextSecondary)),
                  const SizedBox(height: 10),
                  Text(
                    _formatDate(n.date),
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Right: Actions
            Column(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.visibility, color: kTextSecondary),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acknowledged')),
                    );
                  },
                  child: const Text('Acknowledge'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}
