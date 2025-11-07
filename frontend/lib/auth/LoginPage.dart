import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/homepage/HomePage.dart';

/// --- Brand Colors ---
const Color kBackground = Color(0xFFF9F6F5); // softer cream
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kAccent = Color.fromARGB(255, 218, 67, 3);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageProState();
}

class _LoginPageProState extends State<LoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _fieldsFade;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _fieldsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 80),
      () => _entranceController.forward(),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LumoraHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Image.asset(
            'background.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const _Branding(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fieldsFade,
                    child: _LoginCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocus: _emailFocus,
                      passFocus: _passFocus,
                      onLogin: _onLoginPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --- Branding with Gradient Text
class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [kAccent, const Color.fromARGB(255, 247, 83, 34)],
              ).createShader(bounds),
          child: Text(
            'Lumora',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Text(
          'AI insights for high-conviction decisions',
          style: GoogleFonts.inter(
            textStyle: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// --- Login Card (Glassmorphism)
class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passFocus;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passFocus,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = min(MediaQuery.of(context).size.width * 0.9, 420.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Sign in to your account',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _InputField(
                controller: emailController,
                focusNode: emailFocus,
                hint: "Email address",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: passwordController,
                focusNode: passFocus,
                hint: "Password",
                obscure: true,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot password?",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LoginButton(onPressed: onLogin),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Get started",
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- Inputs (Glass + glow)
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.inter(color: kTextPrimary),
      cursorColor: kAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: kTextSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent, width: 1.6),
        ),
      ),
    );
  }
}

/// --- Gradient Button
class _LoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LoginButton({required this.onPressed});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAccent, const Color.fromARGB(255, 245, 82, 32)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    "Login",
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: 1.2,
                    child: Transform.translate(
                      offset: Offset(_shineController.value * 200 - 100, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(
                                255,
                                251,
                                192,
                                153,
                              ).withOpacity(0.0),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
