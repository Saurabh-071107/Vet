import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/vet_api_service.dart';
import '../widgets/case_card.dart';
import 'consultation_screen.dart';

class CasesView extends StatefulWidget {
  const CasesView({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<CasesView> createState() => _CasesViewState();
}

class _CasesViewState extends State<CasesView> {
  final VetApiService _apiService = VetApiService();

  List<VetCaseModel> _allCases = [];
  List<VetCaseModel> _filteredCases = [];
  List<Map<String, dynamic>> _appointments = [];
  
  bool _isLoading = true;
  String _selectedTab = 'Patients'; // 'Patients', 'Urgent', 'Appointments'
  VetCaseModel? _selectedCaseForWideScreen;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final casesFuture = _apiService.getCases();
      final appointmentsFuture = _apiService.getAppointments();
      final queueFuture = _apiService.getVetQueue();

      final results = await Future.wait([casesFuture, appointmentsFuture, queueFuture]);
      final cases = results[0] as List<VetCaseModel>;
      final apts = results[1] as List<Map<String, dynamic>>;
      final queueApts = results[2] as List<Map<String, dynamic>>;

      // Merge queue items with high priority at top of patients list
      final queueCases = queueApts.map((apt) => VetCaseModel.fromAppointment(apt)).toList();
      final existingIds = cases.map((c) => c.id).toSet();
      final mergedCases = <VetCaseModel>[
        ...queueCases.where((qc) => !existingIds.contains(qc.id)),
        ...cases,
      ];

      if (mounted) {
        setState(() {
          _allCases = mergedCases;
          _appointments = apts;
          _isLoading = false;
          _applyFilters();
          if (_filteredCases.isNotEmpty && _selectedCaseForWideScreen == null) {
            _selectedCaseForWideScreen = _filteredCases.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading cases & appointments data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var caseList = List<VetCaseModel>.from(_allCases);
    if (_selectedTab == 'Urgent') {
      caseList = caseList
          .where((c) =>
              c.priorityText == 'High Priority' ||
              c.aiRiskScore >= 75 ||
              c.suspectedOutbreak ||
              c.aiSeverity.toLowerCase() == 'critical')
          .toList();
    }

    setState(() {
      _filteredCases = caseList;
      if (_selectedCaseForWideScreen != null &&
          !_filteredCases.any((c) => c.id == _selectedCaseForWideScreen!.id)) {
        _selectedCaseForWideScreen = _filteredCases.isNotEmpty ? _filteredCases.first : null;
      }
    });
  }

  int get _urgentCount => _allCases
      .where((c) =>
          c.priorityText == 'High Priority' ||
          c.aiRiskScore >= 75 ||
          c.suspectedOutbreak ||
          c.aiSeverity.toLowerCase() == 'critical')
      .length;

  void _openConsultationScreen(VetCaseModel c) async {
    // Notify backend that doctor initiated call (sets ringing state for waiting patient)
    try {
      await _apiService.startCall(c.id);
    } catch (_) {}

    if (!mounted) return;

    final updated = await Navigator.push<VetCaseModel>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ConsultationScreen(
          caseItem: c,
          appointmentId: c.id,
          onCaseUpdated: (updatedCase) {
            if (!mounted) return; // guard: widget may be disposed
            final idx = _allCases.indexWhere((item) => item.id == updatedCase.id);
            if (idx != -1) {
              setState(() {
                _allCases[idx] = updatedCase;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final idx = _allCases.indexWhere((item) => item.id == updated.id);
        if (idx != -1) _allCases[idx] = updated;
        _applyFilters();
        _selectedCaseForWideScreen = updated;
      });
    }
  }

  void _startAppointmentConsultation(Map<String, dynamic> apt) {
    // 5-minute pre-call validation rule
    if (!VetApiService.isAppointmentCallAllowed(apt)) {
      final lockReason = VetApiService.getAppointmentLockReason(apt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Call locked for ${apt["farmerName"] ?? "farmer"}. Doctors can only start calls up to 5 minutes before scheduled slot (${apt["scheduledTime"]}). $lockReason',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Map appointment to case model
    final aptCase = VetCaseModel.fromAppointment(apt);
    _openConsultationScreen(aptCase);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= VetAppConstants.tabletBreakpoint;
        final horizontalPadding = isWide ? 28.0 : 16.0;

        return Scaffold(
          backgroundColor: VetAppConstants.background,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VetAppConstants.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. TOP HEADER (Back button, Title, Refresh)
                      _buildHeader(context),
                      const SizedBox(height: 16),

                      // 2. THREE DEDICATED TABS: Patients, Urgent, Appointments
                      _buildThreeTabs(),
                      const SizedBox(height: 16),

                      // 3. MAIN BODY (Patients list, Urgent list, or Appointments list)
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _selectedTab == 'Appointments'
                                ? _buildAppointmentsList()
                                : (_filteredCases.isEmpty
                                    ? _buildEmptyState()
                                    : (isWide ? _buildWideMasterDetail() : _buildPatientQueueList())),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/national_emblem.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: VetAppConstants.primaryTeal, size: 26),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Government of Maharashtra · महाराष्ट्र शासन',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Back Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Title
            const Text(
              'Patients & History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),

            // Refresh Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadAllData,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: VetAppConstants.primaryTeal,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. THREE TABS: Patients, Urgent, Appointments
  // ---------------------------------------------------------------------------
  Widget _buildThreeTabs() {
    final patientsCount = _allCases.isNotEmpty ? _allCases.length : 12;
    final urgentCount = _allCases.isNotEmpty ? _urgentCount : 3;
    final aptsCount = _appointments.isNotEmpty ? _appointments.length : 3;

    return Row(
      children: [
        // Tab 1: Patients
        Expanded(
          child: _buildTabPill(
            label: 'Patients ($patientsCount)',
            icon: Icons.people_alt_rounded,
            isSelected: _selectedTab == 'Patients',
            onTap: () {
              setState(() {
                _selectedTab = 'Patients';
                _applyFilters();
              });
            },
            selectedBg: VetAppConstants.primaryTeal,
            unselectedBg: Colors.white,
            selectedText: Colors.white,
            unselectedText: const Color(0xFF1E293B),
            unselectedBorder: const Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(width: 8),

        // Tab 2: Urgent
        Expanded(
          child: _buildTabPill(
            label: 'Urgent ($urgentCount)',
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFFDC2626),
            isSelected: _selectedTab == 'Urgent',
            onTap: () {
              setState(() {
                _selectedTab = 'Urgent';
                _applyFilters();
              });
            },
            selectedBg: const Color(0xFFDC2626),
            unselectedBg: const Color(0xFFFEF2F2),
            selectedText: Colors.white,
            unselectedText: const Color(0xFFDC2626),
            unselectedBorder: const Color(0xFFFECACA),
          ),
        ),
        const SizedBox(width: 8),

        // Tab 3: Appointments
        Expanded(
          child: _buildTabPill(
            label: 'Appointments ($aptsCount)',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF059669),
            isSelected: _selectedTab == 'Appointments',
            onTap: () {
              setState(() {
                _selectedTab = 'Appointments';
                _applyFilters();
              });
            },
            selectedBg: const Color(0xFF059669),
            unselectedBg: const Color(0xFFF0FDF4),
            selectedText: Colors.white,
            unselectedText: const Color(0xFF059669),
            unselectedBorder: const Color(0xFFBBF7D0),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
    required Color selectedBg,
    required Color unselectedBg,
    required Color selectedText,
    required Color unselectedText,
    required Color unselectedBorder,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBg : unselectedBorder,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedBg.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x040E2C4D),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : (iconColor ?? unselectedText),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? selectedText : unselectedText,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PATIENT QUEUE LIST (TAB 1 & TAB 2)
  // ---------------------------------------------------------------------------
  Widget _buildPatientQueueList() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: VetAppConstants.primaryBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredCases.length,
        itemBuilder: (context, index) {
          final c = _filteredCases[index];
          return CaseCard(
            caseItem: c,
            onExamine: () => _openConsultationScreen(c),
            onReceiveCall: () => _openConsultationScreen(c),
            onReject: _loadAllData,
          );


        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. APPOINTMENTS LIST (TAB 3)
  // ---------------------------------------------------------------------------
  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Scheduled Appointments Found',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check back later or refresh live data.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF059669),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final apt = _appointments[index];
          return _buildAppointmentCard(apt);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final type = (apt['type'] ?? 'video_call').toString();
    final isVideo = type.contains('video');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06102A4A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Scheduled Time + Type Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 5),
                  Text(
                    apt['scheduledTime'] ?? 'Today, 10:30 AM',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isVideo ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                      size: 14,
                      color: isVideo ? VetAppConstants.primaryTeal : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isVideo ? 'Video Call' : 'Audio Call',
                      style: TextStyle(
                        color: isVideo ? VetAppConstants.primaryTeal : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          // Animal & Farmer Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VetAppConstants.clinicalTealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets_rounded, color: VetAppConstants.primaryTeal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt['animalName'] ?? 'Gauri (HF Cow)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Farmer: ${apt['farmerName']} • ${apt['village']}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tag: ${apt['animalTag'] ?? "MH-PUN-0842"} • ${apt['farmerPhone'] ?? ""}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (apt['notes'] != null && (apt['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      apt['notes'],
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action: Receive Video Call with 5-Minute Pre-Call Rule
          Builder(
            builder: (context) {
              final isCallAllowed = VetApiService.isAppointmentCallAllowed(apt);
              final lockReason = VetApiService.getAppointmentLockReason(apt);

              if (!isCallAllowed) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lockReason.isNotEmpty ? lockReason : 'Call opens 5 min before scheduled slot',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _startAppointmentConsultation(apt),
                        icon: const Icon(Icons.lock_outline_rounded, size: 16),
                        label: const Text(
                          'Call Locked (Available 5m Before)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _startAppointmentConsultation(apt),
                  icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Receive Call / Start Consultation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. WIDE SCREEN / TABLET MASTER-DETAIL
  // ---------------------------------------------------------------------------
  Widget _buildWideMasterDetail() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left master list
        Expanded(
          flex: 5,
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView.builder(
              itemCount: _filteredCases.length,
              itemBuilder: (context, index) {
                final c = _filteredCases[index];
                final isSelected = _selectedCaseForWideScreen?.id == c.id;
                return CaseCard(
                  caseItem: c,
                  isSelected: isSelected,
                  onExamine: () {
                    setState(() => _selectedCaseForWideScreen = c);
                  },
                  onReceiveCall: () => _openConsultationScreen(c),
                  onReject: _loadAllData,
                );


              },
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Right details pane
        Expanded(
          flex: 6,
          child: _selectedCaseForWideScreen != null
              ? _buildWideDetailPane(_selectedCaseForWideScreen!)
              : const Center(child: Text('Select a case to inspect clinical records')),
        ),
      ],
    );
  }

  Widget _buildWideDetailPane(VetCaseModel c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060E2C4D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                c.formattedCaseId,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VetAppConstants.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openConsultationScreen(c),
                icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 18),
                label: const Text('Start Video Consultation', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Animal: ${c.speciesAndAge}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Location: ${c.villageText}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Clinical Symptoms:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: c.symptoms
                .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF1F5F9),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Text('AI Prediction: ${c.aiPredictedDisease}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(c.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Cases Found in this Tab',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try selecting another tab or refreshing live data.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
