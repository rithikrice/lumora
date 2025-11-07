import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/aiInsights/AIChatScreen_new.dart';
import 'package:lumora/homepage/theme.dart';

class SidebarNav extends StatefulWidget {
  final String activeSection;
  final Function(String) onSelect;
  final String startupId;

  const SidebarNav({
    super.key,
    required this.activeSection,
    required this.onSelect,
    required this.startupId,
  });

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> {
  String? hoveredItem;

  final sections = {
    "Profile": {Icons.business_outlined: "Company Profile"},
    "Analysis": {
      Icons.insights_outlined: "Investment Highlights",
      Icons.trending_up_outlined: "KPI BenchMarks",
    },
    "Updates": {Icons.update_outlined: "Activity Timeline"},
    "AI Magic": {
      Icons.auto_awesome_outlined: "AI Insights",
      Icons.psychology_outlined: "Growth Simulations",
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children:
                  sections.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...entry.value.entries.map((iconEntry) {
                          final icon = iconEntry.key;
                          final label = iconEntry.value;
                          final bool selected = widget.activeSection == label;
                          final bool isHovered = hoveredItem == label;

                          return MouseRegion(
                            onEnter: (_) => setState(() => hoveredItem = label),
                            onExit: (_) => setState(() => hoveredItem = null),
                            child: GestureDetector(
                              onTap: () => widget.onSelect(label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color:
                                      selected
                                          ? kAccent.withOpacity(0.10)
                                          : isHovered
                                          ? kAccent.withOpacity(0.05)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        selected
                                            ? kAccent.withOpacity(0.35)
                                            : Colors.transparent,
                                    width: 1,
                                  ),
                                  boxShadow:
                                      selected
                                          ? [
                                            BoxShadow(
                                              color: kAccent.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : [],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        height: 6,
                                        width: 6,
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              selected
                                                  ? kAccent
                                                  : Colors.transparent,
                                        ),
                                      ),
                                      Icon(
                                        icon,
                                        size: 18,
                                        color:
                                            selected
                                                ? kAccent
                                                : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: GoogleFonts.inter(
                                            fontSize: 14.5,
                                            fontWeight:
                                                selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color:
                                                selected
                                                    ? kAccent
                                                    : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),
            ),
          ),

          // Floating ASK AI Button
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AIChatScreen(startupId: widget.startupId),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAccent.withOpacity(0.9),
                        kAccent.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ask Lumora AI',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
