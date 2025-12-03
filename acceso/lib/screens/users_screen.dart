import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedUsers = await _apiService.getAllUsers();
      
      print("=== RESULTADO CARGA ===");
      print("Usuarios cargados: ${loadedUsers.length}");
      
      for (var user in loadedUsers) {
        print("Usuario recibido: ${user.keys.toList()}");
        print("Valores: $user");
      }
      
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error de conexión: $e";
        isLoading = false;
      });
      print("Excepción en _loadUsers: $e");
    }
  }

  String _getSafeValue(Map<String, dynamic> user, String key) {
    return user[key]?.toString() ?? 'N/A';
  }

  // Validación de correo institucional
  String? _validateInstitutionalEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el correo';
    }
    if (!value.contains('@')) {
      return 'Ingresa un correo válido';
    }
    if (!value.toLowerCase().endsWith('@uteq.edu.mx')) {
      return 'Debe ser un correo institucional @uteq.edu.mx';
    }
    return null;
  }

  // Validación de contraseña segura
  String? _validatePassword(String? value, {bool isOptional = false}) {
    if (value == null || value.isEmpty) {
      if (isOptional) return null;
      return 'Por favor ingresa la contraseña';
    }
    
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    
    // Verificar que tenga al menos una letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra';
    }
    
    // Verificar que tenga al menos un número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    
    // Verificar que tenga al menos un carácter especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;`~]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial (!@#\$%^&*(),.?":{}|<>_-+=[]\\;`~)';
    }
    
    return null;
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
            onPressed: _loadUsers,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 50,
                        color: Color(0xFFFFA500),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'USUARIOS REGISTRADOS',
                        style: TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${users.length} usuarios encontrados',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _showAddUserDialog,
                    tooltip: 'Agregar Usuario',
                  ),
                ),
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
                    : users.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersList(),
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
              onPressed: _loadUsers,
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
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFF003366),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String nombre = _getSafeValue(user, 'nombre');
    final String correo = _getSafeValue(user, 'correo');
    final String role = _getSafeValue(user, 'rol');
    final String matricula = _getSafeValue(user, 'matricula');
    
    Color roleColor;
    IconData roleIcon;
    
    switch (role.toLowerCase()) {
      case 'admin':
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'profesor':
        roleColor = Colors.blue;
        roleIcon = Icons.school;
        break;
      case 'tutor':
        roleColor = Colors.orange;
        roleIcon = Icons.support_agent;
        break;
      case 'alumno':
      default:
        roleColor = Colors.green;
        roleIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showUserDetails(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        correo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (matricula != 'N/A') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Matrícula: $matricula',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 14, color: roleColor),
                            const SizedBox(width: 4),
                            Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF003366)),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditUserDialog(user);
                        break;
                      case 'delete':
                        _confirmDeleteUser(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF003366)),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
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

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    final matriculaController = TextEditingController();
    final grupoController = TextEditingController();
    String selectedRole = 'alumno';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: Color(0xFF003366)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Agregar Usuario',
                style: TextStyle(
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'ejemplo@uteq.edu.mx',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: _validateInstitutionalEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Mín. 8 caracteres, letras, números y símbolos',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF003366)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Color(0xFF003366),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: (value) => _validatePassword(value, isOptional: false),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      labelText: 'Matrícula (opcional)',
                      prefixIcon: const Icon(Icons.badge, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: const Icon(Icons.work, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                      DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                      DropdownMenuItem(value: 'tutor', child: Text('Tutor')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  // Campo de Grupo solo para alumnos
                  if (selectedRole.toLowerCase() == 'alumno') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: grupoController,
                      decoration: InputDecoration(
                        labelText: 'Grupo',
                        prefixIcon: const Icon(Icons.group, color: Color(0xFF003366)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (selectedRole.toLowerCase() == 'alumno' && (value == null || value.isEmpty)) {
                          return 'El grupo es obligatorio para alumnos';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _createUser(
                    nombre: nombreController.text.trim(),
                    correo: correoController.text.trim(),
                    password: passwordController.text,
                    rol: selectedRole,
                    matricula: matriculaController.text.trim(),
                    grupo: selectedRole.toLowerCase() == 'alumno' ? grupoController.text.trim() : null,
                    activo: 1,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
              ),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: user['nombre']);
    final correoController = TextEditingController(text: user['correo']);
    final passwordController = TextEditingController();
    final matriculaController = TextEditingController(text: user['matricula'] ?? '');
    final grupoController = TextEditingController(text: user['grupo'] ?? '');
    String selectedRole = user['rol']?.toString().toLowerCase() ?? 'alumno';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF003366)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Editar Usuario',
                style: TextStyle(
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'ejemplo@uteq.edu.mx',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: _validateInstitutionalEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña (opcional)',
                      hintText: 'Dejar vacío para no cambiar',
                      helperText: 'Mín. 8 caracteres, letras, números y símbolos',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF003366)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Color(0xFF003366),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    validator: (value) => _validatePassword(value, isOptional: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      labelText: 'Matrícula',
                      prefixIcon: const Icon(Icons.badge, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: const Icon(Icons.work, color: Color(0xFF003366)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                      DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                      DropdownMenuItem(value: 'tutor', child: Text('Tutor')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  // Campo de Grupo solo para alumnos
                  if (selectedRole.toLowerCase() == 'alumno') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: grupoController,
                      decoration: InputDecoration(
                        labelText: 'Grupo',
                        prefixIcon: const Icon(Icons.group, color: Color(0xFF003366)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (selectedRole.toLowerCase() == 'alumno' && (value == null || value.isEmpty)) {
                          return 'El grupo es obligatorio para alumnos';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _updateUser(
                    userId: user['id'].toString(),
                    nombre: nombreController.text.trim(),
                    correo: correoController.text.trim(),
                    password: passwordController.text.isNotEmpty 
                        ? passwordController.text 
                        : null,
                    rol: selectedRole,
                    matricula: matriculaController.text.trim(),
                    grupo: selectedRole.toLowerCase() == 'alumno' ? grupoController.text.trim() : null,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
              ),
              child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
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
            const Text(
              'Detalles del Usuario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('ID', _getSafeValue(user, 'id')),
            _buildDetailRow('Nombre', _getSafeValue(user, 'nombre')),
            _buildDetailRow('Correo', _getSafeValue(user, 'correo')),
            _buildDetailRow('Matrícula', _getSafeValue(user, 'matricula')),
            _buildDetailRow('Rol', _getSafeValue(user, 'rol')),
            _buildDetailRow('Creado', _getSafeValue(user, 'creado_en')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditUserDialog(user);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003366),
                      side: const BorderSide(color: Color(0xFF003366)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmar Eliminación',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este usuario?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre: ${user['nombre']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Correo: ${user['correo']}'),
                  const SizedBox(height: 4),
                  Text('Rol: ${user['rol']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
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
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user['id'].toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            width: 100,
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

  Future<void> _createUser({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    String? matricula,
    String? grupo,
    required int activo,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF003366)),
      ),
    );

    try {
      print("=== CREANDO NUEVO USUARIO ===");
      print("Nombre: $nombre");
      print("Correo: $correo");
      print("Rol: $rol");
      print("Matrícula: $matricula");
      print("Grupo: $grupo");
      
      final result = await _apiService.createUser(
        nombre: nombre,
        correo: correo,
        password: password,
        rol: rol,
        matricula: matricula,
        grupo: grupo,
        activo: activo,
      );

      if (mounted) Navigator.pop(context);

      if (result != null) {
        print("✓ Usuario creado exitosamente");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('✓ Usuario "$nombre" creado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadUsers();
        }
      } else {
        print("✗ Error al crear usuario");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✗ Error al crear el usuario. Verifica los datos.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("✗ Excepción en _createUser: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('✗ Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateUser({
    required String userId,
    String? nombre,
    String? correo,
    String? password,
    String? rol,
    String? matricula,
    String? grupo,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF003366)),
      ),
    );

    try {
      print("=== ACTUALIZANDO USUARIO DESDE UI ===");
      print("User ID recibido: $userId");
      print("Tipo de userId: ${userId.runtimeType}");
      print("Nombre: $nombre");
      print("Correo: $correo");
      print("Rol: $rol");
      print("Matrícula: $matricula");
      print("Grupo: $grupo");
      print("Password: ${password != null && password.isNotEmpty ? '[TIENE PASSWORD]' : '[SIN PASSWORD]'}");
      
      final result = await _apiService.updateUser(
        userId: userId,
        nombre: nombre,
        correo: correo,
        password: password,
        rol: rol,
        matricula: matricula,
        grupo: grupo,
      );

      if (mounted) Navigator.pop(context);

      if (result) {
        print("✓ Usuario actualizado exitosamente desde UI");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('✓ Usuario "$nombre" actualizado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadUsers();
        }
      } else {
        print("✗ Error al actualizar usuario desde UI");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✗ Error al actualizar el usuario. Verifica la consola para más detalles.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("✗ Excepción en _updateUser UI: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('✗ Excepción: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {
      print("=== ELIMINANDO USUARIO DESDE UI ===");
      print("User ID recibido: $userId");
      print("Tipo de userId: ${userId.runtimeType}");
      
      final result = await _apiService.deleteUser(userId);

      if (mounted) Navigator.pop(context);

      if (result) {
        print("✓ Usuario eliminado exitosamente desde UI");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✓ Usuario eliminado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadUsers();
        }
      } else {
        print("✗ Error al eliminar usuario desde UI");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✗ Error al eliminar el usuario. Verifica la consola para más detalles.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("✗ Excepción en _deleteUser UI: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('✗ Excepción: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}