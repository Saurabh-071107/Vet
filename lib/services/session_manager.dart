import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'vet_api_service.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isLoggedIn = false;
  String? _token;
  String _vetId = 'usr-vet-1';
  String _vetName = 'Dr. Anand Sharma';
  String? _profilePhotoUrl = 'assets/images/doctor_1.png';
  String _designation = 'Veterinary Officer (B.V.Sc & A.H.)';
  String _email = 'dr.sharma@vetcare.in';
  String _phone = '+91 98220 11223';
  String _specialization = 'Bovine Medicine & Surgery';
  String _licenseNumber = 'VCI-MH-2018-8472';
  String _hospitalClinic = 'Rural Veterinary Dispensary, Pune Division';
  String _district = 'Pune';
  final String _state = 'Maharashtra';
  bool _isAvailableForCalls = true;
  bool _emergencyDuty = false;
  String _language = 'en';
  String _apiUrl = VetAppConstants.defaultApiUrl;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String get vetId => _vetId;
  String get vetName => _vetName;
  String? get profilePhotoUrl => _profilePhotoUrl;
  String get designation => _designation;
  String get email => _email;
  String get phone => _phone;
  String get specialization => _specialization;
  String get licenseNumber => _licenseNumber;
  String get hospitalClinic => _hospitalClinic;
  String get district => _district;
  String get state => _state;
  bool get isAvailableForCalls => _isAvailableForCalls;
  bool get emergencyDuty => _emergencyDuty;
  String get language => _language;
  String get apiUrl => _apiUrl;

  /// Returns initials of the vet's name (e.g. 'RP' for 'Dr. Rohit Patil')
  String get initials {
    if (_vetName.trim().isEmpty) return 'VT';
    final clean = _vetName.replaceAll(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'VT';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('vet_is_logged_in') ?? false;
      _token = prefs.getString('vet_token');
      _vetId = prefs.getString('vet_id') ?? _vetId;
      _vetName = prefs.getString('vet_name') ?? _vetName;
      _profilePhotoUrl = prefs.getString('vet_profile_photo');
      _designation = prefs.getString('vet_designation') ?? _designation;
      _email = prefs.getString('vet_email') ?? _email;
      _phone = prefs.getString('vet_phone') ?? _phone;
      _specialization = prefs.getString('vet_specialization') ?? _specialization;
      _licenseNumber = prefs.getString('vet_license') ?? _licenseNumber;
      _hospitalClinic = prefs.getString('vet_clinic') ?? _hospitalClinic;
      _district = prefs.getString('vet_district') ?? _district;
      _isAvailableForCalls = prefs.getBool('vet_available') ?? true;
      _emergencyDuty = prefs.getBool('vet_emergency_duty') ?? false;
      _language = prefs.getString('vet_lang') ?? 'en';
      _apiUrl = prefs.getString('vet_api_url') ?? VetAppConstants.defaultApiUrl;

      VetApiService().setBaseUrl(_apiUrl);
      if (_token != null) {
        VetApiService().setToken(_token!);
      }
    } catch (e) {
      debugPrint('SessionManager init error: $e');
    }
    notifyListeners();
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _isLoggedIn = true;
    _token = token;
    _vetId = user['id'] ?? _vetId;
    _vetName = user['name'] ?? _vetName;
    _email = user['email'] ?? _email;
    _phone = user['phone'] ?? _phone;
    _specialization = user['specialization'] ?? _specialization;
    _licenseNumber = user['licenseNumber'] ?? _licenseNumber;
    _hospitalClinic = user['hospitalClinic'] ?? _hospitalClinic;
    _district = user['district'] ?? _district;
    _isAvailableForCalls = user['availableForCalls'] ?? true;

    VetApiService().setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vet_is_logged_in', true);
    await prefs.setString('vet_token', token);
    await prefs.setString('vet_id', _vetId);
    await prefs.setString('vet_name', _vetName);
    await prefs.setString('vet_email', _email);
    await prefs.setString('vet_phone', _phone);
    await prefs.setString('vet_specialization', _specialization);
    await prefs.setString('vet_license', _licenseNumber);
    await prefs.setString('vet_clinic', _hospitalClinic);
    await prefs.setString('vet_district', _district);
    await prefs.setBool('vet_available', _isAvailableForCalls);

    notifyListeners();
  }

  Future<void> loginDemoVet() async {
    try {
      final res = await VetApiService().login('dr.sharma@vetcare.in', 'password123');
      if (res['token'] != null && res['user'] != null) {
        await saveSession(
          token: res['token'],
          user: Map<String, dynamic>.from(res['user']),
        );
        return;
      }
    } catch (_) {}

    final demoUser = {
      'id': 'usr-vet-1',
      'name': 'Dr. Anand Sharma',
      'email': 'dr.sharma@vetcare.in',
      'phone': '+91 98220 11223',
      'specialization': 'Bovine Medicine & Surgery',
      'licenseNumber': 'VCI-MH-2018-8472',
      'hospitalClinic': 'Rural Veterinary Dispensary, Pune Division',
      'district': 'Pune',
      'availableForCalls': true,
    };
    await saveSession(token: 'demo-vet-jwt-token-anand-sharma', user: demoUser);
  }

  Future<void> toggleAvailability(bool val) async {
    _isAvailableForCalls = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vet_available', val);
    notifyListeners();
  }

  Future<void> toggleEmergencyDuty(bool val) async {
    _emergencyDuty = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vet_emergency_duty', val);
    notifyListeners();
    // Fire-and-forget backend sync — ok if it fails (offline mode)
    try {
      await VetApiService().setEmergencyDuty(val);
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vet_lang', lang);
    notifyListeners();
  }

  Future<void> setApiUrl(String url) async {
    _apiUrl = url;
    VetApiService().setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vet_api_url', url);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    VetApiService().setToken('');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
