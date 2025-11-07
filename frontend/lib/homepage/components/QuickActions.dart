import 'package:flutter/material.dart';
import 'package:lumora/aiInsights/AIChatScreen_new.dart';
import 'package:lumora/aiInsights/MarketRadar.dart';
import 'package:lumora/aiInsights/VideoAnalyser.dart';
import 'package:lumora/config/ApiConfig.dart';
import 'package:lumora/savedDeals/SavedDeals.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const Color kCard = Colors.white;
const Color kAccent = Color(0xFFFF6B2C);
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        "title": "News and Regulations",
        "icon": Icons.add_circle_outline,
        "hint": "Seal the deal!",
      },
      {
        "title": "Compare Deals",
        "icon": Icons.bar_chart,
        "hint": "Check your stats!",
      },
      {"title": "AI Chat", "icon": Icons.chat, "hint": "Spot opportunities!"},
      {
        "title": "Video Analysis",
        "icon": Icons.video_camera_front,
        "hint": "Analyze videos in seconds!",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine number of columns based on available width
            int crossAxisCount = 2;
            double width = constraints.maxWidth;
            if (width > 1200) {
              crossAxisCount = 4;
            } else if (width > 800) {
              crossAxisCount = 3;
            }

            // Adjust child aspect ratio based on width
            double childAspectRatio = width / (crossAxisCount * 120);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children:
                  actions.map((a) => _AnimatedActionCard(action: a)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedActionCard extends StatefulWidget {
  final Map<String, dynamic> action;
  const _AnimatedActionCard({required this.action});

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    _controller.forward();
    setState(() => _hovering = true);
  }

  void _onExit(PointerEvent _) {
    _controller.reverse();
    setState(() => _hovering = false);
  }

  void _handleTap(BuildContext context) {
    final title = widget.action['title'];
    if (title == 'News and Regulations') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegulatoryMarketRadarPage()),
      );
    } else if (title == 'Compare Deals') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PortfolioPage()),
      );
    } else if (title == 'AI Chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AIChatScreen(startupId: "1")),
      );
    } else if (title == 'Video Analysis') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoAnalyzerPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder:
              (context, child) =>
                  Transform.scale(scale: _scaleAnim.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hovering ? 0.12 : 0.06),
                  blurRadius: _hovering ? 18 : 10,
                  offset: Offset(0, _hovering ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: _hovering ? kAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'], size: 28, color: kAccent),
                const SizedBox(height: 6),
                Text(
                  action['title'],
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_hovering)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      action['hint'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
