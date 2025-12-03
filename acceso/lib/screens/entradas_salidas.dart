import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';

class EntradasSalidasScreen extends StatefulWidget {
  const EntradasSalidasScreen({Key? key}) : super(key: key);

  @override
  State<EntradasSalidasScreen> createState() => _EntradasSalidasScreenState();
}

class _EntradasSalidasScreenState extends State<EntradasSalidasScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> accessList = [];
  List<Map<String, dynamic>> filteredAccessList = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _loadAccessData();
  }

  Future<void> _loadAccessData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedAccess = await _apiService.getAllAccess();
      
      print("Registros cargados: ${loadedAccess.length}");
      
      setState(() {
        accessList = loadedAccess;
        _applyFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error de conexión: $e";
        isLoading = false;
      });
      print("Excepción en _loadAccessData: $e");
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'todos') {
      filteredAccessList = accessList;
    } else {
      filteredAccessList = accessList
          .where((access) => access['tipo']?.toString().toLowerCase() == selectedFilter)
          .toList();
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilter();
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'CONTROL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '+',
              style: TextStyle(
                color: Color(0xFFFFA500),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAccessData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF003366),
                  Color(0xFF004080),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 50,
                  color: Color(0xFFFFA500),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ENTRADAS Y SALIDAS',
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${filteredAccessList.length} registros',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF003366),
                    ),
                  )
                : errorMessage != null
                    ? _buildErrorState()
                    : filteredAccessList.isEmpty
                        ? _buildEmptyState()
                        : _buildAccessList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('Todos', 'todos'),
        const SizedBox(width: 8),
        _buildFilterChip('Entradas', 'entrada'),
        const SizedBox(width: 8),
        _buildFilterChip('Salidas', 'salida'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _changeFilter(value),
      backgroundColor: const Color.fromARGB(255, 41, 13, 183).withOpacity(0.5 ),
      selectedColor: const Color(0xFFFFA500),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAccessData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
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
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            selectedFilter == 'todos'
                ? 'No hay registros de acceso'
                : 'No hay ${selectedFilter}s registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessList() {
    return RefreshIndicator(
      onRefresh: _loadAccessData,
      color: const Color(0xFF003366),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAccessList.length,
        itemBuilder: (context, index) {
          final access = filteredAccessList[index];
          return _buildAccessCard(access);
        },
      ),
    );
  }

  Widget _buildAccessCard(Map<String, dynamic> access) {
    final tipo = access['tipo']?.toString().toLowerCase() ?? 'desconocido';
    final isEntrada = tipo == 'entrada';
    
    final color = isEntrada ? Colors.green : Colors.orange;
    final icon = isEntrada ? Icons.login : Icons.logout;
    final tipoText = isEntrada ? 'ENTRADA' : 'SALIDA';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAccessDetails(access),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de tipo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del usuario
                      Text(
                        access['user_nombre'] ?? 'Usuario desconocido',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Zona
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              access['zone_name'] ?? 'Zona desconocida',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Matrícula
                      if (access['user_matricula'] != 'N/A')
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              access['user_matricula'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      
                      // Fecha y hora
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(access['fecha']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Badge de tipo
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tipoText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccessDetails(Map<String, dynamic> access) {
    final tipo = access['tipo']?.toString().toLowerCase() ?? 'desconocido';
    final isEntrada = tipo == 'entrada';
    final color = isEntrada ? Colors.green : Colors.orange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEntrada ? Icons.login : Icons.logout,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Acceso',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        isEntrada ? 'Entrada' : 'Salida',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Usuario', access['user_nombre'] ?? 'N/A'),
            _buildDetailRow('Correo', access['user_correo'] ?? 'N/A'),
            _buildDetailRow('Matrícula', access['user_matricula'] ?? 'N/A'),
            _buildDetailRow('Zona', access['zone_name'] ?? 'N/A'),
            _buildDetailRow('Fecha y hora', _formatDate(access['fecha'])),
            _buildDetailRow('Tipo', access['tipo'] ?? 'N/A'),
            if (access['qr_id'] != null)
              _buildDetailRow('QR ID', access['qr_id']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF003366),
              ),
            ),
          ),
        ],
      ),
    );
  }
}