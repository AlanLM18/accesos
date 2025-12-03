import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'alumnos_materia.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GruposScreen extends StatefulWidget {
  final String materiaId; 
  final String materiaNombre;

  const GruposScreen({
    Key? key,
    required this.materiaId,
    required this.materiaNombre,
  }) : super(key: key);

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _gruposConClases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("=== INICIALIZANDO GRUPOS SCREEN ===");
    print("Materia ID recibido: ${widget.materiaId}");
    print("Materia Nombre: ${widget.materiaNombre}");
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("\n=== CARGANDO GRUPOS DE LA MATERIA ===");
      
      // Obtener grupos únicos de la tabla classes
      final grupos = await _apiService.getGruposByMateria(widget.materiaId);
      
      print("✓ ${grupos.length} grupos únicos encontrados");
      
      // Para cada grupo, necesitamos obtener el ID de la clase (classes.id)
      List<Map<String, dynamic>> gruposConClases = [];
      
      for (var grupo in grupos) {
        final grupoNombre = grupo['grupo'];
        
        print("\nProcesando grupo: $grupoNombre");
        
        // Obtener el ID de la clase para este grupo y materia
        final claseId = await _obtenerClaseId(widget.materiaId, grupoNombre);
        
        if (claseId != null) {
          gruposConClases.add({
            'grupo': grupoNombre,
            'clase_id': claseId, // ID de la tabla classes
          });
          print("  → Clase ID obtenido: $claseId");
        } else {
          print("  ⚠ No se encontró clase para este grupo");
        }
      }
      
      setState(() {
        _gruposConClases = gruposConClases;
        _isLoading = false;
      });
      
      print("\n✓ ${_gruposConClases.length} grupos cargados con sus IDs de clase");
    } catch (e) {
      print("✗ Error al cargar grupos: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método auxiliar para obtener el ID de la clase
  Future<String?> _obtenerClaseId(String materiaId, String grupo) async {
    try {
      final url = '${ApiService.baseUrl}/classes?materia=eq.$materiaId&grupo=eq.$grupo&select=id&limit=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0]['id'] as String;
        }
      }
      return null;
    } catch (e) {
      print("Error al obtener clase ID: $e");
      return null;
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
                  // Título de la materia
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
                          'Listado de Grupos',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Título "Grupos"
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Grupos',
                        style: TextStyle(
                          color: Color(0xFF004C8C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de grupos
                  _isLoading
                      ? const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF004C8C),
                            ),
                          ),
                        )
                      : _gruposConClases.isEmpty
                          ? Expanded(child: _buildEmptyState())
                          : _buildGruposList(),
                  
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

  Widget _buildGruposList() {
    return Padding(
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
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _gruposConClases.length,
            (index) {
              final grupo = _gruposConClases[index];
              return Column(
                children: [
                  if (index > 0)
                    const Divider(
                      height: 1,
                      color: Color(0xFFE0E0E0),
                    ),
                  _buildGrupoItem(grupo),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrupoItem(Map<String, dynamic> grupo) {
    return InkWell(
      onTap: () {
        print("\n=== NAVEGANDO A ALUMNOS ===");
        print("Grupo: ${grupo['grupo']}");
        print("Clase ID (tabla classes): ${grupo['clase_id']}");
        print("Materia Nombre: ${widget.materiaNombre}");
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlumnosMateriaScreen(
              materiaId: grupo['clase_id'], // ✅ Ahora pasamos el ID correcto de la tabla classes
              materiaNombre: widget.materiaNombre,
              grupo: grupo['grupo'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          grupo['grupo'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF004C8C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
            Icons.group_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay grupos asignados',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta materia no tiene grupos',
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