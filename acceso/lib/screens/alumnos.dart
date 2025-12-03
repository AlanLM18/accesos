import 'package:flutter/material.dart';
import 'qralumnos.dart';
import 'profile_screen.dart';
import 'asistencia_materia.dart';
import '../service/session_wrapper.dart';
import '../service/session_service.dart';
import '../service/api_service.dart';

class AsistenciasScreen extends StatefulWidget {  
  final String userId;
  final String? nombre;

  const AsistenciasScreen({
    Key? key, 
    required this.userId,
    this.nombre,
  }) : super(key: key);

  @override
  State<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends State<AsistenciasScreen> {
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService();
  bool _isLoggingOut = false;
  bool _isLoading = true;
  
  String? _grupo;
  List<Map<String, dynamic>> _materias = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosEstudiante();
  }

  @override
  void dispose() {
    _sessionService.endSession();  
    super.dispose();
  }

  Future<void> _cargarDatosEstudiante() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("========== INICIANDO CARGA DE DATOS ==========");
      print("User ID: ${widget.userId}");
      
      final datos = await _apiService.getDatosEstudiante(widget.userId);
      
      print("Datos recibidos: $datos");
      
      if (datos != null && mounted) {
        print("Grupo: ${datos['grupo']}");
        print("Materias: ${datos['materias']}");
        print("Número de materias: ${(datos['materias'] as List).length}");
        
        setState(() {
          _grupo = datos['grupo'] as String?;
          _materias = (datos['materias'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        
        print("✓ Datos cargados: Grupo $_grupo, ${_materias.length} materias");
      } else {
        setState(() {
          _isLoading = false;
        });
        print("✗ No se pudieron cargar los datos del estudiante");
      }
    } catch (e) {
      print("✗ Error al cargar datos: $e");
      print("✗ Stack trace: ${StackTrace.current}");
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

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${now.day} de ${months[now.month - 1]} ${now.year}';
  }

  String _getPrimerNombre(String? nombreCompleto) {
    if (nombreCompleto == null || nombreCompleto.isEmpty) {
      return 'Usuario';
    }
    return nombreCompleto.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return SessionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(context),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF003366),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarDatosEstudiante,
                      color: const Color(0xFF003366),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Registro de asistencias',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003366),
                                    ),
                                  ),
                                  if (_grupo != null)
                                    Text(
                                      'Grupo $_grupo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _getCurrentDate(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_materias.isEmpty)
                                        _buildEmptyState()
                                      else
                                        ..._materias.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final materia = entry.value;
                                          final isLast = index == _materias.length - 1;
                                          
                                          return AsistenciaItem(
                                            userId: widget.userId,
                                            materia: materia['nombre'] ?? 'Sin nombre',
                                            claseId: materia['id'] ?? '',
                                            porcentaje: '${materia['porcentaje']}%',
                                            isLast: isLast,
                                            grupo: _grupo ?? 'Sin grupo',
                                            docente: materia['docente'],
                                          );
                                        }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay materias registradas',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacta con tu tutor',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
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
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR86wguF7Jnm9XV-S7qtwyVHxKi3BBA792Lgw&s',
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
                const Color(0xFF003366).withOpacity(0.8),
                const Color(0xFF003366).withOpacity(0.4),
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
                    const Text(
                      'CONTROL+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
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
                    color: const Color(0xFFFFC107),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ESTUDIANTE',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
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
                        '¡Bienvenid@ ${_getPrimerNombre(widget.nombre)}!',
                        style: const TextStyle(
                          color: Color(0xFF003366),
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
                              builder: (context) => QRScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
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
}

class AsistenciaItem extends StatelessWidget {
  final String userId;
  final String materia;
  final String claseId;
  final String porcentaje;
  final bool isLast;
  final String grupo;
  final String? docente;

  const AsistenciaItem({
    Key? key,
    required this.userId,
    required this.materia,
    required this.claseId,
    required this.porcentaje,
    this.isLast = false,
    required this.grupo,
    this.docente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final porcentajeNum = int.tryParse(porcentaje.replaceAll('%', '')) ?? 0;
    
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AsistenciaMateriaScreen(
                  userId: userId,
                  claseId: claseId,
                  materiaNombre: materia,
                  porcentaje: porcentajeNum,
                  grupo: grupo,
                  docente: docente,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    materia,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Asistencias',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      porcentaje,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 1,
          ),
      ],
    );
  }
}