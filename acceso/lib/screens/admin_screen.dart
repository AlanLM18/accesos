import 'package:flutter/material.dart';
import 'users_screen.dart';
import 'entradas_salidas.dart';
import '../service/session_wrapper.dart';
import '../service/session_service.dart';
import '../service/api_service.dart';

class AdminScreen extends StatefulWidget {
  final String userId;
  final String? nombre;

  const AdminScreen({
    Key? key,
    required this.userId,
    this.nombre,
  }) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService();
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _sessionService.endSession();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              color: Color(0xFF003366),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoggingOut = true;
      });

      await _apiService.logout(widget.userId);
      
      _sessionService.endSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', 
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003366),
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'CONTROL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '+',
                style: TextStyle(
                  color: Color(0xFFFFA500), 
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _isLoggingOut ? null : _handleLogout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF003366),
                      Color(0xFF004080),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 60,
                      color: Color(0xFFFFA500),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ADMINISTRADOR',
                      style: TextStyle(
                        color: Color(0xFFFFA500),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Panel de Control',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),


              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      _buildAdminCard(
                        context: context,
                        icon: Icons.people,
                        title: 'Ver Usuarios',
                        description:
                            'Gestionar y visualizar todos los usuarios registrados',
                        color: const Color(0xFF003366),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UsersScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tarjeta Ver Entradas
                      _buildAdminCard(
                        context: context,
                        icon: Icons.assignment,
                        title: 'Ver Entradas',
                        description:
                            'Gestionar y visualizar todas las entradas del sistema',
                        color: const Color(0xFF003366),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EntradasSalidasScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),

            const SizedBox(width: 20),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}