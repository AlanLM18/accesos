import 'package:flutter/material.dart';
import '../service/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String? nombre;

  const ProfileScreen({
    Key? key,
    required this.userId,
    this.nombre,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("=== CARGANDO USUARIO ===");
      print("User ID: ${widget.userId}");
      
      final usuario = await _apiService.getUserById(widget.userId);
      
      print("Usuario recibido: $usuario");
      
      if (usuario != null && mounted) {
        setState(() {
          _userData = usuario;
          _isLoading = false;
        });
        
        print("✓ Datos guardados en _userData");
        print("Nombre: ${_userData?['nombre']}");
        print("Correo: ${_userData?['correo']}");
        print("Matrícula: ${_userData?['matricula']}");
        print("Grupo: ${_userData?['grupo']}");
        print("Rol: ${_userData?['rol']}");
      } else {
        setState(() {
          _isLoading = false;
        });
        print("✗ No se pudieron cargar los datos del usuario");
      }
    } catch (e) {
      print("✗ Error al cargar datos del usuario: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPrimerNombre(String? nombreCompleto) {
    if (nombreCompleto == null || nombreCompleto.isEmpty) {
      return 'Usuario';
    }
    return nombreCompleto.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando, mostrar spinner
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF003366).withOpacity(0.8),
                const Color(0xFF003366).withOpacity(0.9),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    // Extraer datos DESPUÉS de verificar que no está cargando
    final imagenUrl = _userData?['imagen'];
    final nombre = _userData?['nombre'] ?? widget.nombre ?? 'Usuario';
    final correo = _userData?['correo'] ?? 'No disponible';
    final matricula = _userData?['matricula']?.toString() ?? 'No disponible';
    final grupo = _userData?['grupo'] ?? 'No asignado';
    final rol = _userData?['rol'] ?? 'Usuario';

    print("=== DEBUG FINAL ===");
    print("_userData: $_userData");
    print("Imagen: $imagenUrl");
    print("Nombre: $nombre");
    print("Correo: $correo");
    print("Matrícula: $matricula");
    print("Grupo: $grupo");
    print("Rol: $rol");
    print("==================");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fondo gris claro uniforme
      body: Column(
        children: [
          // Header con gradiente - Stack para que la imagen sobresalga
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Fondo azul con imagen
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR86wguF7Jnm9XV-S7qtwyVHxKi3BBA792Lgw&s',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF003366).withOpacity(0.8),
                        const Color(0xFF003366).withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'Mi Perfil',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Foto de perfil que sobresale - posicionada en la parte inferior del fondo
              Positioned(
                bottom: -100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const CircleAvatar(
                            radius: 100,
                            backgroundColor: Colors.white,
                            child: CircularProgressIndicator(
                              color: Color(0xFF003366),
                            ),
                          )
                        : ClipOval(
                            child: imagenUrl != null && imagenUrl.isNotEmpty
                                ? Image.network(
                                    imagenUrl,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.white,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: const Color(0xFF003366),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const CircleAvatar(
                                        radius: 100,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 100,
                                          color: Color(0xFF003366),
                                        ),
                                      );
                                    },
                                  )
                                : const CircleAvatar(
                                    radius: 100,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Color(0xFF003366),
                                    ),
                                  ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          
          // Espaciado para la foto que sobresale
          const SizedBox(height: 100),
          
          // Contenido del perfil
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF003366),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarDatosUsuario,
                      color: const Color(0xFF003366),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Título fuera de la tarjeta
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                          ),
                          
                          // Tarjeta de información sin título
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Icons.person,
                                    'Nombre Completo',
                                    nombre,
                                  ),
                                  const Divider(height: 30),
                                  _buildInfoRow(
                                    Icons.email,
                                    'Correo',
                                    correo,
                                  ),
                                  const Divider(height: 30),
                                  _buildInfoRow(
                                    Icons.badge,
                                    'Matrícula',
                                    matricula,
                                  ),
                                  const Divider(height: 30),
                                  _buildInfoRow(
                                    Icons.group,
                                    'Grupo',
                                    grupo,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    // Determinar si es el campo de correo para ajustar el tamaño
    final isEmail = label == 'Correo';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF003366).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF003366),
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isEmail ? 13 : 15, // Correo más pequeño
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003366),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}