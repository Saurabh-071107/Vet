import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/vet_api_service.dart';

class VaccinationView extends StatefulWidget {
  const VaccinationView({super.key});

  @override
  State<VaccinationView> createState() => _VaccinationViewState();
}

class _VaccinationViewState extends State<VaccinationView> {
  final VetApiService _apiService = VetApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getVaccinationBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vaccination bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsAdministered(Map<String, dynamic> booking) async {
    final bookingId = booking['id']?.toString() ?? '';
    final animalName = booking['animalName']?.toString() ?? 'Livestock';
    final vaccineName = booking['vaccineName']?.toString() ?? 'Vaccine';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Confirm Administration',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark $vaccineName as administered to $animalName (${booking['animalTag']})?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Batch: ${booking['batchNumber'] ?? "VAC-2026-01"} · Digital certificate will be issued to farmer.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.updateVaccinationBookingStatus(bookingId, 'Administered');
      setState(() {
        final idx = _bookings.indexWhere((b) => b['id'] == bookingId);
        if (idx != -1) {
          _bookings[idx]['status'] = 'Administered';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vaccination recorded for $animalName ($vaccineName)'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
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
        final horizontalPadding = isWide ? 28.0 : 16.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VetAppConstants.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TOP HEADER (Title + Total Count + Live Sync Refresh)
                      _buildHeader(),
                      const SizedBox(height: 14),

                      // 2. BOOKED SLOTS LIST (Minimum White Space, 100% responsive, Zero overflows)
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _bookings.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _loadBookings,
                                    color: const Color(0xFF1D4ED8),
                                    child: isWide
                                        ? _buildWideGridBookings()
                                        : _buildMobileBookingsList(),
                                  ),
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
  // 1. TOP HEADER (WITHOUT SORTING / FILTER BAR)
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vaccination Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_bookings.length} Farmer Booked Slots Scheduled',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loadBookings,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF1D4ED8),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. MOBILE LIST OF BOOKED SLOTS
  // ---------------------------------------------------------------------------
  Widget _buildMobileBookingsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. WIDE / TABLET 2-COLUMN GRID
  // ---------------------------------------------------------------------------
  Widget _buildWideGridBookings() {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 195,
      ),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. BOOKED VACCINATION SLOT CARD (ZERO OVERFLOWS & RESPONSIVE CONSTRAINTS)
  // ---------------------------------------------------------------------------
  Widget _buildBookingCard(Map<String, dynamic> b) {
    final animalName = b['animalName']?.toString() ?? 'Livestock';
    final animalTag = b['animalTag']?.toString() ?? 'TAG-0000';
    final species = b['species']?.toString() ?? 'Cattle';
    final farmerName = b['farmerName']?.toString() ?? 'Farmer';
    final village = b['village']?.toString() ?? 'Pune';
    final vaccineName = b['vaccineName']?.toString() ?? 'Vaccination';
    final doseType = b['doseType']?.toString() ?? 'Scheduled Dose';
    final bookedDate = b['bookedDate']?.toString() ?? 'Today';
    final timeSlot = b['timeSlot']?.toString() ?? '09:00 AM - 12:00 PM';
    final status = b['status']?.toString() ?? 'Confirmed';
    final photoUrl = b['photoUrl']?.toString() ?? '';
    final isDone = status.toLowerCase().contains('admin');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Animal Photo/Avatar + Animal Name & Tag ID + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animal Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: photoUrl.isNotEmpty
                      ? (photoUrl.startsWith('http')
                          ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildInitials(animalName))
                          : Image.asset(photoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildInitials(animalName)))
                      : _buildInitials(animalName),
                ),
              ),
              const SizedBox(width: 10),

              // Animal Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$animalName ($species)',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            animalTag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Farmer: $farmerName • $village',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isDone ? const Color(0xFF059669) : const Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 9),

          // Row 2: Vaccine Name & Dose Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.vaccines_rounded, size: 15, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccineName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      doseType,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // Row 3: Date & Time Slot Pill + Action Button
          Row(
            children: [
              // Date & Time Slot (Expanded with flexible text to prevent any overflow)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        bookedDate,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          timeSlot,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action Button
              if (!isDone)
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _markAsAdministered(b),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                    label: const Text(
                      'Administer',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                      SizedBox(width: 3),
                      Text(
                        'Done',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
    return Container(
      color: const Color(0xFF1D4ED8),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.event_available_rounded, color: Color(0xFF94A3B8), size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Booked Vaccination Slots Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap refresh to check live farmer bookings.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
