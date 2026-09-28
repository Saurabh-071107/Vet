import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vet_case_model.dart';
import '../services/vet_api_service.dart';
import 'risk_badge.dart';

class ExaminationDialog extends StatefulWidget {
  const ExaminationDialog({
    super.key,
    required this.caseItem,
    required this.onSaved,
  });

  final VetCaseModel caseItem;
  final ValueChanged<VetCaseModel> onSaved;

  @override
  State<ExaminationDialog> createState() => _ExaminationDialogState();
}

class _ExaminationDialogState extends State<ExaminationDialog> {
  late final TextEditingController _notesController;
  late final List<RecommendedTest> _tests;
  late final List<Prescription> _prescriptions;
  late bool _suspectedOutbreak;
  late String _status;
  bool _isSaving = false;

  // New prescription form inputs
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _withdrawalController = TextEditingController(text: '3');
  bool _showAddPrescription = false;

  // New test input
  final _testNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.caseItem.vetNotes ?? '');
    _tests = List<RecommendedTest>.from(widget.caseItem.recommendedTests);
    _prescriptions = List<Prescription>.from(widget.caseItem.prescriptions);
    _suspectedOutbreak = widget.caseItem.suspectedOutbreak;
    _status = widget.caseItem.status == 'reported' ? 'prescribed' : widget.caseItem.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _medNameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _withdrawalController.dispose();
    _testNameController.dispose();
    super.dispose();
  }

  void _addPrescription() {
    final med = _medNameController.text.trim();
    final dosage = _dosageController.text.trim();
    if (med.isEmpty || dosage.isEmpty) return;

    setState(() {
      _prescriptions.add(
        Prescription(
          id: 'rx-${DateTime.now().millisecondsSinceEpoch}',
          medicineName: med,
          dosage: dosage,
          instructions: _instructionsController.text.trim(),
          withdrawalPeriodDays: int.tryParse(_withdrawalController.text.trim()) ?? 0,
        ),
      );
      _medNameController.clear();
      _dosageController.clear();
      _instructionsController.clear();
      _withdrawalController.text = '3';
      _showAddPrescription = false;
    });
  }

  void _addTest() {
    final testName = _testNameController.text.trim();
    if (testName.isEmpty) return;

    setState(() {
      _tests.add(
        RecommendedTest(
          id: 'test-${DateTime.now().millisecondsSinceEpoch}',
          testName: testName,
          labName: 'District Diagnostic Centre',
          status: 'Sample Pending',
          orderedAt: DateTime.now().toIso8601String().split('T')[0],
        ),
      );
      _testNameController.clear();
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final updatedCase = await VetApiService().recordExamination(
        caseId: widget.caseItem.id,
        vetNotes: _notesController.text.trim(),
        tests: _tests,
        prescriptions: _prescriptions,
        suspectedOutbreak: _suspectedOutbreak,
        status: _status,
      );

      widget.onSaved(updatedCase);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save examination: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= VetAppConstants.tabletBreakpoint;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 16,
        vertical: isWide ? 32 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: VetAppConstants.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Examination & Digital Prescription',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${widget.caseItem.animalId} · Case #${widget.caseItem.id}',
                          style: const TextStyle(
                            color: Color(0xFFB0C8E8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Case overview row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VetAppConstants.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.caseItem.aiPredictedDisease,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: VetAppConstants.ink,
                                ),
                              ),
                              const Spacer(),
                              RiskBadge(
                                riskScore: widget.caseItem.aiRiskScore,
                                severity: widget.caseItem.aiSeverity,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Farmer: ${widget.caseItem.farmerId}',
                            style: const TextStyle(fontSize: 12.5, color: VetAppConstants.textMuted),
                          ),
                          if (widget.caseItem.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reported: "${widget.caseItem.description}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Clinical Observation & Diagnosis
                    const Text(
                      'Veterinarian Clinical Observations & Diagnosis',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VetAppConstants.ink),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter clinical findings, body temperature, lymph nodes, mucous membranes...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VetAppConstants.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VetAppConstants.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Prescriptions
                    Row(
                      children: [
                        const Text(
                          'Prescribed Medications',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VetAppConstants.ink),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _showAddPrescription = !_showAddPrescription),
                          icon: Icon(_showAddPrescription ? Icons.remove : Icons.add, size: 16),
                          label: Text(_showAddPrescription ? 'Cancel' : '+ Add Drug', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),

                    if (_showAddPrescription) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _medNameController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Drug Name (e.g. Ceftiofur)',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _dosageController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Dosage (e.g. 1g IM)',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _instructionsController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Instructions (e.g. OD for 3 days)',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _withdrawalController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Withdrawal (Days)',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _addPrescription,
                                style: FilledButton.styleFrom(
                                  backgroundColor: VetAppConstants.clinicalTeal,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Add to Prescription', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_prescriptions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No medications added yet. Tap "+ Add Drug" to prescribe.',
                          style: TextStyle(fontSize: 12, color: VetAppConstants.textMuted, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: _prescriptions.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8F6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD1E7DD)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.medication, color: VetAppConstants.clinicalTeal, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.medicineName} (${p.dosage})',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      if (p.instructions.isNotEmpty)
                                        Text(
                                          p.instructions,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                        ),
                                      if (p.withdrawalPeriodDays != null && p.withdrawalPeriodDays! > 0)
                                        Text(
                                          'Milk/Meat Withdrawal: ${p.withdrawalPeriodDays} days',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VetAppConstants.warningAmber,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => setState(() => _prescriptions.remove(p)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 18),

                    // Section 3: Recommended Lab Tests
                    Row(
                      children: [
                        const Text(
                          'Recommended Lab Tests',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VetAppConstants.ink),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 220,
                          height: 36,
                          child: TextField(
                            controller: _testNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Blood Smear PCR',
                              isDense: true,
                              hintStyle: const TextStyle(fontSize: 11.5),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add_circle, color: VetAppConstants.primaryBlue, size: 20),
                                onPressed: _addTest,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_tests.isEmpty)
                      const Text(
                        'No laboratory tests ordered.',
                        style: TextStyle(fontSize: 12, color: VetAppConstants.textMuted, fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tests.map((t) {
                          return Chip(
                            label: Text('${t.testName} (${t.status})', style: const TextStyle(fontSize: 11.5)),
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _tests.remove(t)),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 18),
                    const Divider(color: VetAppConstants.borderLight),
                    const SizedBox(height: 12),

                    // Section 4: Emergency Outbreak Flag & Status
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _suspectedOutbreak,
                      activeThumbColor: VetAppConstants.dangerRed,
                      title: const Text(
                        'Suspected Epidemic / Contagious Outbreak',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: VetAppConstants.dangerRed),
                      ),
                      subtitle: const Text(
                        'Flags this case for District Surveillance Cell & Auto-notifies Government Admin',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onChanged: (val) => setState(() => _suspectedOutbreak = val),
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Update Case Status:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VetAppConstants.ink),
                        ),
                        const SizedBox(width: 14),
                        DropdownButton<String>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(value: 'under_examination', child: Text('Under Examination')),
                            DropdownMenuItem(value: 'prescribed', child: Text('Prescribed / Active Treatment')),
                            DropdownMenuItem(value: 'resolved', child: Text('Resolved / Cured')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: VetAppConstants.borderLight)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Save & Synchronize Treatment', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: VetAppConstants.clinicalTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
