import 'package:flutter/material.dart';
import 'alumnos.dart';
import 'homeprofesor.dart';
import 'admin_screen.dart';
import '../service/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final correo = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      _showMessage('Por favor, completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _apiService.login(correo, password);

      if (user != null) {
        final rol = user['rol'] as String?;
        final userId = user['id'] as String;
        final nombre = user['nombre'] as String?;
        
        if (mounted) {
          if (rol == 'Alumno') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AsistenciasScreen(
                  userId: userId,
                  nombre: nombre,
                ),
              ),
            );
          } else if (rol == 'Profesor' || rol == 'Tutor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfessorDashboard(
                  userId: userId,
                  nombre: nombre,
                  rol: rol,
                ),
              ),
            );
          }else if (rol == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminScreen(
                  userId: userId,
                  nombre: nombre,
                ),
              ),
            );
          } else {
            _showMessage('Rol de usuario no reconocido');
          }
        }
      } else {
        _showMessage('Correo o contraseña incorrectos');
      }
    } catch (e) {
      _showMessage('Error al iniciar sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Stack(
        children: [
          // Círculos decorativos superiores
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF5B9DB8).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: 80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF8FC4DC).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF5B9DB8).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 100,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF8FC4DC).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'CONTROL+',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F72),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 18,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A95B8),
                          disabledBackgroundColor: const Color(0xFF4A95B8).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}