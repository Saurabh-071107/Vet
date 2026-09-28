import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/session_manager.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final isWide = MediaQuery.sizeOf(context).width >= VetAppConstants.tabletBreakpoint;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. DOCTOR HERO PROFILE CARD (LARGE)
                  _buildDoctorHeroCard(session),
                  const SizedBox(height: 14),

                  // 2. EMERGENCY DUTY AVAILABILITY (LARGE)
                  _buildDutyCard(session),
                  const SizedBox(height: 14),

                  // 3. CLINICAL IMPACT & ACTIVITY STATS (LARGE)
                  _buildImpactStatsGrid(),
                  const SizedBox(height: 14),

                  // 4. POSTING & OFFICIAL JURISDICTION (LARGE)
                  _buildPostingCard(session),
                  const SizedBox(height: 14),

                  // 5. EMERGENCY TOLL-FREE HELPLINE (LARGE)
                  _buildHelplineCard(),
                  const SizedBox(height: 16),

                  // 6. SIGN OUT BUTTON (LARGE)
                  _buildSignOutButton(context, session),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorHeroCard(SessionManager session) {
    final photoUrl = session.profilePhotoUrl;
    final initials = session.initials;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Large Avatar
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFF93C5FD), width: 2.5),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? (photoUrl.startsWith('http')
                      ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildInitialsAvatar(initials))
                      : Image.asset(photoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildInitialsAvatar(initials)))
                  : _buildInitialsAvatar(initials),
            ),
          ),
          const SizedBox(width: 16),

          // Core Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.vetName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.specialization,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Registration ID: ${session.licenseNumber}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: const Color(0xFF1D4ED8),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildDutyCard(SessionManager session) {
    final isOnDuty = session.isAvailableForCalls;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnDuty ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  boxShadow: isOnDuty
                      ? [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: 2.5,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Duty Availability',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnDuty ? 'Available for emergency farmer calls' : 'Currently Offline for calls',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isOnDuty ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            scale: 1.05,
            child: Switch.adaptive(
              value: isOnDuty,
              activeTrackColor: const Color(0xFF059669),
              onChanged: (val) => session.toggleAvailability(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStatsGrid() {
    const stats = [
      (Icons.healing_rounded, 'Cases Treated', '148', Color(0xFF1D4ED8), Color(0xFFEFF6FF)),
      (Icons.biotech_rounded, 'Lab Referrals', '86', Color(0xFF059669), Color(0xFFECFDF5)),
      (Icons.phone_in_talk_rounded, 'Triage Calls', '35', Color(0xFFD97706), Color(0xFFFFFBEB)),
      (Icons.location_city_rounded, 'Villages Covered', '12', Color(0xFF7C3AED), Color(0xFFF5F3FF)),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x050F172A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stats[i].$5,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stats[i].$1, size: 20, color: stats[i].$4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats[i].$3,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPostingCard(SessionManager session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical Posting & Jurisdiction',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.business_outlined, 'Dispensary', session.hospitalClinic),
          _infoRow(Icons.location_on_outlined, 'Jurisdiction', '${session.district}, ${session.state}'),
          _infoRow(Icons.phone_outlined, 'Official Phone', session.phone),
          _infoRow(Icons.email_outlined, 'Govt Email', session.email),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.support_agent_rounded, color: Color(0xFF059669), size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAHD Emergency Helpline: 1962',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF065F46)),
                ),
                SizedBox(height: 1),
                Text(
                  'Toll-Free 24x7 Veterinary Ambulance Service',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, SessionManager session) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Sign Out', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              content: const Text('Are you sure you want to log out of your session?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await session.logout();
                    widget.onLogout();
                  },
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
        label: const Text('Sign Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFECACA), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
