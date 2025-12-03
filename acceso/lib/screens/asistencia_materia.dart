import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';

class AsistenciaMateriaScreen extends StatefulWidget {
  final String materiaNombre;
  final int porcentaje;
  final String grupo;
  final String? docente;
  final String userId;
  final String claseId;

  const AsistenciaMateriaScreen({
    Key? key,
    required this.materiaNombre,
    required this.porcentaje,
    required this.grupo,
    this.docente,
    required this.userId,
    required this.claseId,
  }) : super(key: key);

  @override
  State<AsistenciaMateriaScreen> createState() => _AsistenciaMateriaScreenState();
}

class _AsistenciaMateriaScreenState extends State<AsistenciaMateriaScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _inasistencias = [];
  Map<String, int> _estadisticas = {'total': 0, 'presentes': 0, 'faltas': 0};
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("========== CARGANDO INASISTENCIAS ==========");
      print("User ID: ${widget.userId}");
      print("Clase ID: ${widget.claseId}");
      
      // Cargar estadísticas
      final estadisticas = await _apiService.getEstadisticasAsistencia(
        widget.userId, 
        widget.claseId
      );
      
      // Cargar inasistencias (faltas)
      final inasistencias = await _apiService.getInasistenciasByAlumnoYMateria(
        widget.userId, 
        widget.claseId
      );
      
      print("✓ ${inasistencias.length} faltas encontradas");
      print("✓ Estadísticas: ${estadisticas['total']} total, ${estadisticas['presentes']} presentes, ${estadisticas['faltas']} faltas");
      
      if (mounted) {
        setState(() {
          _inasistencias = inasistencias;
          _estadisticas = estadisticas;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("✗ Error al cargar datos: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return 'Hoy es ${now.day} de ${months[now.month - 1]} ${now.year}';
  }

  Color _getColorByPercentage() {
    if (widget.porcentaje >= 90) {
      return const Color(0xFF4CAF50); // Verde - Excelente
    } else if (widget.porcentaje >= 80) {
      return const Color(0xFFFFC107); // Amarillo - Riesgo
    } else {
      return const Color(0xFFF44336); // Rojo - Reprobado
    }
  }

  String _getStatusText() {
    if (widget.porcentaje >= 90) {
      return 'Excelente';
    } else if (widget.porcentaje >= 80) {
      return 'Riesgo';
    } else {
      return 'Reprobado';
    }
  }
  
  String _formatearFecha(String fecha) {
    try {
      final DateTime date = DateTime.parse(fecha);
      final DateFormat formatter = DateFormat('dd MMMM yyyy', 'es_ES');
      return formatter.format(date);
    } catch (e) {
      print("Error al formatear fecha: $e");
      return fecha;
    }
  }
  
  String _formatearHora(String fecha) {
    try {
      final DateTime date = DateTime.parse(fecha);
      final DateFormat formatter = DateFormat('h:mm a', 'es_ES');
      return formatter.format(date);
    } catch (e) {
      print("Error al formatear hora: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getColorByPercentage();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header con color dinámico según porcentaje
          Container(
            decoration: BoxDecoration(
              color: statusColor,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // CONTROL+ y flecha de regreso
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
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
                            'CONTROL+',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  
                  // Información de la materia
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                    child: Column(
                      children: [
                        // Nombre de la materia
                        Text(
                          widget.materiaNombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Grupo y docente
                        Text(
                          'Grupo ${widget.grupo}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Docente: ${widget.docente ?? "Sin asignar"}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Porcentaje
                        Text(
                          'Tu porcentaje de asistencias',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.porcentaje}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Estadísticas detalladas
                        Text(
                          '${_estadisticas['presentes']} asistencias de ${_estadisticas['total']} clases',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Badge de estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido - Historial de inasistencias
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF003366),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    color: const Color(0xFF003366),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título del historial
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Historial de inasistencias',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF44336),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_estadisticas['faltas']} faltas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentDate(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Card con lista de inasistencias
                          if (_inasistencias.isEmpty)
                            _buildEmptyState()
                          else
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: _inasistencias.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final inasistencia = entry.value;
                                    final isLast = index == _inasistencias.length - 1;
                                    
                                    return Column(
                                      children: [
                                        _buildAsistenciaHistorialItem(
                                          _formatearFecha(inasistencia['fecha']),
                                          _formatearHora(inasistencia['fecha']),
                                        ),
                                        if (!isLast)
                                          Divider(color: Colors.grey[300], height: 30),
                                      ],
                                    );
                                  }).toList(),
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
  
  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 20),
              Text(
                '¡Excelente!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No tienes inasistencias registradas en esta materia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAsistenciaHistorialItem(String fecha, String hora) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF44336),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fecha,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hora,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.cancel,
          color: const Color(0xFFF44336),
          size: 24,
        ),
      ],
    );
  }
}