import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';
import 'detalle_asistencia_alumno_screen.dart';

class AlumnosMateriaScreen extends StatefulWidget {
  final String materiaId;
  final String materiaNombre;
  final String grupo;

  const AlumnosMateriaScreen({
    Key? key,
    required this.materiaId,
    required this.materiaNombre,
    required this.grupo,
  }) : super(key: key);

  @override
  State<AlumnosMateriaScreen> createState() => _AlumnosMateriaScreenState();
}

class _AlumnosMateriaScreenState extends State<AlumnosMateriaScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _alumnos = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alumnos = await _apiService.getAlumnosConAsistenciaByGrupoYMateria(
        widget.grupo,
        widget.materiaId,
      );
      
      setState(() {
        _alumnos = alumnos;
        _isLoading = false;
      });
      
      print("✓ ${_alumnos.length} alumnos cargados con asistencias");
    } catch (e) {
      print("✗ Error al cargar alumnos: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarAExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      print("=== EXPORTANDO TABLA DE ASISTENCIAS A EXCEL ===");
      
      // Obtener los datos completos de asistencias
      final resultado = await _apiService.getAsistenciasTabla(widget.materiaId);
      
      final List<Map<String, dynamic>> alumnos = List<Map<String, dynamic>>.from(resultado['alumnos'] ?? []);
      final List<String> fechas = List<String>.from(resultado['fechas'] ?? []);
      final Map<String, Map<String, String>> asistencias = Map<String, Map<String, String>>.from(
        (resultado['asistencias'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            Map<String, String>.from(value as Map),
          ),
        ),
      );

      if (alumnos.isEmpty) {
        throw Exception('No hay datos de asistencia para exportar');
      }

      print("✓ Datos obtenidos: ${alumnos.length} alumnos, ${fechas.length} fechas");
      
      // Crear un nuevo libro de Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Estilos
      var headerStyle = CellStyle(
        backgroundColorHex: "#004C8C",
        fontColorHex: "#FFFFFF",
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      var titleStyle = CellStyle(
        backgroundColorHex: "#4A9FD8",
        fontColorHex: "#FFFFFF",
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      var presenteStyle = CellStyle(
        backgroundColorHex: "#4CAF50",
        fontColorHex: "#FFFFFF",
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      var faltaStyle = CellStyle(
        backgroundColorHex: "#F44336",
        fontColorHex: "#FFFFFF",
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      var sinRegistroStyle = CellStyle(
        backgroundColorHex: "#BDBDBD",
        fontColorHex: "#FFFFFF",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      var retardoStyle = CellStyle(
      backgroundColorHex: "#FFC107", // Amarillo para retardo
      fontColorHex: "#000000", // Texto negro para mejor contraste
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      );

      var boldStyle = CellStyle(bold: true);
      var italicStyle = CellStyle(italic: true);

      // Título principal
      var cellTitulo = sheetObject.cell(CellIndex.indexByString("A1"));
      cellTitulo.value = 'REGISTRO DE ASISTENCIAS';
      cellTitulo.cellStyle = titleStyle;
      
      // Merge para el título
      int totalColumnas = fechas.length + 5; // Alumno, Matrícula, Fechas, Total Presente, Total Faltas, % Asistencia
      sheetObject.merge(
        CellIndex.indexByString("A1"),
        CellIndex.indexByColumnRow(columnIndex: totalColumnas - 1, rowIndex: 0),
      );

      // Información de la materia
      var cellMateria = sheetObject.cell(CellIndex.indexByString("A2"));
      cellMateria.value = 'Materia: ${widget.materiaNombre}';
      cellMateria.cellStyle = boldStyle;

      var cellGrupo = sheetObject.cell(CellIndex.indexByString("A3"));
      cellGrupo.value = 'Grupo: ${widget.grupo}';
      cellGrupo.cellStyle = boldStyle;

      var cellFecha = sheetObject.cell(CellIndex.indexByString("A4"));
      cellFecha.value = 'Fecha de exportación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
      cellFecha.cellStyle = italicStyle;

      // Fila vacía en 5
      int currentRow = 6;

      // Headers de la tabla
      var cellAlumno = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cellAlumno.value = 'Alumno';
      cellAlumno.cellStyle = headerStyle;

      var cellMatricula = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      cellMatricula.value = 'Matrícula';
      cellMatricula.cellStyle = headerStyle;

      // Headers de fechas
      for (int i = 0; i < fechas.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: currentRow));
        cell.value = _formatFecha(fechas[i]);
        cell.cellStyle = headerStyle;
      }

      // Agregar columnas de resumen
      var cellTotalPresente = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 2, rowIndex: currentRow));
      cellTotalPresente.value = 'Total Presente';
      cellTotalPresente.cellStyle = headerStyle;

      var cellTotalFaltas = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 3, rowIndex: currentRow));
      cellTotalFaltas.value = 'Total Faltas';
      cellTotalFaltas.cellStyle = headerStyle;

      var cellPorcentaje = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 4, rowIndex: currentRow));
      cellPorcentaje.value = '% Asistencia';
      cellPorcentaje.cellStyle = headerStyle;

      currentRow++;

      // Datos de alumnos
      for (var alumno in alumnos) {
        final userId = alumno['user_id'] as String;
        
        // Nombre
        var cellNombre = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        cellNombre.value = alumno['nombre'] ?? '';

        // Matrícula
        var cellMatriculaData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        cellMatriculaData.value = alumno['matricula'] ?? '';

        int totalPresente = 0;
        int totalFaltas = 0;
        int totalRetardos = 0;

        // Asistencias por fecha
        for (int i = 0; i < fechas.length; i++) {
          final fecha = fechas[i];
          final estado = asistencias[userId]?[fecha] ?? 'Sin registro';
          
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: currentRow));
          
          if (estado.toLowerCase() == 'presente') {
            cell.value = 'P';
            cell.cellStyle = presenteStyle;
            totalPresente++;
          } else if (estado.toLowerCase() == 'falta') {
            cell.value = 'F';
            cell.cellStyle = faltaStyle;
            totalFaltas++;
          } else if (estado.toLowerCase() == 'retardo') {
            cell.value = 'R';
            cell.cellStyle = retardoStyle;
            totalRetardos++;
          }else {
            cell.value = '-';
            cell.cellStyle = sinRegistroStyle;
          }
        }

        // Total Presente
        var cellTotalPresenteData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 2, rowIndex: currentRow));
        cellTotalPresenteData.value = totalPresente;
        cellTotalPresenteData.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

        // Total Faltas
        var cellTotalFaltasData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 3, rowIndex: currentRow));
        cellTotalFaltasData.value = totalFaltas;
        cellTotalFaltasData.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

        // Porcentaje
        double porcentaje = fechas.isEmpty ? 0 : (totalPresente / fechas.length) * 100;
        var cellPorcentajeData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: fechas.length + 4, rowIndex: currentRow));
        cellPorcentajeData.value = '${porcentaje.toStringAsFixed(1)}%';
        cellPorcentajeData.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: porcentaje >= 90 
              ? "#4CAF50"
              : porcentaje >= 80
                  ? "#FFA726"
                  : "#F44336",
          fontColorHex: "#FFFFFF",
        );

        currentRow++;
      }

      // Ajustar ancho de columnas
      sheetObject.setColWidth(0, 25); // Alumno
      sheetObject.setColWidth(1, 15); // Matrícula
      for (int i = 0; i < fechas.length; i++) {
        sheetObject.setColWidth(i + 2, 12); // Fechas
      }
      sheetObject.setColWidth(fechas.length + 2, 15); // Total Presente
      sheetObject.setColWidth(fechas.length + 3, 15); // Total Faltas
      sheetObject.setColWidth(fechas.length + 4, 15); // % Asistencia

      print("✓ Excel creado exitosamente");

      // Codificar el archivo
      var fileBytes = excel.encode();
      
      if (fileBytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      // Obtener directorio temporal
      final directory = await getTemporaryDirectory();
      final fileName = 'Asistencias_${widget.materiaNombre.replaceAll(' ', '_')}_Grupo_${widget.grupo}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      print("✓ Guardando archivo en: $filePath");
      
      // Escribir archivo
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      print("✓ Archivo guardado exitosamente");

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // Compartir el archivo
        print("✓ Compartiendo archivo...");
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Asistencias - ${widget.materiaNombre} - Grupo ${widget.grupo}',
          text: 'Registro de asistencias exportado desde CONTROL+',
        );

        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Excel exportado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel creado. Puedes encontrarlo en tus archivos.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("✗ Error al exportar: $e");
      print("Stack trace: $stackTrace");
      
      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM').format(date);
    } catch (e) {
      return fecha;
    }
  }

  Color _getColorPorcentaje(int porcentaje) {
    if (porcentaje >= 90) {
      return const Color(0xFF4CAF50); // Verde
    } else if (porcentaje >= 80) {
      return const Color(0xFFFFA726); // Naranja
    } else {
      return const Color(0xFFEF5350); // Rojo
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // Botón de exportar en el header
                    if (!_isLoading && _alumnos.isNotEmpty)
                      IconButton(
                        onPressed: _isExporting ? null : _exportarAExcel,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.file_download,
                                color: Colors.white,
                                size: 28,
                              ),
                        tooltip: 'Exportar tabla de asistencias',
                      ),
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
              child: Column(
                children: [
                  // Título
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.materiaNombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF004C8C),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Listado de Alumnos del',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'grupo ${widget.grupo}',
                          style: const TextStyle(
                            color: Color(0xFF004C8C),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Botón de exportar alternativo
                        if (!_isLoading && _alumnos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportarAExcel,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.table_chart),
                              label: Text(_isExporting ? 'Exportando...' : 'Exportar Tabla de Asistencias'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A9FD8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Lista de alumnos
                  _isLoading
                      ? const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF004C8C),
                            ),
                          ),
                        )
                      : _alumnos.isEmpty
                          ? Expanded(child: _buildEmptyState())
                          : Expanded(child: _buildAlumnosList()),
                  
                  // Espacio inferior
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumnosList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              _alumnos.length,
              (index) {
                final alumno = _alumnos[index];
                return Column(
                  children: [
                    if (index > 0)
                      const Divider(
                        height: 32,
                        color: Color(0xFFE0E0E0),
                        thickness: 1,
                      ),
                    _buildAlumnoItem(alumno),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

// Cambia el método _buildAlumnoItem en tu AlumnosMateriaScreen:

Widget _buildAlumnoItem(Map<String, dynamic> alumno) {
  final porcentaje = alumno['porcentaje'] as int;
  final color = _getColorPorcentaje(porcentaje);

  return InkWell(
    onTap: () {
      // Debug: ver estructura completa del alumno
      print("=== DEBUG ALUMNO ===");
      print("Alumno completo: $alumno");
      print("Keys disponibles: ${alumno.keys.toList()}");
      
      // Obtener el user_id correctamente
      final userId = alumno['id'] as String?;  // En tu estructura, el ID está en 'id', no 'user_id'
      
      if (userId == null) {
        print("✗ ERROR: No se encontró el ID del alumno");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró el ID del alumno'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print("✓ Usuario ID encontrado: $userId");
      print("✓ Navegando a detalle de asistencia...");
      
      // Navegar a la pantalla de detalle
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleAsistenciaAlumnoScreen(
            userId: userId,
            alumnoNombre: (alumno['nombre'] ?? 'Alumno').toString(),
            materiaId: widget.materiaId,
            materiaNombre: widget.materiaNombre,
            grupo: widget.grupo,
          ),
        ),
      ).then((_) {
        // Recargar los datos cuando regrese de la pantalla de detalle
        print("✓ Regresando de detalle, recargando datos...");
        _cargarAlumnos();
      });
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Nombre del alumno
          Expanded(
            child: Text(
              alumno['nombre'],
              style: const TextStyle(
                color: Color(0xFF004C8C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Porcentaje
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$porcentaje%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icono de flecha
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay alumnos en este grupo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El grupo ${widget.grupo} no tiene alumnos asignados',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}