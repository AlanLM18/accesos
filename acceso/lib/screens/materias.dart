import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../service/session_wrapper.dart';
import 'asistencias_materias_screen.dart';

class MateriasScreen extends StatefulWidget {
  final String grupo;

  const MateriasScreen({
    Key? key,
    required this.grupo,
  }) : super(key: key);

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _materias = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaterias();
  }

  Future<void> _loadMaterias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar el método con información del profesor
      final materias = await _apiService.getMateriasByGrupoConProfesor(widget.grupo);
      
      if (mounted) {
        setState(() {
          _materias = materias;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar materias: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        appBar: AppBar(
          title: Text(
            'Materias - Grupo ${widget.grupo}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF004C8C),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // Header con información del grupo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Grupo ${widget.grupo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_materias.length} ${_materias.length == 1 ? 'Materia' : 'Materias'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de materias
            Expanded(
              child: _isLoading
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
                                onPressed: _loadMaterias,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004C8C),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _materias.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay materias registradas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'para este grupo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMaterias,
                              color: const Color(0xFF004C8C),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _materias.length,
                                itemBuilder: (context, index) {
                                  final materia = _materias[index];
                                  return _buildMateriaCard(materia);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildMateriaCard(Map<String, dynamic> materia) {
  return GestureDetector(
    onTap: () {
      // Navegar a la pantalla de asistencias
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AsistenciasMateriasScreen(
            claseId: materia['id'],
            nombreMateria: materia['nombre'] ?? 'Materia',
            grupo: widget.grupo,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004C8C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Color(0xFF004C8C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004C8C),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF004C8C),
                  size: 18,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFF4A9FD8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    materia['profesor_nombre'] ?? 'Sin profesor',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A9FD8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}