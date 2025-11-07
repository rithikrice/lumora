// lib/homepage/components/NotificationPanel.dart
import 'package:flutter/material.dart';
import 'package:lumora/homepage/theme.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> alerts = [
      "⚠ HealthAI churn rate inconsistent",
      "📊 FinTechX raised competitor funding",
      "🚨 AgroNext flagged high burn rate",
    ];

    return Semantics(
      container: true,
      label: 'Notifications Panel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: heading(22)),
          const SizedBox(height: 12),
          Column(
            children:
                alerts.asMap().entries.map((e) {
                  return _AlertCard(
                    message: e.value,
                    delayMs: (e.key + 1) * 140,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final String message;
  final int delayMs;
  const _AlertCard({required this.message, this.delayMs = 80});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover ? kAccent.withOpacity(0.08) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.10 : 0.04),
                blurRadius: _hover ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.notifications, color: kAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: bodyStyle(14).copyWith(color: kTextPrimary),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _hover ? 12 : 8,
                height: _hover ? 12 : 8,
                decoration: BoxDecoration(
                  color: kAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
