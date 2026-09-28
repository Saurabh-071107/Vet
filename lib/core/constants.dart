import 'package:flutter/material.dart';

class VetAppConstants {
  static const String appName = 'Pashu Seva - Veterinarian';
  static const String stateDepartment = 'महाराष्ट्र शासन · पशुसंवर्धन विभाग';
  static const String appMotto = 'निरोगी पशु, समृद्ध महाराष्ट्र';

  // Network API Base URLs
  static const String defaultApiUrl = 'http://10.0.2.2:5000/api';
  static const String localhostApiUrl = 'http://localhost:5000/api';

  // Brand & Medical Color Palette (Redesigned matching Sep 28 Mockup)
  static const Color primaryTeal = Color(0xFF0B6057);
  static const Color primaryTealDark = Color(0xFF074740);
  static const Color primaryNavy = Color(0xFF0B6057);
  static const Color primaryBlue = Color(0xFF0B6057);
  static const Color clinicalTeal = Color(0xFF0B6057);
  static const Color clinicalTealLight = Color(0xFFE0F2EF);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentGreenLight = Color(0xFFDCFCE7);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color amberBadge = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedLight = Color(0xFFFEE2E2);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color ink = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color notesBrown = Color(0xFF854D0E);

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 760.0;
  static const double desktopBreakpoint = 1000.0;
  static const double maxContentWidth = 1100.0;

  // Shared Card Box Decoration
  static BoxDecoration cardDecoration({Color color = Colors.white, double radius = 16.0, Border? border}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: borderLight, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A102A4A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // Bilingual Dictionary (English / Marathi)
  static final Map<String, Map<String, String>> localizedStrings = {
    'dashboard': {'en': 'Dashboard', 'mr': 'डॅशबोर्ड'},
    'cases': {'en': 'Assigned Cases', 'mr': 'नियुक्त प्रकरणे'},
    'outbreaks': {'en': 'Outbreaks & GIS', 'mr': 'प्रकोप नियंत्रण'},
    'consultations': {'en': 'Consultations', 'mr': 'दूरध्वनी सल्ला'},
    'profile': {'en': 'Doctor Profile', 'mr': 'प्रोफाइल'},
    'emergency_available': {'en': 'Available for Emergency Calls', 'mr': 'आपत्कालीन सेवेसाठी उपलब्ध'},
    'quick_actions': {'en': 'Quick Actions', 'mr': 'द्रुत क्रिया'},
    'announcements': {'en': 'Government Announcements', 'mr': 'शासकीय परिपत्रके'},
    'report_outbreak': {'en': 'Report Outbreak', 'mr': 'प्रकोप नोंदवा'},
    'examine_case': {'en': 'Examine & Prescribe', 'mr': 'तपासणी व औषधोपचार'},
  };

  static String tr(String key, String lang) {
    return localizedStrings[key]?[lang] ?? localizedStrings[key]?['en'] ?? key;
  }
}
