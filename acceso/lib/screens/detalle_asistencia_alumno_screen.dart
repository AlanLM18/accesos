import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';

class DetalleAsistenciaAlumnoScreen extends StatefulWidget {
  final String userId;
  final String alumnoNombre;
  final String materiaId;
  final String materiaNombre;
  final String grupo;

  const DetalleAsistenciaAlumnoScreen({
    Key? key,
    required this.userId,
    required this.alumnoNombre,
    required this.materiaId,
    required this.materiaNombre,
    required this.grupo,
  }) : super(key: key);

  @override
  State<DetalleAsistenciaAlumnoScreen> createState() =>
      _DetalleAsistenciaAlumnoScreenState();
}

class _DetalleAsistenciaAlumnoScreenState
    extends State<DetalleAsistenciaAlumnoScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _cargarAsistencias();
  }

  Future<void> _cargarAsistencias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todas las asistencias de la tabla
      final resultado = await _apiService.getAsistenciasTabla(widget.materiaId);
      
      final List<String> fechas = List<String>.from(resultado['fechas'] ?? []);
      final Map<String, Map<String, String>> asistencias =
          Map<String, Map<String, String>>.from(
        (resultado['asistencias'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            Map<String, String>.from(value as Map),
          ),
        ),
      );

      // Debug: Ver estructura de datos
      print("Fechas disponibles: $fechas");
      print("User ID buscado: ${widget.userId}");
      print("Asistencias keys: ${asistencias.keys.toList()}");

      // Filtrar solo las asistencias de este alumno
      List<Map<String, dynamic>> asistenciasAlumno = [];
      
      for (String fecha in fechas) {
        final estado = asistencias[widget.userId]?[fecha] ?? 'Sin registro';
        
        asistenciasAlumno.add({
          'fecha': fecha,
          'estado': estado,
        });
      }

      // Ordenar por fecha (más reciente primero)
      asistenciasAlumno.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['fecha']);
          final dateB = DateTime.parse(b['fecha']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _asistencias = asistenciasAlumno;
        _isLoading = false;
      });

      print("✓ ${_asistencias.length} registros de asistencia cargados");
    } catch (e) {
      print("✗ Error al cargar asistencias: $e");
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar asistencias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarEstadoAsistencia(String fecha, String nuevoEstado) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      print("Actualizando asistencia: fecha=$fecha, estado=$nuevoEstado");
      
      // Llamar al método del API para actualizar la asistencia
      await _apiService.updateAsistencia(
        widget.materiaId,
        widget.userId,
        fecha,
        nuevoEstado,
      );

      // Recargar las asistencias
      await _cargarAsistencias();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Asistencia actualizada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("✗ Error al actualizar asistencia: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _mostrarDialogoCambiarEstado(String fecha, String estadoActual) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Cambiar Estado de Asistencia',
            style: TextStyle(
              color: Color(0xFF004C8C),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha: ${_formatFechaCompleta(fecha)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estado actual: $estadoActual',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecciona el nuevo estado:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: estadoActual.toLowerCase() == 'presente'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cambiarEstadoAsistencia(fecha, 'presente');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Presente'),
            ),
            ElevatedButton(
              onPressed: estadoActual.toLowerCase() == 'falta'
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cambiarEstadoAsistencia(fecha, 'falta');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
              ),
              child: const Text('falta'),
            ),
          ],
        );
      },
    );
  }

  String _formatFechaCompleta(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('EEEE, dd/MM/yyyy', 'es').format(date);
    } catch (e) {
      return fecha;
    }
  }

  String _formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return fecha;
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return const Color(0xFF4CAF50);
      case 'falta':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check_circle;
      case 'falta':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  int _calcularEstadisticas(String tipo) {
    int count = 0;
    for (var asistencia in _asistencias) {
      if (asistencia['estado'].toString().toLowerCase() == tipo.toLowerCase()) {
        count++;
      }
    }
    return count;
  }

  double _calcularPorcentaje() {
    if (_asistencias.isEmpty) return 0;
    int presentes = _calcularEstadisticas('presente');
    return (presentes / _asistencias.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final totalPresentes = _calcularEstadisticas('presente');
    final totalFaltas = _calcularEstadisticas('falta');
    final porcentaje = _calcularPorcentaje();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF004C8C),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'CONTROL+',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE8E8E8),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF004C8C),
                      ),
                    )
                  : Column(
                      children: [
                        // Información del alumno
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                widget.alumnoNombre,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF004C8C),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.materiaNombre,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Grupo ${widget.grupo}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Estadísticas
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildEstadisticaCard(
                                  'Presente',
                                  totalPresentes.toString(),
                                  const Color(0xFF4CAF50),
                                  Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildEstadisticaCard(
                                  'Faltas',
                                  totalFaltas.toString(),
                                  const Color(0xFFEF5350),
                                  Icons.cancel,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildEstadisticaCard(
                                  'Asistencia',
                                  '${porcentaje.toStringAsFixed(1)}%',
                                  porcentaje >= 90
                                      ? const Color(0xFF4CAF50)
                                      : porcentaje >= 70
                                          ? const Color(0xFFFFA726)
                                          : const Color(0xFFEF5350),
                                  Icons.pie_chart,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lista de asistencias
                        Expanded(
                          child: _asistencias.isEmpty
                              ? _buildEmptyState()
                              : _buildAsistenciasList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(
      String titulo, String valor, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenciasList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Asistencias',
              style: TextStyle(
                color: Color(0xFF004C8C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                children: List.generate(
                  _asistencias.length,
                  (index) {
                    final asistencia = _asistencias[index];
                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        _buildAsistenciaItem(asistencia),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciaItem(Map<String, dynamic> asistencia) {
    final fecha = asistencia['fecha'] as String;
    final estado = asistencia['estado'] as String;
    final color = _getColorEstado(estado);
    final icono = _getIconoEstado(estado);

    return InkWell(
      onTap: _isUpdating
          ? null
          : () => _mostrarDialogoCambiarEstado(fecha, estado),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Ícono y estado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            // Fecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatFecha(fecha),
                    style: const TextStyle(
                      color: Color(0xFF004C8C),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estado,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Icono de editar
            Icon(
              Icons.edit,
              color: Colors.grey[400],
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
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros de asistencia',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}