// lib/homepage/components/HeroBanner.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lumora/directory/StartupDirectory.dart';
import 'package:lumora/homepage/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/startupProfile/ExecutiveSummary.dart';
import 'package:lumora/upload/DocumentUploadScreen.dart';
import 'package:lumora/upload/UploadIngestion.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});
  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  Color kAccent = Color(0xFFFF6B2C);
  Color kBackground = Color(0xFFFDFBF9);
  Color kCard = Colors.white;
  Color kTextPrimary = Color(0xFF0D1724);
  Color kTextSecondary = Color(0xFF6B7280);
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Hero banner: Welcome back and quick actions',
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kAccent.withOpacity(0.95), Colors.deepOrange.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kAccent.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + subtitle
            Text(
              'Welcome back!',
              style: bodyStyle(18).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Lumora is a  — investor-grade intelligence',
              style: brandTitle(26).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Lumora an AI investment associate that ingests founder materials and public signals, benchmarks startups against peers, uncovers hidden risks with explainable evidence, and outputs investor-ready deal notes, scorecards and draft term-sheet items — all powered by Google AI.',
              style: bodyStyle(
                14,
              ).copyWith(color: Colors.white.withOpacity(0.95), height: 1.45),
            ),
            const SizedBox(height: 20),

            // CTA row
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StartupDirectoryPage(),
                        // StartupProfilePage()
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kTextPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Deals',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            // navigate to the page to upload new startup documents
                            (_) => DocumentUploadScreen(),
                        // StartupRegistrationForm(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: kAccent2,
                  ),
                  child: Text(
                    'Upload New Startup',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // subtle decorative animated orb
                Expanded(child: Container()),
                SizedBox(
                  width: 68,
                  height: 68,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) {
                      final v = _c.value;
                      return Transform.rotate(
                        angle: v * pi * 2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.18),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.06),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.show_chart,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
