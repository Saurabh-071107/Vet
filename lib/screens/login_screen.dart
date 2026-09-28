import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../services/session_manager.dart';
import '../services/vet_api_service.dart';

class VetLoginScreen extends StatefulWidget {
  const VetLoginScreen({super.key, required this.onLoginSuccess});
  final VoidCallback onLoginSuccess;

  @override
  State<VetLoginScreen> createState() => _VetLoginScreenState();
}

class _VetLoginScreenState extends State<VetLoginScreen> {
  final _emailController = TextEditingController(text: 'dr.sharma@vetcare.in');
  final _passwordController = TextEditingController(text: 'password123');
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('Please enter your Email ID and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await VetApiService().login(identifier, password);
      if (res['token'] != null && res['user'] != null) {
        await SessionManager().saveSession(
          token: res['token'],
          user: Map<String, dynamic>.from(res['user']),
        );
        widget.onLoginSuccess();
      } else {
        _showMessage('Login failed. Please check your credentials.');
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGovtSsoLogin() async {
    setState(() => _isLoading = true);
    await SessionManager().loginDemoVet();
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= VetAppConstants.tabletBreakpoint;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: VetAppConstants.primaryNavy),
            SizedBox(width: 8),
            Text(
              'Exit Pashu Vet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: VetAppConstants.primaryNavy,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the application?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VetAppConstants.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT (Pixel-perfect matching target mockup with optimal sizing)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        // Dynamically scale artwork to comfortably fill tall screens with zero awkward empty gaps
        final artworkHeight = (viewportHeight * 0.42).clamp(290.0, 400.0);
        final topPadding = MediaQuery.paddingOf(context).top;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewportHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Artwork with Maharashtra Header & Landscape
                  _buildArtworkSection(topPadding: topPadding, height: artworkHeight),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Title
                        const Text(
                          'Veterinarian Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17365F),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Subtitle
                        const Text(
                          'Serve for Healthy Animals\nProsperous Maharashtra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF53647A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Field 1: Email ID
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email ID / ईमेल आयडी',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 13),

                        // Field 2: Password
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password / पासवर्ड',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF8C9BAE),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Remember me & Forgot Password
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFF0965B8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showMessage('Password recovery instructions sent to registered email.'),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0965B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Primary Button: Login / लॉगिन
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0965B8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                  )
                                : const Text(
                                    'Login  /  लॉगिन',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        // "or" divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 9),
                          child: Text(
                            'or',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B7787),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),

                        // Secondary Button: Login with Govt ID (e-Vetyani)
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGovtSsoLogin,
                            icon: const Icon(Icons.badge_outlined, color: Color(0xFF17365F), size: 20),
                            label: const Text(
                              'Login with Govt ID (e-Vetyani)',
                              style: TextStyle(
                                color: Color(0xFF17365F),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF86B7E8), width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // "New to platform? Request Access"
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'New to platform? ',
                                style: TextStyle(
                                  color: Color(0xFF5D6B7C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showRequestAccessDialog(context),
                                child: const Text(
                                  'Request Access',
                                  style: TextStyle(
                                    color: Color(0xFF0965B8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Check status link
                        Center(
                          child: GestureDetector(
                            onTap: () => _showCheckStatusDialog(context),
                            child: const Text(
                              'Already requested? Check Status & Get Password',
                              style: TextStyle(
                                color: Color(0xFF17365F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Flexible spacer to balance layout on tall devices and eliminate dead white space
                  const Spacer(),

                  // Bottom Agricultural Foliage Border (from vt images folder)
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/Gemini_Generated_Image_a29ox5a29ox5a29o-Photoroom.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, _, _) => CustomPaint(
                        painter: _BottomCropFoliagePainter(),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TOP ARTWORK & MAHARASHTRA GOVERNMENT HEADER
  // ---------------------------------------------------------------------------
  Widget _buildArtworkSection({required double topPadding, required double height}) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background landscape: blue Sahyadri hills, morning sun, farmhouse with orange roof
          Image.asset(
            'assets/images/login-banner.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

          // Warm golden/orange fort silhouette accent on the upper-left (from target mockup)
          Positioned(
            left: 12,
            top: topPadding + 6,
            width: 80,
            height: 70,
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(
                painter: _FortSilhouettePainter(color: const Color(0xFFE88A1A)),
              ),
            ),
          ),

          // Foreground cutout: Veterinarian doctor examining the cow (vet-cow-art.png)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.82,
            child: Image.asset(
              'assets/images/vet-cow-art.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // Smooth vertical gradient fade to pure white at bottom (seamless merge into page)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.44,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.40, 0.78, 1.0],
                ),
              ),
            ),
          ),

          // Top Header Row: Emblem + "महाराष्ट्र शासन पशुसंवर्धन विभाग" + Golden Maharashtra Map
          Positioned(
            left: 20,
            right: 20,
            top: topPadding + 10,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Official App Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Ashoka Lion Capital National Emblem
                Image.asset(
                  'assets/images/national_emblem.png',
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.account_balance,
                    color: Color(0xFF17365F),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 10),

                // Bilingual Department Typography
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'महाराष्ट्र शासन',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17365F),
                        letterSpacing: 0.2,
                        height: 1.15,
                        shadows: [Shadow(blurRadius: 6, color: Colors.white)],
                      ),
                    ),
                    Text(
                      'पशुसंवर्धन विभाग',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17365F),
                        letterSpacing: 0.2,
                        height: 1.15,
                        shadows: [Shadow(blurRadius: 6, color: Colors.white)],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Golden Maharashtra State Map Silhouette (from target mockup)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(
                    painter: _MaharashtraMapPainter(color: const Color(0xFFE5A900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDE / DESKTOP LAYOUT (Responsive split screen)
  // ---------------------------------------------------------------------------
  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 720),
        margin: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140E2C4D),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: _buildArtworkSection(topPadding: 24, height: double.infinity),
            ),
            Expanded(
              flex: 9,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 36, color: Color(0xFF0965B8)),
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Veterinarian Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17365F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Serve for Healthy Animals\nProsperous Maharashtra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF53647A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email ID / ईमेल आयडी',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password / पासवर्ड',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF8C9BAE),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF0965B8),
                              onChanged: (v) => setState(() => _rememberMe = v ?? true),
                            ),
                            const Text('Remember me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _showMessage('Password recovery instructions sent to registered email.'),
                              child: const Text('Forgot Password?', style: TextStyle(fontSize: 13, color: Color(0xFF0965B8))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0965B8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Login  /  लॉगिन',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('or', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7787), fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGovtSsoLogin,
                            icon: const Icon(Icons.badge_outlined, color: Color(0xFF17365F)),
                            label: const Text('Login with Govt ID (e-Vetyani)', style: TextStyle(color: Color(0xFF17365F), fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF86B7E8), width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('New to platform? ', style: TextStyle(fontSize: 13, color: Color(0xFF5D6B7C))),
                            GestureDetector(
                              onTap: () => _showRequestAccessDialog(context),
                              child: const Text(
                                'Request Access',
                                style: TextStyle(color: Color(0xFF0965B8), fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: () => _showCheckStatusDialog(context),
                            child: const Text(
                              'Already requested? Check Status & Get Password',
                              style: TextStyle(color: Color(0xFF17365F), fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE REQUEST ACCESS DIALOG (VET REGISTRATION)
  // ---------------------------------------------------------------------------
  void _showRequestAccessDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController(text: 'Livestock & Bovine Medicine');
    final docIdCtrl = TextEditingController(text: 'VCI-MH-2026-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final certCtrl = TextEditingController(text: '/uploads/certificates/reg_council_cert.pdf');
    final clinicCtrl = TextEditingController(text: 'District Veterinary Polyclinic, Pune');

    bool isSubmitting = false;
    String? dialogError;
    Map<String, dynamic>? successData;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: successData != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Request Submitted Successfully!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17365F)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('State Doctor ID: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Text(successData!['vet']?['doctorId'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0965B8))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        'PENDING GOV AUDIT',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your state veterinary council credentials have been submitted to the Government DAHD officer for verification. Once approved, your login email and generated password will be available.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0965B8)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showCheckStatusDialog(context, initialId: successData!['vet']?['doctorId']);
                              },
                              child: const Text('Check Status Now', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F1FC), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.assignment_ind_outlined, color: Color(0xFF0965B8), size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Request Access as Doctor',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17365F)),
                                      ),
                                      Text(
                                        'Official Veterinary Council Credentialing',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            if (dialogError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(dialogError!, style: TextStyle(color: Colors.red.shade900, fontSize: 12))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Text('Doctor Full Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(nameCtrl, 'Dr. Anand Sharma', Icons.person_outline),
                            const SizedBox(height: 12),

                            const Text('Specialization *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(specCtrl, 'e.g. Bovine Medicine, Surgery', Icons.medical_services_outlined),
                            const SizedBox(height: 12),

                            const Text('State Council Doctor ID / Reg No *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(docIdCtrl, 'e.g. VCI-MH-2026-8472', Icons.badge_outlined),
                            const SizedBox(height: 12),

                            const Text('Official Email ID *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(emailCtrl, 'dr.name@vetcare.in', Icons.email_outlined),
                            const SizedBox(height: 12),

                            const Text('Mobile Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(phoneCtrl, '9822011223', Icons.phone_android_outlined),
                            const SizedBox(height: 12),

                            const Text('Veterinary Council Certificate / License *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(certCtrl, 'File URL or PDF Certificate link', Icons.attach_file_rounded),
                            const SizedBox(height: 12),

                            const Text('Clinic / Hospital & District', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            _buildDialogTextField(clinicCtrl, 'Government Veterinary Dispensary, Pune', Icons.local_hospital_outlined),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0965B8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final name = nameCtrl.text.trim();
                                        final spec = specCtrl.text.trim();
                                        final docId = docIdCtrl.text.trim();
                                        final email = emailCtrl.text.trim();
                                        final phone = phoneCtrl.text.trim();

                                        if (name.isEmpty || spec.isEmpty || docId.isEmpty || email.isEmpty || phone.isEmpty) {
                                          setDialogState(() => dialogError = 'Please fill all mandatory fields marked with *');
                                          return;
                                        }

                                        setDialogState(() {
                                          isSubmitting = true;
                                          dialogError = null;
                                        });

                                        try {
                                          final res = await VetApiService().requestAccess(
                                            name: name,
                                            specialization: spec,
                                            doctorId: docId,
                                            email: email,
                                            phone: phone,
                                            certificateUrl: certCtrl.text.trim(),
                                            hospitalClinic: clinicCtrl.text.trim(),
                                          );
                                          setDialogState(() {
                                            isSubmitting = false;
                                            successData = res;
                                          });
                                        } catch (e) {
                                          setDialogState(() {
                                            isSubmitting = false;
                                            dialogError = e.toString().replaceAll('Exception:', '').trim();
                                          });
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Submit Application to Government', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE CHECK STATUS & GET PASSWORD DIALOG
  // ---------------------------------------------------------------------------
  void _showCheckStatusDialog(BuildContext context, {String? initialId}) {
    final searchCtrl = TextEditingController(text: initialId ?? _emailController.text);
    bool isLoading = false;
    String? searchError;
    Map<String, dynamic>? statusResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFF0965B8)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Application Status & Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17365F)),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Enter your State Doctor ID or Registered Email to check verification status.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogTextField(searchCtrl, 'Doctor ID or Email', Icons.badge_outlined),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0965B8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final query = searchCtrl.text.trim();
                                  if (query.isEmpty) return;
                                  setDialogState(() {
                                    isLoading = true;
                                    searchError = null;
                                  });
                                  try {
                                    final res = await VetApiService().checkStatus(query);
                                    setDialogState(() {
                                      isLoading = false;
                                      statusResult = res;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      isLoading = false;
                                      searchError = e.toString().replaceAll('Exception:', '').trim();
                                    });
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Check', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (searchError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(searchError!, style: TextStyle(color: Colors.red.shade800, fontSize: 12.5)),
                      ),
                    ],
                    if (statusResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: statusResult!['isApproved'] == true ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusResult!['isApproved'] == true ? Colors.green.shade300 : Colors.amber.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  statusResult!['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF17365F)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusResult!['isApproved'] == true ? Colors.green : Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusResult!['verificationStatus'] ?? 'PENDING',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Doctor ID: ${statusResult!['doctorId']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text('Email: ${statusResult!['email']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            if (statusResult!['isApproved'] == true) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Text('Assigned Password: ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text(
                                    statusResult!['credentials']?['temporaryPassword'] ?? 'Vet@2026',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0965B8)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 38,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0965B8)),
                                  onPressed: () {
                                    _emailController.text = statusResult!['email'] ?? '';
                                    _passwordController.text = statusResult!['credentials']?['temporaryPassword'] ?? '';
                                    Navigator.pop(ctx);
                                    _showMessage('Credentials loaded into login form!');
                                  },
                                  child: const Text('Fill in Login Form & Proceed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              Text(
                                statusResult!['message'] ?? 'Pending official verification by Government Admin.',
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, IconData icon) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF17365F), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF718096), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF8E9BAE)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0965B8), width: 1.5)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED FORM FIELD (DRY / Lazy code)
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13.8, color: Color(0xFF17365F), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF718096), size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF8E9BAE), fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4ED), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4ED), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0965B8), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HISTORIC MARATHA FORT SILHOUETTE PAINTER (Matches Target Mockup Accent)
// -----------------------------------------------------------------------------
class _FortSilhouettePainter extends CustomPainter {
  final Color color;
  _FortSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h * 0.95);
    path.lineTo(w * 0.15, h * 0.85);
    path.lineTo(w * 0.18, h * 0.58);
    path.lineTo(w * 0.28, h * 0.58);
    path.lineTo(w * 0.30, h * 0.75);
    path.lineTo(w * 0.45, h * 0.70);
    path.lineTo(w * 0.48, h * 0.32);
    path.lineTo(w * 0.62, h * 0.32);
    // Flag pole & saffron pennant
    path.lineTo(w * 0.62, h * 0.12);
    path.lineTo(w * 0.74, h * 0.20);
    path.lineTo(w * 0.62, h * 0.26);
    // Right bastion
    path.lineTo(w * 0.66, h * 0.48);
    path.lineTo(w * 0.80, h * 0.48);
    path.lineTo(w * 0.86, h * 0.75);
    path.lineTo(w, h * 0.80);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// GOLDEN MAHARASHTRA STATE MAP PAINTER (Matches Target Mockup Silhouette)
// -----------------------------------------------------------------------------
class _MaharashtraMapPainter extends CustomPainter {
  final Color color;
  _MaharashtraMapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Stylized silhouette of Maharashtra boundary
    final path = Path();
    path.moveTo(w * 0.18, h * 0.32);
    path.lineTo(w * 0.38, h * 0.12); // North-west Khandesh
    path.lineTo(w * 0.58, h * 0.16); // Satpura range
    path.lineTo(w * 0.82, h * 0.10); // Nagpur / Amravati
    path.lineTo(w * 0.98, h * 0.28); // Gadchiroli east tip
    path.lineTo(w * 0.92, h * 0.55); // Chandrapur south
    path.lineTo(w * 0.74, h * 0.65); // Nanded / Marathwada
    path.lineTo(w * 0.58, h * 0.84); // Solapur / Kolhapur
    path.lineTo(w * 0.42, h * 0.98); // Sindhudurg south
    path.lineTo(w * 0.30, h * 0.90);
    path.lineTo(w * 0.24, h * 0.70); // Konkan coastline
    path.lineTo(w * 0.20, h * 0.48); // Mumbai / Thane
    path.lineTo(w * 0.14, h * 0.38);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// BOTTOM CROP FOLIAGE PAINTER (Matches Target Mockup Bottom Decoration)
// -----------------------------------------------------------------------------
class _BottomCropFoliagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden background earth wave
    final goldPaint = Paint()..color = const Color(0xFFFBBF24);
    final goldPath = Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(w * 0.28, h * 0.25, w * 0.60, h * 0.42)
      ..quadraticBezierTo(w * 0.82, h * 0.52, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(goldPath, goldPaint);

    // Lush green foreground crop ground
    final greenPaint = Paint()..color = const Color(0xFF65A30D);
    final greenPath = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.32, h * 0.45, w * 0.68, h * 0.58)
      ..quadraticBezierTo(w * 0.88, h * 0.65, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Deep crop leaf accent paint
    final leafPaint = Paint()..color = const Color(0xFF4D7C0F)..style = PaintingStyle.fill;
    final goldLeafPaint = Paint()..color = const Color(0xFFEAB308)..style = PaintingStyle.fill;

    // Left crop sprout
    final l1 = Path()
      ..moveTo(10, h * 0.65)
      ..quadraticBezierTo(4, h * 0.20, 16, h * 0.05)
      ..quadraticBezierTo(24, h * 0.30, 16, h * 0.65)
      ..close();
    canvas.drawPath(l1, leafPaint);

    final l2 = Path()
      ..moveTo(18, h * 0.70)
      ..quadraticBezierTo(30, h * 0.28, 40, h * 0.18)
      ..quadraticBezierTo(42, h * 0.45, 24, h * 0.75)
      ..close();
    canvas.drawPath(l2, goldLeafPaint);

    // Right crop sprout
    final r1 = Path()
      ..moveTo(w - 12, h * 0.60)
      ..quadraticBezierTo(w - 6, h * 0.16, w - 22, h * 0.04)
      ..quadraticBezierTo(w - 28, h * 0.28, w - 18, h * 0.65)
      ..close();
    canvas.drawPath(r1, leafPaint);

    final r2 = Path()
      ..moveTo(w - 24, h * 0.70)
      ..quadraticBezierTo(w - 38, h * 0.28, w - 48, h * 0.16)
      ..quadraticBezierTo(w - 50, h * 0.45, w - 30, h * 0.75)
      ..close();
    canvas.drawPath(r2, goldLeafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
