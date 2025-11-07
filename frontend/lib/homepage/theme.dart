// lib/homepage/theme.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAccent = Color.fromARGB(255, 62, 44, 255);
const Color kBackground = Color(0xFFFDFBF9);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);

TextStyle brandTitle([double size = 28]) => GoogleFonts.poppins(
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: kTextPrimary,
);

TextStyle heading([double size = 20]) => GoogleFonts.inter(
  fontSize: size,
  fontWeight: FontWeight.w600,
  color: kTextPrimary,
);

TextStyle bodyStyle([double size = 14]) =>
    GoogleFonts.poppins(fontSize: size, color: kTextSecondary);

/// Small helper: staggered fade+slide for entrance animations.
/// Usage: wrap the widget with StaggeredFadeIn(delayMs: 120, child: ...)
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset beginOffset;

  const StaggeredFadeIn({
    required this.child,
    this.delayMs = 120,
    this.duration = const Duration(milliseconds: 600),
    this.beginOffset = const Offset(0, 0.04),
    super.key,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Timer(Duration(milliseconds: widget.delayMs), () {
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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
