import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/session_manager.dart';
import 'dashboard_view.dart';
import 'consultations_view.dart';
import 'cases_view.dart';
import 'profile_view.dart';

class VetShell extends StatefulWidget {
  const VetShell({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<VetShell> createState() => _VetShellState();
}

class _VetShellState extends State<VetShell> {
  int _currentTab = 0;

  void _navigateToTab(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= VetAppConstants.tabletBreakpoint;
    final session = SessionManager();

    final views = [
      DashboardView(
        onNavigateToTab: _navigateToTab,
        onReportOutbreak: () => _navigateToTab(2),
      ),
      ConsultationsView(onBack: () => _navigateToTab(0)),
      CasesView(onBack: () => _navigateToTab(0)),
      ProfileView(onLogout: widget.onLogout),
    ];

    if (isWide) {
      return Scaffold(
        backgroundColor: VetAppConstants.background,
        body: SafeArea(
          child: Row(
            children: [
              _buildNavigationRail(context, session),
              const VerticalDivider(width: 1, color: VetAppConstants.borderLight),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: views,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile Phone Layout with Floating Mockup Bottom Navigation Bar
    return Scaffold(
      backgroundColor: VetAppConstants.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTab,
          children: views,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildNavigationRail(BuildContext context, SessionManager session) {
    return Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/national_emblem.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: VetAppConstants.primaryTeal, size: 28),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'महाराष्ट्र शासन',
                        style: TextStyle(
                          color: VetAppConstants.primaryTeal,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'पशुसंवर्धन विभाग',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: VetAppConstants.borderLight),
          const SizedBox(height: 16),

          // Nav Items
          _railItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _railItem(1, Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded, 'Queue'),
          _railItem(2, Icons.people_outline_rounded, Icons.people_rounded, 'Patients'),
          _railItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),

          const Spacer(),

          // Doctor Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetAppConstants.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2EF),
                  child: Text(
                    session.initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: VetAppConstants.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.doctorName.isNotEmpty ? session.doctorName : 'Dr. Rohit Patil',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      Text(
                        '${session.district} District',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(int index, IconData outlineIcon, IconData activeIcon, String label) {
    final isSelected = _currentTab == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTab(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE0F2EF) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : outlineIcon,
                  size: 20,
                  color: isSelected ? VetAppConstants.primaryTeal : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? VetAppConstants.primaryTeal : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded, 'Queue'),
      (Icons.people_outline_rounded, Icons.people_rounded, 'Patients'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _buildBottomNavItem(
                index: i,
                outlineIcon: items[i].$1,
                activeIcon: items[i].$2,
                label: items[i].$3,
                isSelected: _currentTab == i,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData outlineIcon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    if (isSelected) {
      // Active Pill Design (matching Home pill in mockup)
      return InkWell(
        onTap: () => _navigateToTab(index),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2EF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activeIcon, size: 20, color: VetAppConstants.primaryTeal),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: VetAppConstants.primaryTeal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Inactive Item
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(outlineIcon, size: 22, color: const Color(0xFF64748B)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
