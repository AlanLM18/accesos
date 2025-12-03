import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../service/session_wrapper.dart';
import 'materias.dart'; 

class TutorScreen extends StatefulWidget {
  final String userId;
  final String? nombre;

  const TutorScreen({
    Key? key,
    required this.userId,
    this.nombre,
  }) : super(key: key);

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _grupos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGrupos();
  }

  Future<void> _loadGrupos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final grupos = await _apiService.getGruposByTutor(widget.userId);
      
      if (mounted) {
        setState(() {
          _grupos = grupos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar grupos: $e';
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
          title: const Text(
            'Grupos Tutorados',
            style: TextStyle(
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
            // Header con información del tutor
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
                    Icons.school,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.nombre ?? 'Tutor',
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
                      '${_grupos.length} ${_grupos.length == 1 ? 'Grupo' : 'Grupos'}',
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

            // Lista de grupos
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
                                onPressed: _loadGrupos,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004C8C),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _grupos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.groups_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes grupos asignados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadGrupos,
                              color: const Color(0xFF004C8C),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _grupos.length,
                                itemBuilder: (context, index) {
                                  final grupo = _grupos[index];
                                  return _buildGrupoCard(grupo);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF004C8C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.groups,
            color: Color(0xFF004C8C),
            size: 28,
          ),
        ),
        title: Text(
          'Grupo ${grupo['grupo'] ?? 'Sin nombre'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004C8C),
          ),
        ),
        subtitle: Text(
          'Toca para ver materias',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF004C8C),
          size: 20,
        ),
        onTap: () {
          // Navegar a la pantalla de materias
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MateriasScreen(
                grupo: grupo['grupo'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}