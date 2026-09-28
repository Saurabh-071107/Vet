import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/vet_api_service.dart';
import 'consultation_screen.dart';

class ConsultationsView extends StatefulWidget {
  const ConsultationsView({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<ConsultationsView> createState() => _ConsultationsViewState();
}

class _ConsultationsViewState extends State<ConsultationsView> {
  final VetApiService _apiService = VetApiService();
  String _selectedFilter = 'All'; // 'All', 'Kiosk', 'Patient App'
  String _searchQuery = '';
  List<Map<String, dynamic>> _queueList = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadQueueData();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final results = await Future.wait([
        _apiService.getVetQueue(),
        _apiService.getAppointments(),
      ]);
      final q = results[0];
      final apts = results[1];
      final existingIds = q.map((e) => (e['_id'] ?? e['id'])?.toString()).toSet();
      final merged = <Map<String, dynamic>>[
        ...q,
        ...apts.where((a) => !existingIds.contains((a['_id'] ?? a['id'])?.toString())),
      ];
      if (mounted) {
        setState(() => _queueList = merged);
      }
    } catch (_) {}
  }

  Future<void> _loadQueueData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getVetQueue(),
        _apiService.getAppointments(),
      ]);
      final q = results[0];
      final apts = results[1];
      final existingIds = q.map((e) => (e['_id'] ?? e['id'])?.toString()).toSet();
      final merged = <Map<String, dynamic>>[
        ...q,
        ...apts.where((a) => !existingIds.contains((a['_id'] ?? a['id'])?.toString())),
      ];
      if (mounted) {
        setState(() {
          _queueList = merged;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCall(Map<String, dynamic> patient) async {
    final appointmentId = patient['_id']?.toString() ?? patient['id']?.toString() ?? 'apt_queue_1';
    try {
      await _apiService.startCall(appointmentId);
    } catch (_) {}

    if (mounted) {
      final caseModel = VetCaseModel.fromAppointment(patient);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            caseItem: caseModel,
            appointmentId: appointmentId,
          ),
        ),
      ).then((_) => _silentRefresh());
    }
  }

  // Dynamic patient mapping directly from backend queue & appointments
  List<Map<String, dynamic>> _getMergedPatients() {
    if (_queueList.isEmpty) return [];

    return _queueList.map((q) {
      final name = (q['farmerName'] ?? q['patientName'] ?? q['name'] ?? 'Patient').toString();
      final src = (q['source'] ?? (q['channel'] == 'kiosk' ? 'Kiosk - Center' : 'Patient App')).toString();
      final isKiosk = src.toLowerCase().contains('kiosk');
      final temp = q['temperature'] != null ? '${q['temperature']}°F' : (q['temp'] != null ? '${q['temp']}°F' : 'Normal');
      final bp = q['bp']?.toString() ?? 'Normal';
      final status = (q['status'] ?? '').toString().toLowerCase();
      final priority = (q['priority'] ?? '').toString();
      final isUrgent = status == 'urgent' || priority == 'Emergency' || priority == 'High Priority';

      return {
        ...q,
        'name': name,
        'source': src,
        'sourceType': isKiosk ? 'kiosk' : 'app',
        'badge': q['badge'] ?? (isUrgent ? 'Emergency' : (q['isFollowUp'] == true ? 'Follow-up' : 'New Patient')),
        'complaint': q['reason'] ?? q['complaint'] ?? q['symptoms']?.toString() ?? 'General Consultation',
        'timer': q['timer'] ?? (q['scheduledTime']?.toString() ?? 'In Queue'),
        'timerUrgent': q['timerUrgent'] ?? isUrgent,
        'temperature': temp,
        'bp': bp,
        'avatar': name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPatients = _getMergedPatients();
    final filtered = allPatients.where((p) {
      // Filter tab
      if (_selectedFilter == 'Kiosk' && p['sourceType'] != 'kiosk') return false;
      if (_selectedFilter == 'Patient App' && p['sourceType'] != 'app') return false;
      // Search text
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final complaint = (p['complaint'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !complaint.contains(query)) return false;
      }
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= VetAppConstants.tabletBreakpoint;
        final horizontalPadding = isWide ? 32.0 : 16.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadQueueData,
              color: VetAppConstants.primaryTeal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: VetAppConstants.maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Emblem Header
                        _buildTopEmblemHeader(),
                        const SizedBox(height: 12),

                        // Page Title Bar: Back arrow, "Waiting Queue", "5 Waiting" badge
                        _buildPageTitleBar(allPatients.length),
                        const SizedBox(height: 16),

                        // Wait Time Trend (Last 2h) Card with Histogram
                        _buildWaitTimeTrendCard(),
                        const SizedBox(height: 16),

                        // Search Bar & Filter Pills (All, Kiosk, Patient App)
                        _buildSearchAndFilters(),
                        const SizedBox(height: 16),

                        // Patient Queue Cards List
                        if (_isLoading && _queueList.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: VetAppConstants.primaryTeal),
                            ),
                          )
                        else if (filtered.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                                SizedBox(height: 12),
                                Text(
                                  'Queue is Clear',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No patients currently waiting in this filter.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final patient in filtered)
                            _buildPatientQueueCard(patient),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Top Government Emblem Header
  Widget _buildTopEmblemHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/national_emblem.png',
          width: 34,
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: VetAppConstants.primaryTeal, size: 28),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Government of',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.1,
              ),
            ),
            Text(
              'Maharashtra',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            Text(
              'महाराष्ट्र शासन',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Page Title Bar: Back Arrow, "Waiting Queue", Badge "5 Waiting"
  Widget _buildPageTitleBar(int count) {
    return Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        if (widget.onBack != null) const SizedBox(width: 8),
        const Text(
          'Waiting Queue',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count Waiting',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Wait Time Trend (Last 2h) Card with Responsive Bar Histogram
  Widget _buildWaitTimeTrendCard() {
    // 8-bar heights representing wait times over the last 2 hours
    const barValues = [0.45, 0.70, 0.90, 0.65, 0.40, 0.32, 0.22, 0.15];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Wait Time Trend (Last 2h)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                '-12% vs avg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Histogram Bar Chart
          SizedBox(
            height: 38,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < barValues.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Container(
                        height: 38 * barValues[i],
                        decoration: BoxDecoration(
                          color: i == barValues.length - 1
                              ? VetAppConstants.primaryTeal
                              : (i >= barValues.length - 3
                                  ? const Color(0xFF80CBC4)
                                  : const Color(0xFFB2DFDB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Search and Filter Bar
  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill Search Input
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Search patients...',
                    hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Filter Pills Row (All, Kiosk, Patient App)
        Row(
          children: [
            _filterPill('All'),
            const SizedBox(width: 8),
            _filterPill('Kiosk'),
            const SizedBox(width: 8),
            _filterPill('Patient App'),
          ],
        ),
      ],
    );
  }

  Widget _filterPill(String title) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VetAppConstants.primaryTeal : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 5. Patient Queue Card (Matching Sarah Jenkins / Robert Chen in Mockup)
  Widget _buildPatientQueueCard(Map<String, dynamic> patient) {
    final isUrgent = patient['timerUrgent'] == true;
    final timerColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final badgeText = patient['badge']?.toString() ?? 'New Patient';
    final isNewPatient = badgeText == 'New Patient';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Name & Channel, Countdown Circle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient['avatar']?.toString() ?? 'PT',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name']?.toString() ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          patient['sourceType'] == 'kiosk' ? Icons.desktop_windows_outlined : Icons.smartphone_outlined,
                          size: 13,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patient['source']?.toString() ?? 'Patient App',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Timer countdown in circular ring
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: timerColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    patient['timer']?.toString() ?? '02:00',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: timerColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tags row: Pill (New Patient / Follow-up) + Complaint description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNewPatient ? const Color(0xFFE0F2EF) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNewPatient ? VetAppConstants.primaryTeal : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  patient['complaint']?.toString() ?? 'Consultation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vitals Row: Temp & BP
          Row(
            children: [
              const Icon(Icons.thermostat_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                patient['temperature']?.toString() ?? '98.6°F',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                patient['bp']?.toString() ?? '120/80',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Full-width Deep Teal "Accept Call" Button
          InkWell(
            onTap: () => _startCall(patient),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: VetAppConstants.primaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Accept Call',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
