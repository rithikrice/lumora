// lib/homepage/HomePage.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lumora/homepage/components/LaederBoard.dart';
import 'package:lumora/homepage/theme.dart';
import 'package:lumora/homepage/components/TopNavBar.dart';
import 'package:lumora/homepage/components/HeroBanner.dart';
import 'package:lumora/homepage/components/QuickActions.dart';
import 'package:lumora/homepage/components/NotificationPanel.dart';
import 'package:lumora/homepage/components/RecentDeals.dart';
import 'package:lumora/homepage/components/MarketRadar.dart';

class LumoraHomePage extends StatelessWidget {
  const LumoraHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // subtle background gradient for depth
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEF8F6), Color(0xFFFFFBF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // sticky top nav
          const Positioned(top: 0, left: 0, right: 0, child: TopNavBar()),

          // Body (leave space for Nav)
          Positioned.fill(
            top: 84,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: StaggeredFadeIn(
                              delayMs: 80,
                              child: const HeroBanner(),
                            ),
                          ),
                          SizedBox(
                            width: isWide ? 20 : 0,
                            height: isWide ? 0 : 20,
                          ),
                          Flexible(
                            flex: 1,
                            child: StaggeredFadeIn(
                              delayMs: 240,
                              child: const QuickActions(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: StaggeredFadeIn(
                              delayMs: 480,
                              child: const RecentDeals(),
                            ),
                          ),
                          SizedBox(width: 20),
                          // Notifications
                          Expanded(
                            flex: 1,
                            child: StaggeredFadeIn(
                              delayMs: 360,
                              child: const NotificationsPanel(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Radar + Leaderboard (two-column responsive)
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: StaggeredFadeIn(
                              delayMs: 600,
                              child: const MarketRadar(),
                            ),
                          ),
                          SizedBox(
                            width: isWide ? 20 : 0,
                            height: isWide ? 0 : 20,
                          ),
                          Flexible(
                            flex: 1,
                            child: StaggeredFadeIn(
                              delayMs: 760,
                              child: const Leaderboard(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),
                      // Footer small
                      Center(
                        child: Text(
                          '© ${DateTime.now().year} Lumora — Built for investors',
                          style: bodyStyle(13),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
