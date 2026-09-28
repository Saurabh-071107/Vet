import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/vet_api_service.dart';

class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.caseItem,
    required this.onExamine,
    this.onReceiveCall,
    this.onReject,
    this.isSelected = false,
  });

  final VetCaseModel caseItem;
  final VoidCallback onExamine;
  final VoidCallback? onReceiveCall;
  final VoidCallback? onReject;
  final bool isSelected;


  @override
  Widget build(BuildContext context) {
    final isUrgent = caseItem.priorityText.toLowerCase().contains('high') ||
        caseItem.aiRiskScore >= 75 ||
        caseItem.suspectedOutbreak ||
        caseItem.aiSeverity.toLowerCase() == 'critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent ? const Color(0x0CEF4444) : const Color(0x06102A4A),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onExamine,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Photo + Bio Info + Priority
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Animal Photo Thumbnail with Initials Fallback
                    _buildThumbnail(),
                    const SizedBox(width: 12),

                    // 2. Main Case Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Line: Case ID + Priority Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  caseItem.formattedCaseId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildPriorityBadge(),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Animal Name & Species • Age
                          Text(
                            '${caseItem.animalName != null && caseItem.animalName!.isNotEmpty ? "${caseItem.animalName} • " : ""}${caseItem.speciesAndAge}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Farmer Name & Location
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${caseItem.farmerName ?? "Farmer"} • ${caseItem.villageText}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Reported Time
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                'Reported ${caseItem.reportedAgoText}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Symptoms & AI Diagnosis Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_outlined, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          caseItem.symptoms.isNotEmpty
                              ? 'Symptoms: ${caseItem.symptoms.join(", ")}'
                              : (caseItem.aiPredictedDisease.trim().isNotEmpty
                                  ? 'Suspected: ${caseItem.aiPredictedDisease}'
                                  : (caseItem.description.trim().isNotEmpty
                                      ? caseItem.description
                                      : 'General Clinical Examination')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (caseItem.aiRiskScore > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: caseItem.aiRiskScore >= 75 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI: ${caseItem.aiRiskScore}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: caseItem.aiRiskScore >= 75 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Action Buttons: Reject & Start Video Call
                Row(
                  children: [
                    // Status tag
                    _buildStatusPill(),
                    const Spacer(),

                    // Reject Button
                    Material(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _showRejectDialog(context),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Start Video Call Button
                    Material(
                      color: VetAppConstants.primaryTeal,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: onReceiveCall ?? onExamine,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.video_call_rounded, color: Colors.white, size: 19),
                              SizedBox(width: 6),
                              Text(
                                'Start Video Call (Ring)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    String selectedReason = 'Specialization Mismatch / Outside Bovine Practice';
    final reasons = [
      'Specialization Mismatch / Outside Bovine Practice',
      'Exceeded Current Emergency Caseload',
      'Off-Duty / Shift Complete',
      'Requires On-Site Physical Inspection Only',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.assignment_return_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reject & Re-route Case',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting ${caseItem.formattedCaseId} will return it to the state clinical pool for instant re-assignment to an alternative active veterinarian.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Regulatory Reason:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              ...reasons.map((r) {
                final isCur = selectedReason == r;
                return InkWell(
                  onTap: () => setDlgState(() => selectedReason = r),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCur ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCur ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                        width: isCur ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCur ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 16,
                          color: isCur ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                              color: isCur ? const Color(0xFF991B1B) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await VetApiService().rejectCase(caseItem.id, selectedReason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${caseItem.formattedCaseId} returned to state assignment pool.'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                  onReject?.call();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  // THUMBNAIL WITH INITIALS FALLBACK
  // ---------------------------------------------------------------------------
  Widget _buildThumbnail() {
    final photo = caseItem.primaryPhoto;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: photo != null && photo.isNotEmpty
            ? (photo.startsWith('http')
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitials(),
                  )
                : Image.asset(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitials(),
                  ))
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = caseItem.initials;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0B6057)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRIORITY BADGE
  // ---------------------------------------------------------------------------
  Widget _buildPriorityBadge() {
    final p = caseItem.priorityText.toLowerCase();

    Color bgColor;
    Color textColor;
    String label = caseItem.priorityText;

    if (p.contains('high') || p.contains('critical') || p.contains('urgent')) {
      bgColor = const Color(0xFFEF4444);
      textColor = Colors.white;
      label = 'High Priority';
    } else if (p.contains('med')) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      label = 'Medium';
    } else {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final status = caseItem.status.toLowerCase();
    final isQueue = status == 'in_queue' || (caseItem.displayId != null && caseItem.displayId!.toUpperCase().startsWith('Q-'));
    String label = isQueue ? 'Waiting in Live Queue' : 'Waiting in Queue';
    Color color = isQueue ? const Color(0xFFD97706) : const Color(0xFF64748B);
    Color bg = isQueue ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9);

    if (status == 'prescribed') {
      label = 'Prescribed';
      color = const Color(0xFF16A34A);
      bg = const Color(0xFFDCFCE7);
    } else if (status == 'under_examination' || status == 'ringing') {
      label = status == 'ringing' ? 'Ringing Patient...' : 'In Consultation';
      color = const Color(0xFF2563EB);
      bg = const Color(0xFFDBEAFE);
    } else if (status == 'resolved') {
      label = 'Completed';
      color = const Color(0xFF16A34A);
      bg = const Color(0xFFDCFCE7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isQueue ? Border.all(color: const Color(0xFFFDE68A)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
