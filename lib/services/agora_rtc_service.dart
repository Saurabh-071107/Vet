import 'dart:async';
import 'package:flutter/foundation.dart';

class AgoraRtcService extends ChangeNotifier {
  static final AgoraRtcService _instance = AgoraRtcService._internal();
  factory AgoraRtcService() => _instance;
  AgoraRtcService._internal();

  // Agora Credentials & Channel Config
  String _appId = 'demo_agora_pashu_app_id';
  String? _channelName;
  String? _token;
  int _uid = 0;

  // Live Call State
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _remoteUserJoined = false;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;

  // Getters
  String get appId => _appId;
  String? get channelName => _channelName;
  String? get token => _token;
  int get uid => _uid;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get remoteUserJoined => _remoteUserJoined;
  int get callDurationSeconds => _callDurationSeconds;

  String get formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void configure({String? appId}) {
    if (appId != null && appId.isNotEmpty) {
      _appId = appId;
    }
  }

  Future<bool> joinChannel({
    required String channelName,
    String? token,
    int uid = 0,
  }) async {
    _channelName = channelName;
    _token = token;
    _uid = uid;
    _isJoined = true;
    _remoteUserJoined = true;
    _callDurationSeconds = 0;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<void> leaveChannel() async {
    _isJoined = false;
    _remoteUserJoined = false;
    _channelName = null;
    _durationTimer?.cancel();
    _callDurationSeconds = 0;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void switchCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}
