import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../service/api_service.dart';

class QRScreen extends StatefulWidget {
  final String userId;

  const QRScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _qrData;
  String? _errorMessage;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDataAndGenerateQR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _marcarQRComoUsadoAlSalir();
    super.dispose();
  }

  // Marcar QR como usado al salir
  Future<void> _marcarQRComoUsadoAlSalir() async {
    if (_qrData != null) {
      final qrCode = _qrData!['codigo'] as String?;
      if (qrCode != null && qrCode.isNotEmpty) {
        print("=== MARCANDO QR COMO USADO AL SALIR ===");
        print("QR Code: $qrCode");
        await _apiService.marcarQRUserComoUsado(qrCode);
      }
    }
  }

  // Detectar cuando la app va a segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      print("⚠️ App en segundo plano - marcando QR como usado");
      _marcarQRComoUsadoAlSalir();
    }
  }

  Future<void> _loadDataAndGenerateQR() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _apiService.getUserById(widget.userId);

      if (userData != null) {
        setState(() => _userData = userData);
        await _generateNewQR();
      } else {
        setState(() {
          _errorMessage = 'No se encontró información del usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewQR() async {
    try {
      print("=== GENERANDO NUEVO QR AL ENTRAR ===");
      
      final newQR = await _apiService.generateNewQRUser(widget.userId);
      
      if (newQR != null) {
        setState(() {
          _qrData = newQR;
          _secondsRemaining = 180;
          _isLoading = false;
        });
        
        print("✓ QR generado: ${newQR['codigo']}");
        _startCountdown();
      } else {
        setState(() {
          _errorMessage = 'Error al generar nuevo QR';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al generar QR: $e';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        print("⏰ QR expirado, generando uno nuevo...");
        _generateNewQR();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${now.day} de ${months[now.month - 1]} ${now.year}';
  }

  String _getRolLabel(String? rol) {
    if (rol == null) return 'USUARIO';
    
    switch (rol.toLowerCase()) {
      case 'alumno': return 'ESTUDIANTE';
      case 'profesor': return 'PROFESOR';
      case 'tutor': return 'TUTOR';
      default: return rol.toUpperCase();
    }
  }

  Color _getTimerColor() {
    if (_secondsRemaining > 120) return Colors.greenAccent;
    if (_secondsRemaining > 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Future<bool> _onWillPop() async {
    await _marcarQRComoUsadoAlSalir();
    return true;
  }

  @override
@override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF5B8CAE), // Evita el espacio blanco
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF003366), Color(0xFF5B8CAE)],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildQRContent(),
        ),
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 60),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loadDataAndGenerateQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF003366),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    final nombre = _userData?['nombre'] ?? 'Usuario';
    final matricula = _userData?['matricula'] ?? 'Sin matrícula';
    final rol = _userData?['rol'];
    final grupo = _userData?['grupo'];
    final qrCode = _qrData?['codigo'] ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF003366),
                    border: Border(bottom: BorderSide(color: Color(0xFF5B8CAE), width: 2)),
                  ),
                  child: const Text(
                    'CONTROL+',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () async {
                      await _marcarQRComoUsadoAlSalir();
                      if (mounted) Navigator.pop(context);
                    },
                    tooltip: 'Regresar',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Badge de rol
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFFFFC107), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRolLabel(rol),
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nombre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                nombre.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Fecha
            Text(
              _getCurrentDate(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),

            const SizedBox(height: 20),

            // Texto instructivo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Escanea tu QR para acceder al campus',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),

            const SizedBox(height: 16),

            // TEMPORIZADOR - Solo números
            Text(
              _formatTime(_secondsRemaining),
              style: TextStyle(
                color: _getTimerColor(),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 16),

            // QR Code
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getTimerColor().withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: qrCode.isNotEmpty
                  ? QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    )
                  : const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),

            const SizedBox(height: 20),

            // Matrícula
            Text(
              'Matrícula $matricula',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Grupo
            if (grupo != null && grupo.isNotEmpty)
              Text(
                grupo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

            const SizedBox(height: 20),

            // Advertencia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.7), size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'El QR se invalida al salir de esta pantalla',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
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