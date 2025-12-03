import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../service/api_service.dart';
import '../service/session_wrapper.dart';
import 'prediccion_alumno_screen.dart';

class AsistenciasMateriasScreen extends StatefulWidget {
  final String claseId;
  final String nombreMateria;
  final String grupo;

  const AsistenciasMateriasScreen({
    Key? key,
    required this.claseId,
    required this.nombreMateria,
    required this.grupo,
  }) : super(key: key);

  @override
  State<AsistenciasMateriasScreen> createState() => _AsistenciasMateriasScreenState();
}

class _AsistenciasMateriasScreenState extends State<AsistenciasMateriasScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _alumnos = [];
  List<String> _fechas = [];
  Map<String, Map<String, String>> _asistencias = {};
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resultado = await _apiService.getAsistenciasTabla(widget.claseId);
      
      if (mounted) {
        setState(() {
          _alumnos = List<Map<String, dynamic>>.from(resultado['alumnos'] ?? []);
          _fechas = List<String>.from(resultado['fechas'] ?? []);
          _asistencias = Map<String, Map<String, String>>.from(
            (resultado['asistencias'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                Map<String, String>.from(value as Map),
              ),
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar asistencias: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Navegar a la pantalla de predicción
  void _navegarAPrediccion(Map<String, dynamic> alumno) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrediccionAlumnoScreen(
          alumnoId: alumno['user_id'] as String,
          nombreAlumno: alumno['nombre'] ?? 'Sin nombre',
          matricula: alumno['matricula'] ?? '',
          claseId: widget.claseId,
        ),
      ),
    );
  }

  Future<void> _exportarAExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

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

      var cellTitulo = sheetObject.cell(CellIndex.indexByString("A1"));
      cellTitulo.value = 'REGISTRO DE ASISTENCIAS';
      cellTitulo.cellStyle = titleStyle;
      
      int totalColumnas = _fechas.length + 5;
      sheetObject.merge(
        CellIndex.indexByString("A1"),
        CellIndex.indexByColumnRow(columnIndex: totalColumnas - 1, rowIndex: 0),
      );

      var cellMateria = sheetObject.cell(CellIndex.indexByString("A2"));
      cellMateria.value = 'Materia: ${widget.nombreMateria}';
      cellMateria.cellStyle = boldStyle;

      var cellGrupo = sheetObject.cell(CellIndex.indexByString("A3"));
      cellGrupo.value = 'Grupo: ${widget.grupo}';
      cellGrupo.cellStyle = boldStyle;

      var cellFecha = sheetObject.cell(CellIndex.indexByString("A4"));
      cellFecha.value = 'Fecha de exportación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
      cellFecha.cellStyle = italicStyle;

      int currentRow = 6;

      var cellAlumno = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cellAlumno.value = 'Alumno';
      cellAlumno.cellStyle = headerStyle;

      var cellMatricula = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      cellMatricula.value = 'Matrícula';
      cellMatricula.cellStyle = headerStyle;

      for (int i = 0; i < _fechas.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: currentRow));
        cell.value = _formatFecha(_fechas[i]);
        cell.cellStyle = headerStyle;
      }

      var cellTotalPresente = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 2, rowIndex: currentRow));
      cellTotalPresente.value = 'Total Presente';
      cellTotalPresente.cellStyle = headerStyle;

      var cellTotalFaltas = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 3, rowIndex: currentRow));
      cellTotalFaltas.value = 'Total Faltas';
      cellTotalFaltas.cellStyle = headerStyle;

      var cellPorcentaje = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 4, rowIndex: currentRow));
      cellPorcentaje.value = '% Asistencia';
      cellPorcentaje.cellStyle = headerStyle;

      currentRow++;

      for (var alumno in _alumnos) {
        final userId = alumno['user_id'] as String;
        
        var cellNombre = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        cellNombre.value = alumno['nombre'] ?? '';

        var cellMatriculaData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        cellMatriculaData.value = alumno['matricula'] ?? '';

        int totalPresente = 0;
        int totalFaltas = 0;
        int totalRetardos = 0;

        for (int i = 0; i < _fechas.length; i++) {
          final fecha = _fechas[i];
          final estado = _asistencias[userId]?[fecha] ?? 'Sin registro';
          
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

        var cellTotalPresenteData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 2, rowIndex: currentRow));
        cellTotalPresenteData.value = totalPresente;
        cellTotalPresenteData.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

        var cellTotalFaltasData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 3, rowIndex: currentRow));
        cellTotalFaltasData.value = totalFaltas;
        cellTotalFaltasData.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

        double porcentaje = _fechas.isEmpty ? 0 : (totalPresente / _fechas.length) * 100;
        var cellPorcentajeData = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: _fechas.length + 4, rowIndex: currentRow));
        cellPorcentajeData.value = '${porcentaje.toStringAsFixed(1)}%';
        cellPorcentajeData.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: porcentaje >= 90 
              ? "#4CAF50"
              : porcentaje >= 70
                  ? "#FFA726"
                  : "#F44336",
          fontColorHex: "#FFFFFF",
        );

        currentRow++;
      }

      sheetObject.setColWidth(0, 25);
      sheetObject.setColWidth(1, 15);
      for (int i = 0; i < _fechas.length; i++) {
        sheetObject.setColWidth(i + 2, 12);
      }
      sheetObject.setColWidth(_fechas.length + 2, 15);
      sheetObject.setColWidth(_fechas.length + 3, 15);
      sheetObject.setColWidth(_fechas.length + 4, 15);

      var fileBytes = excel.encode();
      
      if (fileBytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      final directory = await getTemporaryDirectory();
      final fileName = 'Asistencias_${widget.nombreMateria.replaceAll(' ', '_')}_Grupo_${widget.grupo}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Asistencias - ${widget.nombreMateria} - Grupo ${widget.grupo}',
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
        }
      }
    } catch (e) {
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

  Color _getEstadoColor(String estado) {
  switch (estado.toLowerCase()) {
    case 'presente':
      return Colors.green;
    case 'falta':
      return Colors.red;
    case 'retardo':
      return Colors.amber; 
    case 'justificada':
      return Colors.orange;
    default:
      return Colors.grey[400]!;
  }
}

  @override
  Widget build(BuildContext context) {
    return SessionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nombreMateria,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                'Grupo ${widget.grupo}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF004C8C),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
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
                    : const Icon(Icons.file_download),
                tooltip: 'Exportar a Excel',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF004C8C),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAsistencias,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004C8C),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _alumnos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay registros de asistencia',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Header con resumen
                          Container(
                            padding: const EdgeInsets.all(16),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  'Alumnos',
                                  _alumnos.length.toString(),
                                  Icons.people,
                                ),
                                _buildStatCard(
                                  'Fechas',
                                  _fechas.length.toString(),
                                  Icons.calendar_today,
                                ),
                                _buildExportButton(),
                              ],
                            ),
                          ),
                          
                          // Leyenda
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLeyendaItem('Presente', Colors.green),
                                const SizedBox(width: 16),
                                _buildLeyendaItem('Falta', Colors.red),
                                const SizedBox(width: 16),
                                _buildLeyendaItem('Retardo', Colors.amber),
                              ],
                            ),
                          ),

                          // Tabla de asistencias
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadAsistencias,
                              color: const Color(0xFF004C8C),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        const Color(0xFF004C8C).withOpacity(0.1),
                                      ),
                                      columnSpacing: 20,
                                      horizontalMargin: 12,
                                      columns: [
                                        const DataColumn(
                                          label: Text(
                                            'Alumno',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF004C8C),
                                            ),
                                          ),
                                        ),
                                        ..._fechas.map(
                                          (fecha) => DataColumn(
                                            label: Text(
                                              _formatFecha(fecha),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004C8C),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: _alumnos.map((alumno) {
                                        final userId = alumno['user_id'] as String;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              GestureDetector(
                                                onTap: () => _navegarAPrediccion(alumno),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      alumno['nombre'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                        color: Color(0xFF1976D2), // Azul link
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: Color(0xFF1976D2),
                                                      ),
                                                    ),
                                                    Text(
                                                      alumno['matricula'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Celdas de asistencia
                                            ..._fechas.map((fecha) {
                                              final estado = _asistencias[userId]?[fecha] ?? 'Sin registro';
                                              return DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getEstadoColor(estado),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    estado.toLowerCase() == 'presente' ? '-' : 
                                                    estado.toLowerCase() == 'falta' ? '-' : '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        );
                                      }).toList(),
                                    ),
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: _isExporting ? null : _exportarAExcel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (_isExporting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.table_chart, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              _isExporting ? 'Exportando...' : 'Exportar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyendaItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}