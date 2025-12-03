import 'package:flutter/material.dart';
import 'qralumnos.dart';
import 'profile_screen.dart';
import '../service/session_wrapper.dart';
import '../service/session_service.dart';
import '../service/api_service.dart';
import 'tutor_screen.dart';
import 'grupos_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  final String userId;
  final String? nombre;
  final String? rol;

  const ProfessorDashboard({
    Key? key,
    required this.userId,
    this.nombre,
    this.rol,
  }) : super(key: key);

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _materias = [];
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
  }

  @override
  void dispose() {
    _sessionService.endSession();
    super.dispose();
  }

  Future<void> _cargarMaterias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("=== CARGANDO MATERIAS DEL PROFESOR ===");
      print("Profesor ID: ${widget.userId}");
      
      // Obtener materias del profesor
      final materias = await _apiService.getMateriasByProfesor(widget.userId);
      
      print("✓ ${materias.length} materias obtenidas de la tabla materias");
      
      // Mostrar detalles de cada materia
      for (var materia in materias) {
        print("Materia ID: ${materia['id']} - Nombre: ${materia['nom_mat']}");
      }
      
      // Simplemente guardar las materias con su ID real
      List<Map<String, dynamic>> materiasSimplificadas = [];
      
      for (var materia in materias) {
        materiasSimplificadas.add({
          'id': materia['id'], // Este es el ID de la tabla materias
          'nombre': materia['nom_mat'] ?? 'Sin nombre',
        });
      }
      
      setState(() {
        _materias = materiasSimplificadas;
        _isLoading = false;
      });
      
      print("✓ ${_materias.length} materias cargadas y listas para mostrar");
    } catch (e) {
      print("✗ Error al cargar materias: $e");
      setState(() {
        _isLoading = false;
      });
    }
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
              color: Color(0xFF004C8C),
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
                backgroundColor: const Color(0xFF004C8C),
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
        drawer: widget.rol == 'Tutor' ? _buildDrawer(context) : null,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                color: const Color(0xFFE8E8E8),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Materias que impartes',
                      style: TextStyle(
                        color: Color(0xFF004C8C),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentDate(),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF004C8C),
                              ),
                            )
                          : _materias.isEmpty
                              ? _buildEmptyState()
                              : _buildMateriasList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://www.uteq.edu.mx/Images/Noticias/474/1%20Comida.jpeg',
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF004C8C).withOpacity(0.8),
                const Color(0xFF004C8C).withOpacity(0.4),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (widget.rol == 'Tutor')
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Text(
                          'CONTROL+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userId: widget.userId,
                                  nombre: widget.nombre,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 30,
                          ),
                          tooltip: 'Perfil',
                        ),
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
                                  size: 30,
                                ),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFFFFB800),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.rol == 'Tutor' ? 'TUTOR' : 'PROFESOR',
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¡Bienvenid@ ${widget.nombre ?? 'Profesor'}!',
                        style: const TextStyle(
                          color: Color(0xFF004C8C),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Escanea tu QR para acceder al campus',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QRScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A9FD8),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.qr_code,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Código QR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMateriasList() {
    return RefreshIndicator(
      onRefresh: _cargarMaterias,
      color: const Color(0xFF004C8C),
      child: ListView.builder(
        itemCount: _materias.length,
        itemBuilder: (context, index) {
          final materia = _materias[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMateriaCard(materia),
          );
        },
      ),
    );
  }

  Widget _buildMateriaCard(Map<String, dynamic> materia) {
    return InkWell(
      onTap: () {
        print("\n=== NAVEGANDO A GRUPOS ===");
        print("Materia ID (tabla materias): ${materia['id']}");
        print("Materia Nombre: ${materia['nombre']}");
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GruposScreen(
              materiaId: materia['id'], // ID de la tabla materias
              materiaNombre: materia['nombre'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                materia['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  color: Color(0xFF004C8C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF004C8C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay materias asignadas',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacta con el administrador',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF004C8C),
                    Color(0xFF4A9FD8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.nombre ?? 'Tutor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Menú de Tutor',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.groups,
                color: Color(0xFF004C8C),
              ),
              title: const Text(
                'Grupos Tutorados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorScreen(
                      userId: widget.userId,
                      nombre: widget.nombre,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.home,
                color: Color(0xFF004C8C),
              ),
              title: const Text(
                'Inicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${now.day} de ${months[now.month - 1]} ${now.year}';
  }
}