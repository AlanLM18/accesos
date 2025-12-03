import 'package:flutter/material.dart';
import 'session_service.dart';
import '../screens/login_screen.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;

  const SessionWrapper({super.key, required this.child});

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionService.initialize(_handleSessionExpired);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionService.recordActivity();
    }
  }

  void _handleSessionExpired() {
    if (mounted) {
      _sessionService.endSession();
      
      // Mostrar diálogo de sesión expirada
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sesión Expirada'),
          content: const Text(
            'Tu sesión ha expirado por inactividad. Por favor, inicia sesión nuevamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _sessionService.recordActivity(),
      onPanDown: (_) => _sessionService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}