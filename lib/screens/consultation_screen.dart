import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/vet_api_service.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    super.key,
    required this.caseItem,
    this.appointmentId,
    this.onCaseUpdated,
  });

  final VetCaseModel caseItem;
  final String? appointmentId;
  final ValueChanged<VetCaseModel>? onCaseUpdated;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final VetApiService _apiService = VetApiService();
  final TextEditingController _notesController = TextEditingController();

  // Call & Device State
  bool _isMicMuted = false;
  bool _isVideoOff = false;
  final bool _isFrontCamera = true;
  int _callDurationSeconds = 765; // Initialized around 12:45 to match mockup
  Timer? _callTimer;
  Timer? _streamSyncTimer;

  // Real Camera Controller
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _availableCameras = [];

  // Stream & Remote Peer
  String? _peerFrameBase64;
  bool _peerMuted = false;
  bool _peerVideoOff = false;
  bool _isCapturingDoctorFrame = false;

  // Prescriptions & Reports
  final List<Map<String, dynamic>> _prescriptions = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.caseItem.vetNotes ?? '';

    // Initialize sample prescription
    _prescriptions.add({
      'name': 'Ceftiofur Sodium',
      'dosage': '1 g IM once daily',
      'withdrawal': 4,
    });
    _prescriptions.add({
      'name': 'Meloxicam Injection',
      'dosage': '15 ml IM once daily',
      'withdrawal': 5,
    });

    // Start Call Timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDurationSeconds++);
    });

    _initCamera();

    // Stream sync with backend
    _streamSyncTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _syncDoctorStream();
    });

    // Notify backend call started
    final targetId = widget.appointmentId?.isNotEmpty == true ? widget.appointmentId! : widget.caseItem.id;
    _apiService.startCall(targetId).catchError((_) => <String, dynamic>{});
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _streamSyncTimer?.cancel();
    _cameraController?.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        final camera = _availableCameras.firstWhere(
          (c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
          orElse: () => _availableCameras.first,
        );
        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: !_isMicMuted,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (_) {}
  }

  Future<void> _syncDoctorStream() async {
    if (!mounted) return;
    final aptId = widget.appointmentId?.isNotEmpty == true ? widget.appointmentId! : widget.caseItem.id;
    if (aptId.isEmpty) return;

    String? localFrame;
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isCapturingDoctorFrame &&
        !_isVideoOff) {
      _isCapturingDoctorFrame = true;
      try {
        final xfile = await _cameraController!.takePicture();
        final bytes = await xfile.readAsBytes();
        File(xfile.path).delete().ignore();
        localFrame = base64Encode(bytes);
      } catch (_) {}
      _isCapturingDoctorFrame = false;
    }

    await _apiService.pushStreamFrame(
      appointmentId: aptId,
      role: 'doctor',
      frame: localFrame,
      isAudioActive: !_isMicMuted,
      isMuted: _isMicMuted,
      isVideoOff: _isVideoOff,
    );

    final peerData = await _apiService.getPeerStreamFrame(appointmentId: aptId, peerRole: 'farmer');
    if (peerData != null && mounted) {
      setState(() {
        if (peerData['frame'] != null && peerData['frame'].toString().isNotEmpty) {
          _peerFrameBase64 = peerData['frame'].toString();
        }
        _peerMuted = peerData['isMuted'] == true;
        _peerVideoOff = peerData['isVideoOff'] == true;
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    _callTimer?.cancel();
    _streamSyncTimer?.cancel();
    Navigator.pop(context);
  }

  void _saveNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation notes saved successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEPrescribeModal() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'E-Prescription & Medication',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  for (final rx in _prescriptions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.medication, color: VetAppConstants.primaryTeal),
                      title: Text(rx['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${rx['dosage']} • Withdrawal: ${rx['withdrawal']} days'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setModalState(() => _prescriptions.remove(rx));
                          setState(() {});
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VetAppConstants.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final nav = Navigator.of(ctx);
                              setState(() => _isSubmitting = true);
                              try {
                                await _apiService.recordExamination(
                                  caseId: widget.caseItem.id,
                                  vetNotes: _notesController.text,
                                  prescriptions: _prescriptions.map((p) => Prescription(
                                    id: 'rx-${DateTime.now().millisecondsSinceEpoch}',
                                    medicineName: p['name'],
                                    dosage: p['dosage'],
                                    instructions: 'Take as directed',
                                    withdrawalPeriodDays: p['withdrawal'],
                                  )).toList(),
                                  tests: [],
                                  status: 'prescribed',
                                );
                                if (mounted) {
                                  nav.pop();
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('E-Prescription sent to Patient App.')),
                                  );
                                }
                              } catch (_) {}
                              if (mounted) setState(() => _isSubmitting = false);
                            },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _isSubmitting ? 'Syncing...' : 'Send to Patient App',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scheduleFollowUp() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follow-up scheduled for ${pickedDate.toLocal().toString().substring(0, 10)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= VetAppConstants.tabletBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildTopAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: VetAppConstants.maxContentWidth),
                  child: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Top Bar: Maharashtra Seal + Telehealth Pro
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/national_emblem.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: VetAppConstants.primaryTeal, size: 26),
          ),
          const SizedBox(width: 8),
          const Text(
            'Telehealth Pro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Mobile Layout (Vertical Single Column)
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Video Viewport with PIP & Floating Controls
        _buildVideoViewport(),
        const SizedBox(height: 14),

        // Patient Status & Timer Row
        _buildPatientStatusRow(),
        const SizedBox(height: 16),

        // Patient Vitals Card
        _buildPatientVitalsCard(),
        const SizedBox(height: 14),

        // Medical History Card
        _buildMedicalHistoryCard(),
        const SizedBox(height: 14),

        // Consultation Notes Card
        _buildConsultationNotesCard(),
        const SizedBox(height: 14),

        // Recent Reports Card
        _buildRecentReportsCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  // 3. Desktop / Tablet Split Layout
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Video & Vitals
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoViewport(),
              const SizedBox(height: 14),
              _buildPatientStatusRow(),
              const SizedBox(height: 16),
              _buildPatientVitalsCard(),
              const SizedBox(height: 14),
              _buildMedicalHistoryCard(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right Column: Notes & Reports
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConsultationNotesCard(),
              const SizedBox(height: 14),
              _buildRecentReportsCard(),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Video Viewport with Doctor PIP & Floating Call Controls
  Widget _buildVideoViewport() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Remote Peer Video / Photo Stream
          if (_peerFrameBase64 != null && !_peerVideoOff)
            Image.memory(
              base64Decode(_peerFrameBase64!),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => _buildSimulatedPatient(),
            )
          else
            _buildSimulatedPatient(),

          // Audio muted indicator if remote peer is muted
          if (_peerMuted)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_off_rounded, color: Color(0xFFEF4444), size: 14),
                    SizedBox(width: 4),
                    Text('Muted', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

          // Top Right: Doctor Picture-In-Picture (PIP)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 74,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isCameraInitialized &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized &&
                      !_isVideoOff)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ?? 1,
                        height: _cameraController!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF0B6057),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                    ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Centered Floating Controls: Mic, Video, End Call
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic Button
                InkWell(
                  onTap: () => setState(() => _isMicMuted = !_isMicMuted),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isMicMuted ? const Color(0xFFEF4444) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Video Toggle Button
                InkWell(
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      color: _isVideoOff ? const Color(0xFFEF4444) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // End Call Button (Red circle)
                InkWell(
                  onTap: _endCall,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fallback patient camera display with warm portrait
  Widget _buildSimulatedPatient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF475569),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white70, size: 52),
            ),
            const SizedBox(height: 8),
            const Text(
              'Patient Video Stream',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Patient Header & Elapsed Timer
  Widget _buildPatientStatusRow() {
    final patientName = widget.caseItem.farmerName?.isNotEmpty == true
        ? widget.caseItem.farmerName!
        : 'Eleanor Vance';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: const [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                SizedBox(width: 5),
                Text(
                  'Live Consultation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          _formatDuration(_callDurationSeconds),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // 6. Patient Vitals Card (Card 1)
  Widget _buildPatientVitalsCard() {
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
            children: const [
              Icon(Icons.assignment_outlined, size: 18, color: VetAppConstants.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Patient Vitals',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _vitalItem('AGE', '68 Years'),
              ),
              Expanded(
                child: _vitalItem('GENDER', 'Female'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _vitalItem('BLOOD GROUP', 'O Positive'),
              ),
              Expanded(
                child: _vitalItem('WEIGHT / HEIGHT', "145 lbs / 5'4\""),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // 7. Medical History Card (Card 2)
  Widget _buildMedicalHistoryCard() {
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
            children: const [
              Icon(Icons.medical_information_outlined, size: 18, color: VetAppConstants.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Medical History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CONDITIONS',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hypertension',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFBE123C)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Osteoarthritis',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: VetAppConstants.primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ALLERGIES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB45309)),
                SizedBox(width: 4),
                Text(
                  'Penicillin',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Consultation Notes Card (Card 3)
  Widget _buildConsultationNotesCard() {
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
            children: [
              Row(
                children: const [
                  Icon(Icons.edit_note_rounded, size: 20, color: VetAppConstants.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Consultation Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _saveNotes,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF854D0E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.save_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Save Notes',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Textarea
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Type prescription or clinical notes here...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Action Buttons: E-Prescribe & Schedule Follow-up
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: VetAppConstants.primaryTeal, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _showEPrescribeModal,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16, color: VetAppConstants.primaryTeal),
                  label: const Text(
                    'E-Prescribe',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: VetAppConstants.primaryTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: VetAppConstants.primaryTeal, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _scheduleFollowUp,
                  icon: const Icon(Icons.calendar_today_outlined, size: 15, color: VetAppConstants.primaryTeal),
                  label: const Text(
                    'Schedule Follow-up',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: VetAppConstants.primaryTeal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 9. Recent Reports Card (Card 4)
  Widget _buildRecentReportsCard() {
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
            children: [
              Row(
                children: const [
                  Icon(Icons.folder_open_outlined, size: 18, color: VetAppConstants.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing complete archived lab documents.')),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: VetAppConstants.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2 Report cards side by side
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.description_outlined, size: 20, color: Color(0xFF0D9488)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blood Panel',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text('Oct 12, 2023', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.document_scanner_outlined, size: 20, color: Color(0xFF0D9488)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chest X-Ray',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text('Sep 05, 2023', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Upload Document Button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document attachment dialog opened.')),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined, size: 16, color: Color(0xFF475569)),
                  SizedBox(width: 6),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
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
