import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/session_manager.dart';
import '../services/vet_api_service.dart';
import 'consultation_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.onNavigateToTab,
    required this.onReportOutbreak,
  });

  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onReportOutbreak;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final VetApiService _apiService = VetApiService();
  final SessionManager _session = SessionManager();
  Timer? _pollTimer;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _queueItems = [];
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _loadDashboardData();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadDashboardData(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDashboardData({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getDashboardStats(),
        _apiService.getVetQueue(),
        _apiService.getAppointments(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _queueItems = results[1] as List<Map<String, dynamic>>;
          _appointments = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  void _startConsultation(Map<String, dynamic> item) {
    final caseModel = VetCaseModel.fromAppointment(item);
    final appointmentId = item['_id']?.toString() ?? item['id']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(
          caseItem: caseModel,
          appointmentId: appointmentId,
        ),
      ),
    ).then((_) => _loadDashboardData(isBackground: true));
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = _session.doctorName.isNotEmpty ? _session.doctorName : _session.vetName;
    final waitingCount = _queueItems.length;
    final todayCount = (_stats['totalAppointments'] as num?)?.toInt() ??
        (_stats['totalPatientsAttended'] as num?)?.toInt() ??
        (_stats['assignedCases'] as num?)?.toInt() ??
        _appointments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= VetAppConstants.tabletBreakpoint;
        final horizontalPadding = isWide ? 32.0 : 16.0;

        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: VetAppConstants.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 110),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VetAppConstants.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(
                          minHeight: 2.5,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(VetAppConstants.primaryTeal),
                        ),
                      ),

                    // Top App Header: Maharashtra Seal + Notification Bell & Profile Avatar
                    _buildTopHeader(context),
                    const SizedBox(height: 16),

                    // Morning Hero Banner with Pastoral Artwork & Live Doctor Name
                    _buildHeroBanner(context, doctorName),
                    const SizedBox(height: 20),

                    // Two Key Stat Cards (Today's Patients & Patients Waiting)
                    _buildStatCards(todayCount, waitingCount),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    _buildQuickActionsSection(waitingCount),
                    const SizedBox(height: 24),

                    // Currently Waiting Section (strictly connected to live backend queue)
                    _buildCurrentlyWaitingSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Top Bar: Maharashtra Seal + Notification Bell & Profile Avatar
  Widget _buildTopHeader(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/national_emblem.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.account_balance, color: VetAppConstants.primaryTeal, size: 32),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Government of',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.1,
              ),
            ),
            Text(
              'Maharashtra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            Text(
              'महाराष्ट्र शासन',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                height: 1.1,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification Bell with indicator
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 26),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All animal husbandry district alerts are synchronized.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        // Doctor Profile Avatar
        GestureDetector(
          onTap: () => widget.onNavigateToTab(3),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: VetAppConstants.clinicalTealLight,
              shape: BoxShape.circle,
              border: Border.all(color: VetAppConstants.primaryTeal.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person, color: VetAppConstants.primaryTeal, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Hero Banner: Pastoral Morning Landscape with Greeting
  Widget _buildHeroBanner(BuildContext context, String doctorName) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1E7DD), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Banner Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/vet_dashboard_banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFE8F4F0)),
            ),
          ),
          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.94),
                    Colors.white.withValues(alpha: 0.70),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          // Greeting Text
          Positioned(
            left: 20,
            top: 28,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Good Morning,',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Stat Cards: Today's Patients & Patients Waiting
  Widget _buildStatCards(int todayCount, int waitingCount) {
    return Row(
      children: [
        // Today's Patients
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icon_todays_patients.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.people, size: 20, color: VetAppConstants.primaryTeal),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        "Today's Patients",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$todayCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayCount > 0 ? 'Active in records' : 'No patients yet',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Patients Waiting
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icon_patients_waiting.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.timer, size: 20, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Patients Waiting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$waitingCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  waitingCount > 0 ? 'High urgency' : 'Queue cleared',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: waitingCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Quick Actions Section
  Widget _buildQuickActionsSection(int waitingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        // Primary Teal Button: View Queue
        InkWell(
          onTap: () => widget.onNavigateToTab(1),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: VetAppConstants.primaryTeal,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x200B6057), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Text(
                  'View Queue',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$waitingCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // White Card: Patient History
        InkWell(
          onTap: () => widget.onNavigateToTab(2),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Patient History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // White Card: Today's Schedule
        InkWell(
          onTap: () => widget.onNavigateToTab(1),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Text(
                  _appointments.isNotEmpty
                      ? "Today's Schedule (${_appointments.length} appointments)"
                      : "Today's Schedule",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 5. Currently Waiting Section (Dynamic from backend)
  Widget _buildCurrentlyWaitingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Currently Waiting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => widget.onNavigateToTab(1),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: VetAppConstants.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_queueItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF10B981)),
                SizedBox(height: 8),
                Text(
                  'No Patients Waiting',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'The patient triage queue is currently clear.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          for (final item in _queueItems)
            _buildWaitingPatientCard(item),
      ],
    );
  }

  Widget _buildWaitingPatientCard(Map<String, dynamic> item) {
    final name = (item['farmerName'] ?? item['patientName'] ?? item['name'] ?? 'Patient').toString();
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'PT';
    final issue = (item['reason'] ?? item['issue'] ?? item['symptoms'] ?? 'General Consultation').toString();
    final channel = (item['channel'] ?? item['source'] ?? 'Video').toString();
    final timeStr = (item['scheduledTime'] ?? item['timer'] ?? 'Waiting').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2EF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        channel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: VetAppConstants.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _startConsultation(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
