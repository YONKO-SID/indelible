// =============================================================================
// LOGIN SCREEN — The first screen users see.
//
// ARCHITECTURE NOTES:
// ─────────────────────────────────────────────────────────────────────
// This screen is a StatefulWidget because it manages:
//   1. isSignUp — which tab is active (sign up vs sign in)
//   2. _isLoading — whether a Firebase call is in progress
//   3. _isPasswordVisible — eye icon toggle for password field
//   4. TextEditingControllers — hold form field values
//
// It talks to AuthService for all Firebase operations.
// It does NOT import firebase_auth directly — separation of concerns.
//
// PATTERN: Screen → Service → Firebase
//   LoginScreen._handleSubmit() → AuthService.signUpWithEmail() → Firebase
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

// Card width — extracted as a constant so it's easy to find and change
const double _kCardWidth = 440;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ══════════════════════════════════════════════════════════════════
  // STATE VARIABLES
  // ══════════════════════════════════════════════════════════════════

  bool isSignUp = true;         // true = "Create account" mode, false = "Sign in" mode
  bool _isLoading = false;       // true while waiting for Firebase response
  bool _isPasswordVisible = false; // toggles password field visibility

  // Controllers hold the text the user types. You READ from them (controller.text)
  // and MUST dispose them when the screen is destroyed to prevent memory leaks.
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // The auth service — one instance per screen is fine
  final _authService = AuthService();

  // ══════════════════════════════════════════════════════════════════
  // COLOR PALETTE — Your exact design colors
  // ══════════════════════════════════════════════════════════════════

  static const Color _bgColor = Color(0xFF0A0A0A);       // Deepest background
  static const Color _surfaceColor = Color(0xFF161618);   // Card surface
  static const Color _inputColor = Color(0xFF1E1E20);     // Input field fill
  static const Color _borderColor = Color(0xFF2C2C2E);    // Subtle borders

  // ══════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    // CRITICAL: Always dispose controllers!
    // If you forget, the TextEditingController keeps listening to the
    // text field even after the screen is gone = memory leak.
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // AUTH HANDLERS — What happens when the user taps buttons
  // ══════════════════════════════════════════════════════════════════

  /// Called when the user taps "Create an account" or "Sign in"
  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation — don't hit Firebase with empty fields
    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    // Set loading state — this shows a spinner on the button
    setState(() => _isLoading = true);

    try {
      if (isSignUp) {
        // SIGN UP FLOW
        final name = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim();
        await _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : null,
        );
      } else {
        // SIGN IN FLOW
        await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      }
      // If we get here, auth succeeded — navigate to dashboard
      _navigateToDashboard();
    } catch (e) {
      // Firebase throws specific error messages like:
      //   "The email address is already in use"
      //   "The password is too weak"
      //   "No user found with this email"
      // We display them directly to the user.
      _showError(_getFirebaseErrorMessage(e));
    } finally {
      // Always stop the loading spinner, even if there was an error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Called when the user taps the Google button
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _navigateToDashboard();
      }
    } catch (e) {
      _showError(_getFirebaseErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigate to dashboard and remove login from the stack
  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardScreen()),
      (route) => false,
    );
  }

  /// Show a snackbar with an error message
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Converts Firebase exception codes into human-readable messages
  String _getFirebaseErrorMessage(dynamic error) {
    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('email-already-in-use')) return 'This email is already registered';
      if (msg.contains('weak-password')) return 'Password must be at least 6 characters';
      if (msg.contains('invalid-email')) return 'Please enter a valid email address';
      if (msg.contains('user-not-found')) return 'No account found with this email';
      if (msg.contains('wrong-password')) return 'Incorrect password';
      if (msg.contains('too-many-requests')) return 'Too many attempts. Please try later';
    }
    return 'Something went wrong. Please try again.';
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD METHOD — The main UI
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: _kCardWidth,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabToggle(),
                const SizedBox(height: 32),

                // ── Logo ──
                Center(
                  child: Column(
                    children: [
                      // We will use a fallback icon in case the image isn't saved yet, but we will look for the image
                      Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.fingerprint, size: 80, color: Colors.white24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "INDELIBLE",
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFC06CFF), // matched the purple from the logo
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        "A mark indestructible",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00D4FF), // matched the cyan from the logo
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ── Heading ──
                Text(
                  isSignUp ? "Create an account" : "Welcome back",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Name Fields (Sign Up only) ──
                if (isSignUp) ...[
                  Row(
                    children: [
                      Expanded(child: _buildInputField("First name", controller: _firstNameController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField("Last name", controller: _lastNameController)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Email Field ──
                _buildInputField(
                  "Enter your email",
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // ── Password Field ──
                _buildInputField(
                  "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 24),

                // ── Primary Button ──
                _buildPrimaryButton(),

                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSocialButtons(),
                const SizedBox(height: 20),

                // ── Terms Text ──
                Center(
                  child: Text(
                    "By creating an account, you agree to our Terms & Service",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // UI COMPONENTS — Each extracted into its own method for readability
  // ══════════════════════════════════════════════════════════════════

  /// The pill-shaped Sign Up / Sign In toggle at the top of the card
  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab("Sign up", isActive: isSignUp, onTap: () => setState(() => isSignUp = true)),
          _buildTab("Sign in", isActive: !isSignUp, onTap: () => setState(() => isSignUp = false)),
        ],
      ),
    );
  }

  /// A single tab in the toggle — AnimatedContainer smoothly transitions colors
  Widget _buildTab(String text, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// A reusable input field with consistent dark styling
  Widget _buildInputField(
    String hint, {
    IconData? icon,
    bool isPassword = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        // textInputAction tells the keyboard what the "enter" button does:
        //   TextInputAction.next → moves focus to the next field
        //   TextInputAction.done → closes the keyboard (use on the last field)
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
          // Show/hide password toggle — only for password fields
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// The main CTA button — shows a loading spinner while auth is in progress
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // Disable the button while loading to prevent double-taps
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            // AnimatedSwitcher would be smoother here, but this is simpler for now
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text(
                isSignUp ? "Create an account" : "Sign in",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// The "OR SIGN IN WITH" divider between primary and social buttons
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _borderColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("OR SIGN IN WITH", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(child: Container(height: 1, color: _borderColor)),
      ],
    );
  }

  /// Google and Apple sign-in buttons side by side
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata, // Placeholder — replace with Google SVG later
            label: "Google",
            onTap: _handleGoogleSignIn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: "Apple",
            onTap: () {
              // Apple Sign-In requires an Apple Developer account ($99/year)
              // Skip for hackathon MVP — just show a coming soon message
              _showError("Apple Sign-In coming soon");
            },
          ),
        ),
      ],
    );
  }

  /// A single social sign-in button
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}