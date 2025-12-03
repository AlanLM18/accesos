import 'dart:async';
import 'package:flutter/material.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  VoidCallback? _onSessionExpired;
  
  static const Duration _sessionTimeout = Duration(minutes: 30);

  void initialize(VoidCallback onSessionExpired) {
    _onSessionExpired = onSessionExpired;
    _lastActivityTime = DateTime.now();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      if (_lastActivityTime != null) {
        final difference = now.difference(_lastActivityTime!);
        if (difference >= _sessionTimeout) {
          _expireSession();
        }
      }
    });
  }

  void recordActivity() {
    _lastActivityTime = DateTime.now();
  }

  void _expireSession() {
    _inactivityTimer?.cancel();
    _lastActivityTime = null;
    _onSessionExpired?.call();
  }

  void endSession() {
    _inactivityTimer?.cancel();
    _lastActivityTime = null;
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}