import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../services/vet_api_service.dart';

class OutbreaksView extends StatefulWidget {
  const OutbreaksView({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<OutbreaksView> createState() => OutbreaksViewState();
}

class OutbreaksViewState extends State<OutbreaksView> {
  final VetApiService _apiService = VetApiService();
  final MapController _mapController = MapController();

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _outbreaks = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: Map View, 1: Report
  Map<String, dynamic>? _selectedOutbreak;
  final Set<String> _expandedAlertIds = {};

  // Initial map center on Maharashtra (Pune & surrounding outbreak regions)
  final LatLng _initialCenter = const LatLng(18.75, 74.25);
  final double _initialZoom = 7.5;

  // Reporting Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _diseaseController = TextEditingController(text: 'Foot and Mouth Disease (FMD)');
  final _customDiseaseController = TextEditingController();
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController(text: 'Pune');
  final _casesCountController = TextEditingController(text: '5');
  String _selectedSeverity = 'Critical'; // 'Critical' (High Risk), 'High' (Medium Risk), 'Medium' (Low Risk)
  double _quarantineRadiusKm = 15.0;
  bool _isCustomDisease = false;
  bool _isSubmittingReport = false;

  final List<String> _commonDiseases = [
    'Foot and Mouth Disease (FMD)',
    'Lumpy Skin Disease (LSD)',
    'Anthrax Surveillance Cluster',
    'Bovine Anaplasmosis / Tick Fever',
    'Black Quarter (BQ)',
    'Brucellosis Screening',
    'Peste des Petits Ruminants (PPR)',
    'Other (Type Custom Disease)',
  ];

  final List<String> _districts = [
    'Pune',
    'Nashik',
    'Satara',
    'Solapur',
    'Aurangabad (Chhatrapati Sambhaji Nagar)',
    'Ahmednagar',
    'Kolhapur',
    'Sangli',
    'Jalgaon',
    'Nagpur',
    'Amravati',
    'Nanded',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOutbreaks();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _scrollController.dispose();
    _diseaseController.dispose();
    _customDiseaseController.dispose();
    _reasonController.dispose();
    _evidenceController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _casesCountController.dispose();
    super.dispose();
  }

  Future<void> _fetchOutbreaks() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getOutbreaks();
      if (mounted) {
        setState(() {
          _outbreaks = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching outbreaks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Public method so parent shells (like VetShell or Dashboard) can trigger the report screen
  void showReportOutbreakModal() {
    setState(() {
      _selectedTabIndex = 1;
    });
  }

  void _centerMapOnOutbreak(Map<String, dynamic> ob) {
    final epi = ob['epicenter'] as Map<String, dynamic>?;
    if (epi != null && epi['lat'] != null && epi['lng'] != null) {
      final target = LatLng((epi['lat'] as num).toDouble(), (epi['lng'] as num).toDouble());
      
      setState(() {
        _selectedOutbreak = ob;
        _selectedTabIndex = 0;
        final id = ob['id']?.toString() ?? '';
        if (id.isNotEmpty) _expandedAlertIds.add(id);
      });

      // Smoothly scroll the screen back up to the map window so the user sees the highlighted zone
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }

      _mapController.move(target, 10.2);

      final disease = ob['disease']?.toString() ?? 'Outbreak';
      final loc = ob['village']?.toString() ?? ob['district']?.toString() ?? '';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focused map on $disease ($loc)'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Color _getRiskColor(String? severity, String? riskLevel) {
    final s = (severity ?? '').toLowerCase();
    final r = (riskLevel ?? '').toLowerCase();
    if (s == 'critical' || r.contains('high')) {
      return const Color(0xFFDC2626); // Red
    } else if (s == 'high' || r.contains('medium')) {
      return const Color(0xFFF59E0B); // Amber / Orange
    } else {
      return const Color(0xFF10B981); // Emerald Green
    }
  }

  String _getRiskLabel(String? severity, String? riskLevel) {
    final s = (severity ?? '').toLowerCase();
    final r = (riskLevel ?? '').toLowerCase();
    if (s == 'critical' || r.contains('high')) {
      return 'High Risk';
    } else if (s == 'high' || r.contains('medium')) {
      return 'Medium Risk';
    } else {
      return 'Low Risk';
    }
  }

  Future<void> _submitOutbreakReport() async {
    if (!_formKey.currentState!.validate()) return;

    final diseaseName = _isCustomDisease
        ? _customDiseaseController.text.trim()
        : _diseaseController.text.trim();

    if (diseaseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or specify the disease name.')),
      );
      return;
    }

    setState(() => _isSubmittingReport = true);

    // Approximate latitude and longitude based on selected district
    double lat = 18.5204;
    double lng = 73.8567;
    final dist = _districtController.text.toLowerCase();
    if (dist.contains('nashik')) {
      lat = 19.9975;
      lng = 73.7898;
    } else if (dist.contains('satara')) {
      lat = 17.6805;
      lng = 74.0183;
    } else if (dist.contains('solapur')) {
      lat = 17.6599;
      lng = 75.9064;
    } else if (dist.contains('aurangabad') || dist.contains('sambhaji')) {
      lat = 19.8762;
      lng = 75.3433;
    } else if (dist.contains('kolhapur')) {
      lat = 16.7050;
      lng = 74.2433;
    } else if (dist.contains('nagpur')) {
      lat = 21.1458;
      lng = 79.0882;
    }

    final casesCount = int.tryParse(_casesCountController.text.trim()) ?? 5;
    final riskLabel = _selectedSeverity == 'Critical'
        ? 'High Risk'
        : (_selectedSeverity == 'High' ? 'Medium Risk' : 'Low Risk');

    try {
      final res = await _apiService.reportOutbreakToGovt(
        disease: diseaseName,
        reason: _reasonController.text.trim(),
        evidence: _evidenceController.text.trim(),
        severity: _selectedSeverity,
        clusterRadiusKm: _quarantineRadiusKm,
        lat: lat,
        lng: lng,
        casesCount: casesCount,
        district: _districtController.text.trim(),
        village: _villageController.text.trim().isNotEmpty
            ? '${_villageController.text.trim()}, ${_districtController.text.trim()}'
            : _districtController.text.trim(),
      );

      final newOutbreak = {
        'id': 'outbreak-${DateTime.now().millisecondsSinceEpoch}',
        'disease': diseaseName,
        'severity': _selectedSeverity,
        'riskLevel': riskLabel,
        'district': _districtController.text.trim(),
        'village': _villageController.text.trim().isNotEmpty
            ? '${_villageController.text.trim()}, ${_districtController.text.trim()}'
            : _districtController.text.trim(),
        'clusterRadiusKm': _quarantineRadiusKm.toInt(),
        'casesCount': casesCount,
        'epicenter': {'lat': lat, 'lng': lng},
        'reason': _reasonController.text.trim(),
        'evidence': _evidenceController.text.trim(),
        'status': 'Disaster Cell Alert Transmitted',
        'containmentMeasures': [
          'Immediate ${_quarantineRadiusKm.toInt()}km perimeter quarantine established',
          'Automated alert sent to Maharashtra State Disease Surveillance Cell'
        ],
        'reportedAgo': 'Just now',
        'reportedDate': 'Today',
      };

      if (mounted) {
        setState(() {
          _outbreaks.insert(0, newOutbreak);
          _isSubmittingReport = false;
          _selectedTabIndex = 0; // Return to Map View
          _expandedAlertIds.add(newOutbreak['id'].toString());
        });

        // Center map on newly reported outbreak
        Future.delayed(const Duration(milliseconds: 300), () {
          _centerMapOnOutbreak(newOutbreak);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ??
                'Outbreak reported and transmitted to Government Dashboard.'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Reset form
        _reasonController.clear();
        _evidenceController.clear();
        _villageController.clear();
        _customDiseaseController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingReport = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transmit outbreak report: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= VetAppConstants.tabletBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. TOP APP BAR (Back, Outbreak Reporting Title, Compass / Locate Icon)
                _buildTopAppBar(context),

                // 2. SEGMENTED TAB SWITCHER (Map View | Report)
                _buildSegmentedTabSwitcher(),

                // 3. MAIN CONTENT (Map View + Recent Alerts OR Report Form)
                Expanded(
                  child: _selectedTabIndex == 0
                      ? (isWide ? _buildWideMapView() : _buildMobileMapView())
                      : _buildReportFormView(isWide),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP APP BAR
  // ---------------------------------------------------------------------------
  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
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
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Outbreak Reporting',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SEGMENTED TAB SWITCHER (Map View | Report)
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Map View Tab Button
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? const Color(0xFF1D4ED8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _selectedTabIndex == 0 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),

          // Report Tab Button
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? const Color(0xFF1D4ED8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _selectedTabIndex == 1 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. MOBILE MAP VIEW (Scrollable with unhidden button & expandable details)
  // ---------------------------------------------------------------------------
  Widget _buildMobileMapView() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120), // Generous padding so floating bottom bar never obscures content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. High-Performance Interactive Map Container (Fixed responsive height)
          Container(
            height: 290,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                children: [
                  _buildOpenFreeMapWidget(),
                  // Floating Legend Bar at the bottom of the map view
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: _buildRiskLegendCard(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Section Header: Recent Alerts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_outbreaks.length} Active Zones',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. List of Recent Alerts (Expandable Cards with Dropdown)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: _outbreaks.map((ob) => _buildRecentAlertItem(ob)).toList(),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. WIDE / TABLET MAP VIEW (Split-Screen)
  // ---------------------------------------------------------------------------
  Widget _buildWideMapView() {
    return Row(
      children: [
        // Left Column: Interactive Map + Legend
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  _buildOpenFreeMapWidget(),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: _buildRiskLegendCard(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Column: Recent Alerts List & Quick Actions
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Outbreak Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => setState(() => _selectedTabIndex = 1),
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text(
                        'Report Outbreak',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _outbreaks.length,
                    itemBuilder: (context, index) {
                      final ob = _outbreaks[index];
                      return _buildRecentAlertItem(ob);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. OPENFREEMAP / CARTO VOYAGER TILE LAYER
  // ---------------------------------------------------------------------------
  Widget _buildOpenFreeMapWidget() {
    // Generate concentric risk circles
    final circleMarkers = <CircleMarker>[];
    final mapMarkers = <Marker>[];

    for (final ob in _outbreaks) {
      final epi = ob['epicenter'] as Map<String, dynamic>?;
      if (epi == null || epi['lat'] == null || epi['lng'] == null) continue;

      final point = LatLng((epi['lat'] as num).toDouble(), (epi['lng'] as num).toDouble());
      final radiusKm = (ob['clusterRadiusKm'] as num?)?.toDouble() ?? 15.0;
      final riskColor = _getRiskColor(ob['severity']?.toString(), ob['riskLevel']?.toString());
      final isSelected = _selectedOutbreak?['id'] == ob['id'];

      // Outer Heat Wave Glow
      circleMarkers.add(
        CircleMarker(
          point: point,
          radius: radiusKm * 1000,
          useRadiusInMeter: true,
          color: riskColor.withValues(alpha: isSelected ? 0.28 : 0.18),
          borderColor: riskColor.withValues(alpha: 0.55),
          borderStrokeWidth: 1.5,
        ),
      );

      // Inner Dense Risk Core
      circleMarkers.add(
        CircleMarker(
          point: point,
          radius: (radiusKm * 1000) * 0.45,
          useRadiusInMeter: true,
          color: riskColor.withValues(alpha: isSelected ? 0.45 : 0.32),
          borderColor: riskColor.withValues(alpha: 0.8),
          borderStrokeWidth: 1.8,
        ),
      );

      // Teardrop Marker with Icon
      mapMarkers.add(
        Marker(
          point: point,
          width: 80,
          height: 72,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedOutbreak = ob;
                final id = ob['id']?.toString() ?? '';
                if (id.isNotEmpty) _expandedAlertIds.add(id);
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // City / District Micro-Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ob['district']?.toString() ?? 'Zone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // High-reliability CartoDB Voyager Raster Tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.pashuseva.vet',
          maxZoom: 19,
        ),
        // Outbreak Containment Buffer Circles
        CircleLayer(circles: circleMarkers),
        // Outbreak Teardrop Markers
        MarkerLayer(markers: mapMarkers),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. RISK LEGEND CARD (MATCHING REFERENCE IMAGE)
  // ---------------------------------------------------------------------------
  Widget _buildRiskLegendCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // High Risk
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'High Risk',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          // Medium Risk
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Medium Risk',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          // Low Risk
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Low Risk',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. RECENT ALERT LIST ITEM CARD (WITH EXPANDABLE DETAILS DROPDOWN)
  // ---------------------------------------------------------------------------
  Widget _buildRecentAlertItem(Map<String, dynamic> ob) {
    final id = ob['id']?.toString() ?? '';
    final disease = ob['disease']?.toString() ?? 'Outbreak Alert';
    final district = ob['district']?.toString() ?? 'Pune';
    final village = ob['village']?.toString() ?? district;
    final reportedAgo = ob['reportedAgo']?.toString() ?? ob['reportedDate']?.toString() ?? 'Recently';
    final casesCount = ob['casesCount']?.toString() ?? '5';
    final radius = ob['clusterRadiusKm']?.toString() ?? '15';
    final reason = ob['reason']?.toString() ?? 'Clinical investigation ordered by Veterinary Officer.';
    final evidence = ob['evidence']?.toString() ?? 'Diagnostic samples dispatched to Disease Investigation Section.';
    final riskColor = _getRiskColor(ob['severity']?.toString(), ob['riskLevel']?.toString());
    final riskLabel = _getRiskLabel(ob['severity']?.toString(), ob['riskLevel']?.toString());
    final isExpanded = _expandedAlertIds.contains(id);

    IconData diseaseIcon = Icons.health_and_safety_rounded;
    if (disease.toLowerCase().contains('fmd') || disease.toLowerCase().contains('mouth')) {
      diseaseIcon = Icons.coronavirus_rounded;
    } else if (disease.toLowerCase().contains('lumpy') || disease.toLowerCase().contains('lsd')) {
      diseaseIcon = Icons.shield_outlined;
    } else if (disease.toLowerCase().contains('anthrax')) {
      diseaseIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? riskColor.withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row with Dropdown Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedAlertIds.remove(id);
                  } else {
                    _expandedAlertIds.add(id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Organ / Disease Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(diseaseIcon, color: riskColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Outbreak Title & Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            village,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reported Ago + Dropdown Arrow Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          reportedAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable Details Section
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          riskLabel,
                          style: TextStyle(color: riskColor, fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Buffer: $radius km',
                          style: const TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cases: $casesCount Cattle',
                          style: const TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Clinical Reason
                  const Text('Reason / Symptoms:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(reason, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35)),
                  const SizedBox(height: 8),

                  // Evidence
                  const Text('Diagnostic Evidence:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(evidence, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35)),
                  const SizedBox(height: 12),

                  // Center on Map Action
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1D4ED8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _centerMapOnOutbreak(ob),
                      icon: const Icon(Icons.location_searching_rounded, size: 16, color: Color(0xFF1D4ED8)),
                      label: const Text('View on Map', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
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
  // 8. REPORT FORM VIEW (SENT TO GOVERNMENT DASHBOARD)
  // ---------------------------------------------------------------------------
  Widget _buildReportFormView(bool isWide) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 650 : double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120), // Avoid hiding under bottom nav bar
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disaster Surveillance Dispatch',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Transmits real-time alert with reason & evidence to Government Admin Dashboard.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Suspected Disease
                const Text(
                  'Suspected Disease *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _diseaseController.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _commonDiseases
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13.5))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _diseaseController.text = val;
                        _isCustomDisease = val.contains('Other');
                      });
                    }
                  },
                ),
                if (_isCustomDisease) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customDiseaseController,
                    decoration: InputDecoration(
                      hintText: 'Type exact disease name (e.g. Ephemeral Fever)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please specify disease name' : null,
                  ),
                ],
                const SizedBox(height: 16),

                // 2. Clinical Reason / Observations
                const Text(
                  'Reason for Suspecting Outbreak *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Describe symptom patterns, transmission speed, fever, mortality, or cluster occurrences.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Rapidly spreading oral blisters, lameness, and 105°F fever across 6 herd animals...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter the outbreak reason' : null,
                ),
                const SizedBox(height: 16),

                // 3. Evidence & Findings
                const Text(
                  'Evidence & Diagnostic Findings *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Specify test kits used, PCR/swab lab dispatches, clinical lesions photos, or necropsy findings.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _evidenceController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Lateral flow antigen swab positive; sample sent to Regional Lab for confirmation.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please provide clinical evidence' : null,
                ),
                const SizedBox(height: 16),

                // 4. District & Village
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('District *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _districtController.text,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _districts
                                .map((d) => DropdownMenuItem(value: d.split(' ').first, child: Text(d.split(' ').first, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _districtController.text = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Village / Block *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _villageController,
                            style: const TextStyle(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. Khed / Shirur',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter village' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Affected Cases Count & Severity
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Affected Animals *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _casesCountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. 8',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter number' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Risk Severity *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSeverity,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Critical', child: Text('Critical (High Risk)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'High', child: Text('High (Medium Risk)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Medium', child: Text('Moderate (Low Risk)', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSeverity = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Quarantine Perimeter Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quarantine Buffer Zone:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text('${_quarantineRadiusKm.toInt()} km Radius', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                  ],
                ),
                Slider(
                  value: _quarantineRadiusKm,
                  min: 5.0,
                  max: 35.0,
                  divisions: 6,
                  activeColor: const Color(0xFF1D4ED8),
                  label: '${_quarantineRadiusKm.toInt()} km',
                  onChanged: (val) => setState(() => _quarantineRadiusKm = val),
                ),
                const SizedBox(height: 24),

                // SUBMIT BUTTON TO GOVERNMENT DASHBOARD
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // Emergency Red
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmittingReport ? null : _submitOutbreakReport,
                    icon: _isSubmittingReport
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                    label: Text(
                      _isSubmittingReport
                          ? 'Transmitting to Government Dashboard...'
                          : 'Transmit Outbreak Report to Govt Dashboard',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
