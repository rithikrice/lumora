// lib/homepage/components/TopNavBar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/homepage/HomePage.dart';
import 'package:lumora/homepage/theme.dart';
import 'package:lumora/startupProfile/Notifications.dart';

class TopNavBar extends StatefulWidget {
  const TopNavBar({super.key});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  int _hoverIndex = -1;
  final List<String> _items = ["Settings", "Notifications", "Help"];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.04),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 🔹 Logo + Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LumoraHomePage(),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kAccent.withOpacity(0.95),
                              Colors.deepOrange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kAccent.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'LA',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LumoraHomePage(),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text('Lumora', style: brandTitle(22)),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 🔹 Nav Items (Hover underline + click actions)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children:
                        _items.asMap().entries.map((e) {
                          final idx = e.key;
                          final label = e.value;
                          final hovering = _hoverIndex == idx;

                          return MouseRegion(
                            onEnter: (_) => setState(() => _hoverIndex = idx),
                            onExit: (_) => setState(() => _hoverIndex = -1),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (label == "Notifications") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const NotificationsPage(),
                                    ),
                                  );
                                } else if (label == "Settings") {
                                  // TODO: Navigate to SettingsPage (when ready)
                                } else if (label == "Help") {
                                  // TODO: Navigate to HelpPage (when ready)
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      hovering
                                          ? kAccent.withOpacity(0.06)
                                          : Colors.transparent,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        color:
                                            hovering
                                                ? kAccent
                                                : Color(0xFF6B7280),
                                        fontWeight:
                                            hovering
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      height: 3,
                                      width: hovering ? 28 : 0,
                                      decoration: BoxDecoration(
                                        color: kAccent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
