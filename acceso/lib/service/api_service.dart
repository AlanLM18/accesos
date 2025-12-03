import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bcrypt/bcrypt.dart';

class ApiService {
  static const String baseUrl = 'https://auxjfdcihhdbjsivhxwb.supabase.co/rest/v1';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1eGpmZGNpaGhkYmpzaXZoeHdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MTM5OTQsImV4cCI6MjA3NTI4OTk5NH0.bvc-gkCAizyMviVf5OJfsOlWyvL-TIIvS1ahs1Vojkg'; 
  
  static Map<String, String> get headers => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  };

  // Login 
  Future<Map<String, dynamic>?> login(String correo, String password) async {
    try {
      print("=== INICIANDO LOGIN ===");
      print("Correo: $correo");
      
      // Primero obtener el usuario por correo y que esté activo
      final response = await http.get(
        Uri.parse('$baseUrl/users?correo=eq.$correo&activo=eq.1&select=*'),
        headers: headers,
      );

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isEmpty) {
          print("Usuario no encontrado o inactivo");
          return null;
        }

        final user = data[0] as Map<String, dynamic>;
        final hashedPassword = user['password'] as String;
        
        // Verificar la contraseña con bcrypt
        print("Verificando contraseña...");
        final passwordMatch = BCrypt.checkpw(password, hashedPassword);
        
        if (passwordMatch) {
          print("✓ Login exitoso");
          return user;
        } else {
          print("✗ Contraseña incorrecta");
          return null;
        }
      } else {
        print("Error en login: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción en login: $e");
      return null;
    }
  }

  // usuario
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?id=eq.$userId&select=*'),
        headers: headers,
      );

      print("Status code getUserById: ${response.statusCode}");
      print("Response body getUserById: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isEmpty) {
          print("Usuario no encontrado");
          return null;
        }

        return data[0] as Map<String, dynamic>;
      } else {
        print("Error al obtener usuario: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción en getUserById: $e");
      return null;
    }
  }

  //QR alumnos
  Future<Map<String, dynamic>?> getQRByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qrcodes?user_id=eq.$userId&select=*'),
        headers: headers,
      );

      print("Status code getQRByUserId: ${response.statusCode}");
      print("Response body getQRByUserId: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isEmpty) {
          print("QR no encontrado para el usuario");
          return null;
        }

        return data[0] as Map<String, dynamic>;
      } else {
        print("Error al obtener QR: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción en getQRByUserId: $e");
      return null;
    }
  }

Future<Map<String, dynamic>?> generateNewQRUser(String userId) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCode = '$userId-$timestamp';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 3));
    
    print("=== GENERANDO NUEVO QR EN QRUSERS ===");
    print("User ID: $userId");
    print("QR Code: $qrCode");
    print("Expira en: $expiresAt");
    
    // Primero invalidar QRs anteriores del usuario
    await _invalidarQRsUsuarioAnteriores(userId);
    
    final headersWithPrefer = Map<String, String>.from(headers);
    headersWithPrefer['Prefer'] = 'return=representation';
    
    final response = await http.post(
      Uri.parse('$baseUrl/qrusers'),
      headers: headersWithPrefer,
      body: jsonEncode({
        'user_id': userId,
        'codigo': qrCode,
        'created_at': now.toIso8601String(),
        'expira_at': expiresAt.toIso8601String(),
        'usado': false,
      }),
    );
    
    print("Status code generateNewQRUser: ${response.statusCode}");
    print("Response body: ${response.body}");
    
    if (response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        print("✓ QR generado exitosamente en qrusers");
        return data[0] as Map<String, dynamic>;
      }
    } else {
      print("✗ Error al generar QR: ${response.statusCode} - ${response.body}");
      return null;
    }
    
    return null;
  } catch (e) {
    print("✗ Excepción en generateNewQRUser: $e");
    print("Stack trace: ${StackTrace.current}");
    return null;
  }
}

// Invalidar QRs anteriores del usuario en qrusers
Future<void> _invalidarQRsUsuarioAnteriores(String userId) async {
  try {
    print("Invalidando QRs anteriores del usuario...");
    
    final response = await http.patch(
      Uri.parse('$baseUrl/qrusers?user_id=eq.$userId&usado=eq.false'),
      headers: headers,
      body: jsonEncode({
        'usado': true,
        'usado_at': DateTime.now().toIso8601String(),
      }),
    );
    
    print("Status code invalidar QRs: ${response.statusCode}");
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      print("✓ QRs anteriores invalidados exitosamente");
    }
  } catch (e) {
    print("Error al invalidar QRs anteriores: $e");
  }
}

// Obtener QR activo (no usado y no expirado) del usuario de qrusers
Future<Map<String, dynamic>?> getQRUserByUserId(String userId) async {
  try {
    final now = DateTime.now().toIso8601String();
    
    final response = await http.get(
      Uri.parse('$baseUrl/qrusers?user_id=eq.$userId&usado=eq.false&expira_at=gt.$now&select=*&order=created_at.desc&limit=1'),
      headers: headers,
    );
    
    print("Status code getQRUserByUserId: ${response.statusCode}");
    print("Response body: ${response.body}");
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      if (data.isEmpty) {
        print("QR activo no encontrado para el usuario");
        return null;
      }
      
      return data[0] as Map<String, dynamic>;
    } else {
      print("Error al obtener QR: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    print("Excepción en getQRUserByUserId: $e");
    return null;
  }
}

// QR y Usuario usando qrusers
Future<Map<String, dynamic>?> getUserWithQRUser(String userId) async {
  try {
    final user = await getUserById(userId);
    if (user == null) return null;

    final qr = await getQRUserByUserId(userId);
    
    return {
      'user': user,
      'qr': qr,
    };
  } catch (e) {
    print("Excepción en getUserWithQRUser: $e");
    return null;
  }
}

// Verificar si el QR ha expirado usando expira_at
bool isQRUserExpired(String? expiraAt) {
  if (expiraAt == null) return true;
  
  try {
    final expiraDate = DateTime.parse(expiraAt);
    final now = DateTime.now();
    
    return now.isAfter(expiraDate);
  } catch (e) {
    print("Error al verificar expiración: $e");
    return true;
  }
}

// Obtener tiempo restante en segundos usando expira_at
int getTimeRemainingQRUser(String? expiraAt) {
  if (expiraAt == null) return 0;
  
  try {
    final expiraDate = DateTime.parse(expiraAt);
    final now = DateTime.now();
    final difference = expiraDate.difference(now);
    
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  } catch (e) {
    print("Error al calcular tiempo restante: $e");
    return 0;
  }
}

// Validar QR escaneado de qrusers
Future<Map<String, dynamic>?> validarQRUserEscaneado(String qrCode) async {
  try {
    print("=== VALIDANDO QR ESCANEADO (QRUSERS) ===");
    print("QR Code: $qrCode");
    
    // Buscar el QR en la base de datos
    final response = await http.get(
      Uri.parse('$baseUrl/qrusers?codigo=eq.$qrCode&select=*,users(*)'),
      headers: headers,
    );
    
    print("Status code validarQRUser: ${response.statusCode}");
    print("Response body: ${response.body}");
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      if (data.isEmpty) {
        print("✗ QR no encontrado");
        return {'valid': false, 'message': 'QR no válido'};
      }
      
      final qrData = data[0] as Map<String, dynamic>;
      final usado = qrData['usado'] as bool? ?? false;
      final expiraAt = qrData['expira_at'] as String?;
      final userData = qrData['users'] as Map<String, dynamic>?;
      
      // Verificar si ya fue usado
      if (usado) {
        print("✗ QR ya fue usado");
        final usadoAt = qrData['usado_at'] as String?;
        return {
          'valid': false, 
          'message': 'QR ya utilizado',
          'usado_at': usadoAt,
        };
      }
      
      // Verificar si expiró
      if (isQRUserExpired(expiraAt)) {
        print("✗ QR expirado");
        // Marcar como usado automáticamente
        await marcarQRUserComoUsado(qrCode);
        return {
          'valid': false, 
          'message': 'QR expirado',
          'expira_at': expiraAt,
        };
      }
      
      print("✓ QR válido");
      return {
        'valid': true,
        'message': 'QR válido',
        'qr_data': qrData,
        'user_data': userData,
        'time_remaining': getTimeRemainingQRUser(expiraAt),
      };
    } else {
      print("✗ Error al validar QR");
      return {'valid': false, 'message': 'Error al validar QR'};
    }
  } catch (e) {
    print("✗ Excepción en validarQRUserEscaneado: $e");
    return {'valid': false, 'message': 'Error al validar QR'};
  }
}

// Marcar QR como usado en qrusers
Future<bool> marcarQRUserComoUsado(String qrCode) async {
  try {
    print("=== MARCANDO QR COMO USADO (QRUSERS) ===");
    print("QR Code: $qrCode");
    
    final response = await http.patch(
      Uri.parse('$baseUrl/qrusers?codigo=eq.$qrCode'),
      headers: headers,
      body: jsonEncode({
        'usado': true,
        'usado_at': DateTime.now().toIso8601String(),
      }),
    );
    
    print("Status code marcarQRUserComoUsado: ${response.statusCode}");
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      print("✓ QR marcado como usado");
      return true;
    } else {
      print("✗ Error al marcar QR como usado");
      return false;
    }
  } catch (e) {
    print("✗ Excepción en marcarQRUserComoUsado: $e");
    return false;
  }
}

// Registrar acceso con QR de qrusers
Future<Map<String, dynamic>> registrarAccesoConQRUser(String qrCode, String zoneId, String zoneName) async {
  try {
    print("=== REGISTRANDO ACCESO CON QR (QRUSERS) ===");
    
    // Primero validar el QR
    final validacion = await validarQRUserEscaneado(qrCode);
    
    if (validacion?['valid'] != true) {
      print("✗ QR no válido: ${validacion?['message']}");
      return {
        'success': false,
        'message': validacion?['message'] ?? 'QR no válido',
      };
    }
    
    final qrData = validacion!['qr_data'] as Map<String, dynamic>;
    final userData = validacion['user_data'] as Map<String, dynamic>?;
    final userId = qrData['user_id'] as String;
    final qrId = qrData['id'] as String;
    
    // Marcar QR como usado
    final marcado = await marcarQRUserComoUsado(qrCode);
    
    if (!marcado) {
      return {
        'success': false,
        'message': 'Error al marcar QR como usado',
      };
    }
    
    // Registrar el acceso
    final headersWithPrefer = Map<String, String>.from(headers);
    headersWithPrefer['Prefer'] = 'return=representation';
    
    final response = await http.post(
      Uri.parse('$baseUrl/access'),
      headers: headersWithPrefer,
      body: jsonEncode({
        'user_id': userId,
        'zone_id': zoneId,
        'qr_id': qrId,
        'tipo': 'entrada',
        'fecha': DateTime.now().toIso8601String(),
        'zone_nombre': zoneName,
      }),
    );
    
    print("Status code registrarAcceso: ${response.statusCode}");
    print("Response body: ${response.body}");
    
    if (response.statusCode == 201) {
      print("✓ Acceso registrado exitosamente");
      return {
        'success': true,
        'message': 'Acceso concedido',
        'user_nombre': userData?['nombre'] ?? 'Usuario',
        'user_matricula': userData?['matricula'] ?? 'N/A',
        'zone_nombre': zoneName,
      };
    } else {
      print("✗ Error al registrar acceso");
      return {
        'success': false,
        'message': 'Error al registrar acceso',
      };
    }
  } catch (e) {
    print("✗ Excepción en registrarAccesoConQRUser: $e");
    return {
      'success': false,
      'message': 'Error al procesar acceso',
    };
  }
}

// Limpiar QRs expirados (función de mantenimiento opcional)
Future<int> limpiarQRsExpirados() async {
  try {
    print("=== LIMPIANDO QRs EXPIRADOS ===");
    
    final now = DateTime.now().toIso8601String();
    
    // Marcar QRs expirados como usados
    final response = await http.patch(
      Uri.parse('$baseUrl/qrusers?expira_at=lt.$now&usado=eq.false'),
      headers: headers,
      body: jsonEncode({
        'usado': true,
        'usado_at': DateTime.now().toIso8601String(),
      }),
    );
    
    print("Status code limpiarQRsExpirados: ${response.statusCode}");
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      print("✓ QRs expirados limpiados");
      return response.statusCode;
    }
    
    return 0;
  } catch (e) {
    print("✗ Excepción en limpiarQRsExpirados: $e");
    return 0;
  }
}

  

  // GET - Obtener todos los usuarios con mejor logging
Future<List<Map<String, dynamic>>> getAllUsers() async {
  try {
    print("=== OBTENIENDO TODOS LOS USUARIOS ===");
    print("URL: $baseUrl/users?select=*");
    
    final response = await http.get(
      Uri.parse('$baseUrl/users?select=*'),
      headers: headers,
    );

    print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} usuarios obtenidos");
      
      // Mostrar detalles de cada usuario en consola
      for (int i = 0; i < data.length; i++) {
        final user = data[i] as Map<String, dynamic>;
        print("""
                Usuario #${i + 1}:
                ID: ${user['id']}
                Nombre: ${user['nombre']}
                Correo: ${user['correo']}
                Matrícula: ${user['matricula']}
                Rol: ${user['rol']}
                Creado en: ${user['creado_en']}
                Password: ${user['password']?.substring(0, 5)}... (oculto)
            """);
      }
      
      return data.cast<Map<String, dynamic>>();
    } else {
      print("✗ Error HTTP: ${response.statusCode}");
      print("✗ Error body: ${response.body}");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getAllUsers: $e");
    print("✗ Stack trace: ${e.toString()}");
    return [];
  }
}

  // Crear usuario con contraseña hasheada
  Future<Map<String, dynamic>?> createUser({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    String? matricula,
    String? grupo,
    required int activo,
  }) async {
    try {
      print("=== CREANDO NUEVO USUARIO ===");
      
      final rolFormatted = rol[0].toUpperCase() + rol.substring(1).toLowerCase();
      
      // Hashear la contraseña con bcrypt
      print("Hasheando contraseña...");
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      print("✓ Contraseña hasheada exitosamente");
      
      final Map<String, dynamic> userData = {
        'nombre': nombre,
        'correo': correo,
        'password': hashedPassword, // Guardar el hash en lugar del texto plano
        'rol': rolFormatted,
        'matricula': matricula ?? '',
        'activo': 1,
      };
      
      if (rolFormatted.toLowerCase() == 'alumno' && grupo != null && grupo.isNotEmpty) {
        userData['grupo'] = grupo;
      }
      
      print("Datos a enviar (password hasheado): ${userData['password'].substring(0, 20)}...");
      print("Rol formateado: $rolFormatted");
      
      final headersWithPrefer = Map<String, String>.from(headers);
      headersWithPrefer['Prefer'] = 'return=representation';
      
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: headersWithPrefer,
        body: jsonEncode(userData),
      );

      print("Status code createUser: ${response.statusCode}");
      print("Response body createUser: ${response.body}");

      if (response.statusCode == 201) {
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print("Usuario creado exitosamente (sin body de respuesta)");
          return userData;
        }
        
        try {
          final List<dynamic> data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            print("✓ Usuario creado exitosamente con contraseña segura");
            return data[0] as Map<String, dynamic>;
          } else {
            print("Usuario creado pero respuesta vacía");
            return userData;
          }
        } catch (e) {
          print("Usuario creado, error al parsear respuesta: $e");
          return userData;
        }
      } else {
        print("Error al crear usuario - Status: ${response.statusCode}");
        print("Error body: ${response.body}");
        
        try {
          final errorData = jsonDecode(response.body);
          print("Error detallado: ${errorData['message'] ?? errorData}");
        } catch (e) {
          print("No se pudo parsear el error");
        }
        
        return null;
      }
    } catch (e) {
      print("Excepción en createUser: $e");
      print("Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  // Actualizar usuario con contraseña hasheada (si se proporciona)
  Future<bool> updateUser({
    required String userId,
    String? nombre,
    String? correo,
    String? password,
    String? rol,
    String? matricula,
    String? grupo,
  }) async {
    try {
      print("=== ACTUALIZANDO USUARIO ===");
      
      final Map<String, dynamic> updateData = {};
      
      if (nombre != null && nombre.isNotEmpty) {
        updateData['nombre'] = nombre;
      }
      if (correo != null && correo.isNotEmpty) {
        updateData['correo'] = correo;
      }
      
      // Si se proporciona una nueva contraseña, hashearla
      if (password != null && password.isNotEmpty) {
        print("Hasheando nueva contraseña...");
        final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
        updateData['password'] = hashedPassword;
        print("✓ Nueva contraseña hasheada");
      }
      
      if (rol != null && rol.isNotEmpty) {
        final rolFormatted = rol[0].toUpperCase() + rol.substring(1).toLowerCase();
        updateData['rol'] = rolFormatted;
        
        if (rolFormatted.toLowerCase() == 'alumno' && grupo != null && grupo.isNotEmpty) {
          updateData['grupo'] = grupo;
        } else if (rolFormatted.toLowerCase() != 'alumno') {
          updateData['grupo'] = null;
        }
      }
      if (matricula != null && matricula.isNotEmpty) {
        updateData['matricula'] = matricula;
      }
      
      print("Datos a actualizar: ${updateData.keys.toList()}");
      
      final response = await http.patch(
        Uri.parse('$baseUrl/users?id=eq.$userId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      print("Status code updateUser: ${response.statusCode}");
      print("Response body updateUser: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✓ Usuario actualizado exitosamente");
        return true;
      } else {
        print("✗ Error al actualizar usuario - Status: ${response.statusCode}");
        print("Error body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción en updateUser: $e");
      return false;
    }
  }


  //Eliminar un usuario
  Future<bool> deleteUser(String userId) async {
    try {
      
      final response = await http.delete(
        Uri.parse('$baseUrl/users?id=eq.$userId'),
        headers: headers,
      );

      print("Status code deleteUser: ${response.statusCode}");
      print("Response body deleteUser: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Usuario eliminado exitosamente");
        return true;
      } else {
        print("Error al eliminar usuario - Status: ${response.statusCode}");
        print("Error body: ${response.body}");
        
      
        try {
          final errorData = jsonDecode(response.body);
          print("Error detallado: ${errorData['message'] ?? errorData}");
        } catch (e) {
          print("No se pudo parsear el error");
        }
        
        return false;
      }
    } catch (e) {
      print("Excepción en deleteUser: $e");
      print("Stack trace: ${StackTrace.current}");
      return false;
    }
  }

  // Obtener todos los accesos con información de usuario y zona
  Future<List<Map<String, dynamic>>> getAllAccess() async {
    try {
      print("=== OBTENIENDO TODOS LOS ACCESOS ===");
      
      // Usar join para obtener datos de users y zones
      final url = '$baseUrl/access?select=*,users(nombre,correo,matricula),zones(nombre)&order=fecha.desc';
      print("URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print("Status code getAllAccess: ${response.statusCode}");
      print("Response body getAllAccess: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✓ ${data.length} registros de acceso obtenidos");
        
        // Transformar los datos para que sean más fáciles de usar
        final List<Map<String, dynamic>> accessList = [];
        
        for (var item in data) {
          final accessData = item as Map<String, dynamic>;
          
          // Extraer datos del usuario
          final userData = accessData['users'] as Map<String, dynamic>?;
          
          // Extraer datos de la zona
          final zoneData = accessData['zones'] as Map<String, dynamic>?;
          
          accessList.add({
            'id': accessData['id'],
            'user_id': accessData['user_id'],
            'zone_id': accessData['zone_id'],
            'fecha': accessData['fecha'],
            'tipo': accessData['tipo'],
            'qr_id': accessData['qr_id'],
            'zone_nombre': accessData['zone_nombre'],
            // Datos del usuario
            'user_nombre': userData?['nombre'] ?? 'Usuario desconocido',
            'user_correo': userData?['correo'] ?? 'N/A',
            'user_matricula': userData?['matricula'] ?? 'N/A',
            // Datos de la zona
            'zone_name': zoneData?['nombre'] ?? 'Zona desconocida',
          });
        }
        
        print("✓ Datos transformados exitosamente");
        return accessList;
      } else {
        print("✗ Error HTTP: ${response.statusCode}");
        print("✗ Error body: ${response.body}");
        return [];
      }
    } catch (e) {
      print("✗ Excepción en getAllAccess: $e");
      print("✗ Stack trace: ${e.toString()}");
      return [];
    }
  }

  // Obtener accesos por usuario
  Future<List<Map<String, dynamic>>> getAccessByUserId(String userId) async {
    try {
      print("=== OBTENIENDO ACCESOS POR USUARIO ===");
      print("User ID: $userId");
      
      final url = '$baseUrl/access?user_id=eq.$userId&select=*,zones(nombre)&order=fecha.desc';
      print("URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print("Status code getAccessByUserId: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✓ ${data.length} registros encontrados");
        
        final List<Map<String, dynamic>> accessList = [];
        
        for (var item in data) {
          final accessData = item as Map<String, dynamic>;
          final zoneData = accessData['zones'] as Map<String, dynamic>?;
          
          accessList.add({
            'id': accessData['id'],
            'user_id': accessData['user_id'],
            'zone_id': accessData['zone_id'],
            'fecha': accessData['fecha'],
            'tipo': accessData['tipo'],
            'qr_id': accessData['qr_id'],
            'zone_nombre': accessData['zone_nombre'],
            'zone_name': zoneData?['nombre'] ?? 'Zona desconocida',
          });
        }
        
        return accessList;
      } else {
        print("✗ Error al obtener accesos");
        return [];
      }
    } catch (e) {
      print("✗ Excepción en getAccessByUserId: $e");
      return [];
    }
  }

  // Obtener accesos por zona
  Future<List<Map<String, dynamic>>> getAccessByZoneId(String zoneId) async {
    try {
      print("=== OBTENIENDO ACCESOS POR ZONA ===");
      print("Zone ID: $zoneId");
      
      final url = '$baseUrl/access?zone_id=eq.$zoneId&select=*,users(nombre,correo,matricula)&order=fecha.desc';
      print("URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print("Status code getAccessByZoneId: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✓ ${data.length} registros encontrados");
        
        final List<Map<String, dynamic>> accessList = [];
        
        for (var item in data) {
          final accessData = item as Map<String, dynamic>;
          final userData = accessData['users'] as Map<String, dynamic>?;
          
          accessList.add({
            'id': accessData['id'],
            'user_id': accessData['user_id'],
            'zone_id': accessData['zone_id'],
            'fecha': accessData['fecha'],
            'tipo': accessData['tipo'],
            'qr_id': accessData['qr_id'],
            'zone_nombre': accessData['zone_nombre'],
            'user_nombre': userData?['nombre'] ?? 'Usuario desconocido',
            'user_correo': userData?['correo'] ?? 'N/A',
            'user_matricula': userData?['matricula'] ?? 'N/A',
          });
        }
        
        return accessList;
      } else {
        print("✗ Error al obtener accesos");
        return [];
      }
    } catch (e) {
      print("✗ Excepción en getAccessByZoneId: $e");
      return [];
    }
  }

  // Obtener accesos
  Future<List<Map<String, dynamic>>> getAccessByType(String tipo) async {
    try {
      print("Tipo: $tipo");
      
      final url = '$baseUrl/access?tipo=eq.$tipo&select=*,users(nombre,correo,matricula),zones(nombre)&order=fecha.desc';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(" ${data.length} registros encontrados");
        
        final List<Map<String, dynamic>> accessList = [];
        
        for (var item in data) {
          final accessData = item as Map<String, dynamic>;
          final userData = accessData['users'] as Map<String, dynamic>?;
          final zoneData = accessData['zones'] as Map<String, dynamic>?;
          
          accessList.add({
            'id': accessData['id'],
            'user_id': accessData['user_id'],
            'zone_id': accessData['zone_id'],
            'fecha': accessData['fecha'],
            'tipo': accessData['tipo'],
            'qr_id': accessData['qr_id'],
            'zone_nombre': accessData['zone_nombre'],
            'user_nombre': userData?['nombre'] ?? 'Usuario desconocido',
            'user_correo': userData?['correo'] ?? 'N/A',
            'user_matricula': userData?['matricula'] ?? 'N/A',
            'zone_name': zoneData?['nombre'] ?? 'Zona desconocida',
          });
        }
        
        return accessList;
      } else {
        print("Error al obtener accesos");
        return [];
      }
    } catch (e) {
      print("Excepción en getAccessByType: $e");
      return [];
    }
  }


  // Logout 
  Future<bool> logout(String userId) async {
    try {
      print("=== CERRANDO SESIÓN ===");
      print("User ID: $userId");
      
      
      final response = await http.patch(
        Uri.parse('$baseUrl/users?id=eq.$userId'),
        headers: headers,
        body: jsonEncode({
          'ultimo_logout': DateTime.now().toIso8601String(),
        }),
      );

      print("Status code logout: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Logout registrado exitosamente");
        return true;
      } else {
        print("No se pudo registrar el logout, pero continuando...");
        return true; 
      }
    } catch (e) {
      print("Excepción en logout: $e");
      return true; 
    }
  }



// Grupos tutorados
Future<List<Map<String, dynamic>>> getGruposByTutor(String tutorId) async {
  try {
    print("Tutor ID: $tutorId");
    
    final response = await http.get(
      Uri.parse('$baseUrl/tutores?tutor=eq.$tutorId&select=*'),
      headers: headers,
    );

    print("Status code getGruposByTutor: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} grupos encontrados para el tutor");
      
      return data.cast<Map<String, dynamic>>();
    } else {
      print("✗ Error al obtener grupos del tutor");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getGruposByTutor: $e");
    return [];
  }
}


// Materias por grupo - Corregida para usar JOIN con tabla materias
Future<List<Map<String, dynamic>>> getMateriasByGrupo(String grupo) async {
  try {
    print("=== OBTENIENDO MATERIAS POR GRUPO ===");
    print("Grupo: $grupo");
    
    // Hacer JOIN con la tabla materias para obtener nom_mat
    final response = await http.get(
      Uri.parse('$baseUrl/classes?grupo=eq.$grupo&select=id,materia,horario,grupo,materias(id,nom_mat)'),
      headers: headers,
    );

    print("Status code getMateriasByGrupo: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} registros encontrados");
      
      // Eliminar materias duplicadas basándose en el ID de la materia
      final Set<String> idsMateriasVistas = {};
      final List<Map<String, dynamic>> materiasUnicas = [];
      
      for (var clase in data) {
        final claseMap = clase as Map<String, dynamic>;
        final materiaId = claseMap['materia'] as String?;
        final materiaData = claseMap['materias'] as Map<String, dynamic>?;
        
        // Solo agregar si no hemos visto esta materia antes
        if (materiaId != null && !idsMateriasVistas.contains(materiaId)) {
          idsMateriasVistas.add(materiaId);
          
          materiasUnicas.add({
            'id': claseMap['id'],
            'materia_id': materiaId,
            'nombre': materiaData?['nom_mat'] ?? 'Sin nombre',
            'horario': claseMap['horario'],
            'grupo': claseMap['grupo'],
          });
        }
      }
      
      print("✓ ${materiasUnicas.length} materias únicas encontradas");
      
      // Mostrar detalles de cada materia única
      for (var materia in materiasUnicas) {
        print("""
        Materia:
        ID Clase: ${materia['id']}
        ID Materia: ${materia['materia_id']}
        Nombre: ${materia['nombre']}
        Horario: ${materia['horario']}
        Grupo: ${materia['grupo']}
        """);
      }
      
      return materiasUnicas;
    } else {
      print("✗ Error al obtener materias del grupo");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getMateriasByGrupo: $e");
    return [];
  }
}

// Materias por grupo con profesor - Corregida para usar JOIN con tabla materias
Future<List<Map<String, dynamic>>> getMateriasByGrupoConProfesor(String grupo) async {
  try {
    print("=== OBTENIENDO MATERIAS CON PROFESOR POR GRUPO ===");
    print("Grupo: $grupo");
    
    // Hacer JOIN con materias para obtener nom_mat y id_profesor
    final response = await http.get(
      Uri.parse('$baseUrl/classes?grupo=eq.$grupo&select=id,materia,horario,grupo,materias(id,nom_mat,id_profesor,users:id_profesor(nombre,correo))'),
      headers: headers,
    );

    print("Status code getMateriasByGrupoConProfesor: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} registros encontrados");
      
      final Set<String> idsMateriasVistas = {};
      final List<Map<String, dynamic>> materiasUnicas = [];
      
      for (var clase in data) {
        final claseMap = clase as Map<String, dynamic>;
        final materiaId = claseMap['materia'] as String?;
        final materiaData = claseMap['materias'] as Map<String, dynamic>?;
        
        // Solo agregar si no hemos visto esta materia antes
        if (materiaId != null && !idsMateriasVistas.contains(materiaId)) {
          idsMateriasVistas.add(materiaId);
          
          // Extraer datos del profesor desde materias -> users
          final profesorData = materiaData?['users'] as Map<String, dynamic>?;
          
          materiasUnicas.add({
            'id': claseMap['id'],
            'materia_id': materiaId,
            'nombre': materiaData?['nom_mat'] ?? 'Sin nombre',
            'horario': claseMap['horario'],
            'grupo': claseMap['grupo'],
            'profesor_id': materiaData?['id_profesor'],
            'profesor_nombre': profesorData?['nombre'] ?? 'Sin asignar',
            'profesor_correo': profesorData?['correo'] ?? 'N/A',
          });
        }
      }
      
      print("✓ ${materiasUnicas.length} materias únicas con profesor encontradas");
      
      // Mostrar detalles
      for (var materia in materiasUnicas) {
        print("""
        Materia con Profesor:
        ID Clase: ${materia['id']}
        ID Materia: ${materia['materia_id']}
        Nombre: ${materia['nombre']}
        Grupo: ${materia['grupo']}
        Profesor: ${materia['profesor_nombre']} (${materia['profesor_correo']})
        """);
      }
      
      return materiasUnicas;
    } else {
      print("✗ Error al obtener materias con profesor");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getMateriasByGrupoConProfesor: $e");
    return [];
  }
}


// Obtener asistencias por materia (clase)
Future<List<Map<String, dynamic>>> getAsistenciasByClase(String claseId) async {
  try {
    print("=== OBTENIENDO ASISTENCIAS POR CLASE ===");
    print("Clase ID: $claseId");
    

    final response = await http.get(
      Uri.parse('$baseUrl/attendance?clase_id=eq.$claseId&select=*,users:user_id(nombre,matricula)&order=fecha.desc'),
      headers: headers,
    );

    print("Status code getAsistenciasByClase: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} registros de asistencia encontrados");
      
      final List<Map<String, dynamic>> asistencias = [];
      
      for (var item in data) {
        final asistenciaData = item as Map<String, dynamic>;
        final userData = asistenciaData['users'] as Map<String, dynamic>?;
        
        asistencias.add({
          'id': asistenciaData['id'],
          'user_id': asistenciaData['user_id'],
          'clase_id': asistenciaData['clase_id'],
          'fecha': asistenciaData['fecha'],
          'estado': asistenciaData['estado'],
          'qr_id': asistenciaData['qr_id'],
          'alumno_nombre': userData?['nombre'] ?? 'Desconocido',
          'alumno_matricula': userData?['matricula'] ?? 'N/A',
        });
      }
      
      return asistencias;
    } else {
      print("✗ Error al obtener asistencias");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getAsistenciasByClase: $e");
    return [];
  }
}

// Asistencias agrupadas por alumno 
Future<Map<String, dynamic>> getAsistenciasTabla(String claseId) async {
  try {
    print("=== OBTENIENDO ASISTENCIAS PARA TABLA ===");
    
    final asistencias = await getAsistenciasByClase(claseId);
    
    if (asistencias.isEmpty) {
      return {
        'alumnos': [],
        'fechas': [],
        'asistencias': {},
      };
    }

    final Set<String> fechasSet = {};
    for (var asistencia in asistencias) {
      final fecha = asistencia['fecha'] as String?;
      if (fecha != null) {

        final fechaSolo = fecha.split('T')[0];
        fechasSet.add(fechaSolo);
      }
    }
    
    final List<String> fechas = fechasSet.toList()..sort((a, b) => b.compareTo(a));
    

    final Map<String, Map<String, dynamic>> alumnosMap = {};
    for (var asistencia in asistencias) {
      final userId = asistencia['user_id'] as String;
      if (!alumnosMap.containsKey(userId)) {
        alumnosMap[userId] = {
          'user_id': userId,
          'nombre': asistencia['alumno_nombre'],
          'matricula': asistencia['alumno_matricula'],
        };
      }
    }

    final List<Map<String, dynamic>> alumnos = alumnosMap.values.toList()
      ..sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));
    
    
    final Map<String, Map<String, String>> asistenciasMap = {};
    
    for (var alumno in alumnos) {
      final userId = alumno['user_id'] as String;
      asistenciasMap[userId] = {};
      
      for (var fecha in fechas) {
 
        final asistenciaEncontrada = asistencias.firstWhere(
          (a) {
            final fechaAsistencia = (a['fecha'] as String).split('T')[0];
            return a['user_id'] == userId && fechaAsistencia == fecha;
          },
          orElse: () => {},
        );
        
        if (asistenciaEncontrada.isNotEmpty) {
          asistenciasMap[userId]![fecha] = asistenciaEncontrada['estado'] as String;
        } else {
          asistenciasMap[userId]![fecha] = 'Sin registro';
        }
      }
    }
    
    print("✓ Tabla procesada: ${alumnos.length} alumnos, ${fechas.length} fechas");
    
    return {
      'alumnos': alumnos,
      'fechas': fechas,
      'asistencias': asistenciasMap,
    };
  } catch (e) {
    print("✗ Excepción en getAsistenciasTabla: $e");
    return {
      'alumnos': [],
      'fechas': [],
      'asistencias': {},
    };
  }
}

// Obtener materias que imparte un profesor
Future<List<Map<String, dynamic>>> getMateriasByProfesor(String profesorId) async {
  try {
    print("=== OBTENIENDO MATERIAS POR PROFESOR ===");
    print("Profesor ID: $profesorId");
    
    final response = await http.get(
      Uri.parse('$baseUrl/materias?id_profesor=eq.$profesorId&select=*'),
      headers: headers,
    );

    print("Status code getMateriasByProfesor: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print(" ${data.length} materias encontradas para el profesor");
      
      return data.cast<Map<String, dynamic>>();
    } else {
      print("Error al obtener materias del profesor");
      return [];
    }
  } catch (e) {
    print("Excepción en getMateriasByProfesor: $e");
    return [];
  }
}

// Obtener grupos únicos de una materia específica
Future<List<Map<String, dynamic>>> getGruposByMateria(String materiaId) async {
  try {
    print("=== OBTENIENDO GRUPOS POR MATERIA ===");
    print("Materia ID: $materiaId");
    
    final response = await http.get(
      Uri.parse('$baseUrl/classes?materia=eq.$materiaId&select=grupo&order=grupo.asc'),
      headers: headers,
    );

    print("Status code getGruposByMateria: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      // Extraer grupos únicos
      final Set<String> gruposUnicos = {};
      final List<Map<String, dynamic>> grupos = [];
      
      for (var item in data) {
        final grupo = item['grupo'] as String?;
        if (grupo != null && !gruposUnicos.contains(grupo)) {
          gruposUnicos.add(grupo);
          grupos.add({
            'grupo': grupo,
          });
        }
      }
      
      print("✓ ${grupos.length} grupos únicos encontrados");
      return grupos;
    } else {
      print("✗ Error al obtener grupos");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getGruposByMateria: $e");
    return [];
  }
}

// Obtener datos completos del estudiante (usuario + grupo + asistencias)
Future<Map<String, dynamic>?> getDatosEstudiante(String userId) async {
  try {
    print("=== OBTENIENDO DATOS DEL ESTUDIANTE ===");
    print("User ID: $userId");
    

    final usuario = await getUserById(userId);
    if (usuario == null) {
      print("Usuario no encontrado");
      return null;
    }
    
    final grupo = usuario['grupo'] as String?;
    print("Grupo del estudiante: $grupo");
    
    if (grupo == null || grupo.isEmpty) {
      print("El estudiante no tiene grupo asignado");
      return {
        'usuario': usuario,
        'grupo': null,
        'materias': [],
      };
    }
    
    final materias = await getMateriasByGrupoConProfesor(grupo);
    print(" ${materias.length} materias encontradas");
    

    List<Map<String, dynamic>> materiasConAsistencia = [];
    
    for (var materia in materias) {
      final materiaId = materia['id'] as String;
      final porcentaje = await calcularPorcentajeAsistencia(userId, materiaId);
      
      materiasConAsistencia.add({
        'id': materiaId,
        'nombre': materia['nombre'],
        'horario': materia['horario'],
        'porcentaje': porcentaje,
        'docente': materia['profesor_nombre'],
      });
    }
    
    print("Datos del estudiante obtenidos exitosamente");
    
    return {
      'usuario': usuario,
      'grupo': grupo,
      'materias': materiasConAsistencia,
    };
  } catch (e) {
    print("✗ Excepción en getDatosEstudiante: $e");
    return null;
  }
}

// Calcular porcentaje de asistencia de una materia
Future<int> calcularPorcentajeAsistencia(String userId, String claseId) async {
  try {

    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$claseId&select=estado'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      if (data.isEmpty) {
        return 0;
      }
      

      int totalClases = data.length;
      int asistencias = 0;
      
      for (var registro in data) {
        final estado = (registro['estado'] as String?)?.toLowerCase();
        if (estado == 'presente') {
          asistencias++;
        }
      }
      

      int porcentaje = ((asistencias / totalClases) * 100).round();
      
      print("Asistencia calculada: $asistencias/$totalClases = $porcentaje%");
      
      return porcentaje;
    } else {
      print("Error al calcular asistencia. Status: ${response.statusCode}");
      return 0;
    }
  } catch (e) {
    print("Excepción en calcularPorcentajeAsistencia: $e");
    return 0;
  }
}

// Obtener todas las asistencias de un alumno
Future<List<Map<String, dynamic>>> getAsistenciasByAlumno(String userId) async {
  try {
    
    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&select=*,classes:clase_id(nombre,horario,grupo)&order=fecha.desc'),
      headers: headers,
    );

    print("Status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print(" ${data.length} registros de asistencia encontrados");
      
      final List<Map<String, dynamic>> asistencias = [];
      
      for (var item in data) {
        final asistenciaData = item as Map<String, dynamic>;
        final claseData = asistenciaData['classes'] as Map<String, dynamic>?;
        
        final estadoOriginal = asistenciaData['estado'] as String?;
        final estadoNormalizado = estadoOriginal?.toLowerCase() ?? 'desconocido';
        
        asistencias.add({
          'id': asistenciaData['id'],
          'user_id': asistenciaData['user_id'],
          'clase_id': asistenciaData['clase_id'],
          'fecha': asistenciaData['fecha'],
          'estado': estadoNormalizado, 
          'materia_nombre': claseData?['nombre'] ?? 'Desconocida',
          'materia_horario': claseData?['horario'] ?? 'N/A',
          'materia_grupo': claseData?['grupo'] ?? 'N/A',
        });
      }
      
      return asistencias;
    } else {
      print("Error al obtener asistencias. Status: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("Excepción en getAsistenciasByAlumno: $e");
    return [];
  }
}

// Obtener inasistencias
Future<List<Map<String, dynamic>>> getInasistenciasByAlumnoYMateria(String userId, String claseId) async {
  try {
    

    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$claseId&estado=eq.falta&select=*&order=fecha.desc'),
      headers: headers,
    );

    print("Status code getInasistenciasByAlumnoYMateria: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✓ ${data.length} faltas encontradas");
      
      return data.cast<Map<String, dynamic>>();
    } else {
      print("✗ Error al obtener inasistencias. Status: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("✗ Excepción en getInasistenciasByAlumnoYMateria: $e");
    return [];
  }
}

// Obtener estadísticas de asistencia
Future<Map<String, int>> getEstadisticasAsistencia(String userId, String claseId) async {
  try {
    
    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$claseId&select=estado'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      int presentes = 0;
      int faltas = 0;
      
      for (var registro in data) {
        final estado = (registro['estado'] as String?)?.toLowerCase();
        if (estado == 'presente') {
          presentes++;
        } else if (estado == 'falta') {
          faltas++;
        }
      }
      
      print("Estadísticas: ${data.length} total, $presentes presentes, $faltas faltas");
      
      return {
        'total': data.length,
        'presentes': presentes,
        'faltas': faltas,
      };
    } else {
      print("Error al obtener estadísticas. Status: ${response.statusCode}");
      return {'total': 0, 'presentes': 0, 'faltas': 0};
    }
  } catch (e) {
    print("Excepción en getEstadisticasAsistencia: $e");
    return {'total': 0, 'presentes': 0, 'faltas': 0};
  }
}

// Agregar este método a tu ApiService class

// Obtener alumnos de un grupo con su porcentaje de asistencia en una materia específica
Future<List<Map<String, dynamic>>> getAlumnosConAsistenciaByGrupoYMateria(
  String grupo, 
  String materiaId
) async {
  try {
    print("=== OBTENIENDO ALUMNOS CON ASISTENCIA ===");
    print("Grupo: $grupo");
    print("Materia ID: $materiaId");
    
    // 1. Obtener todos los alumnos del grupo
    final responseAlumnos = await http.get(
      Uri.parse('$baseUrl/users?grupo=eq.$grupo&rol=eq.Alumno&activo=eq.1&select=id,nombre,matricula,grupo'),
      headers: headers,
    );

    print("Status code alumnos: ${responseAlumnos.statusCode}");

    if (responseAlumnos.statusCode != 200) {
      print("✗ Error al obtener alumnos");
      return [];
    }

    final List<dynamic> alumnosData = jsonDecode(responseAlumnos.body);
    print("✓ ${alumnosData.length} alumnos encontrados en el grupo");

    if (alumnosData.isEmpty) {
      return [];
    }

    // 2. Para cada alumno, calcular su porcentaje de asistencia
    List<Map<String, dynamic>> alumnosConAsistencia = [];

    for (var alumnoData in alumnosData) {
      final alumno = alumnoData as Map<String, dynamic>;
      final userId = alumno['id'] as String;
      final nombre = alumno['nombre'] as String;
      final matricula = alumno['matricula'] as String? ?? 'N/A';

      // Calcular porcentaje de asistencia para esta materia
      final porcentaje = await calcularPorcentajeAsistencia(userId, materiaId);

      alumnosConAsistencia.add({
        'id': userId,
        'nombre': nombre,
        'matricula': matricula,
        'grupo': grupo,
        'porcentaje': porcentaje,
      });
    }

    // Ordenar por nombre
    alumnosConAsistencia.sort((a, b) => 
      (a['nombre'] as String).compareTo(b['nombre'] as String)
    );

    print("✓ ${alumnosConAsistencia.length} alumnos procesados con asistencias");

    return alumnosConAsistencia;
  } catch (e) {
    print("✗ Excepción en getAlumnosConAsistenciaByGrupoYMateria: $e");
    return [];
  }
}

Future<Map<String, dynamic>> getDatosPrediccionAlumno(String userId, String claseId) async {
  try {
    print("=== OBTENIENDO DATOS PARA PREDICCIÓN ===");
    print("User ID: $userId");
    print("Clase ID: $claseId");
    
    // 1. Obtener datos del alumno
    final alumno = await getUserById(userId);
    if (alumno == null) {
      print("✗ Alumno no encontrado");
      return {
        'success': false,
        'message': 'Alumno no encontrado',
      };
    }
    
    // 2. Obtener todas las asistencias del alumno para esta clase
    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$claseId&select=fecha,estado&order=fecha.asc'),
      headers: headers,
    );
    
    print("Status code getDatosPrediccionAlumno: ${response.statusCode}");
    
    if (response.statusCode != 200) {
      print("✗ Error al obtener asistencias");
      return {
        'success': false,
        'message': 'Error al obtener asistencias',
      };
    }
    
    final List<dynamic> data = jsonDecode(response.body);
    print("✓ ${data.length} registros de asistencia encontrados");
    
    // 3. Procesar datos
    List<String> fechas = [];
    List<String> asistencias = [];
    int totalPresentes = 0;
    int totalFaltas = 0;
    
    for (var registro in data) {
      final fecha = registro['fecha'] as String?;
      final estado = registro['estado'] as String? ?? 'Sin registro';
      
      if (fecha != null) {
        // Extraer solo la fecha (sin hora)
        final fechaSolo = fecha.split('T')[0];
        fechas.add(fechaSolo);
        asistencias.add(estado);
        
        // Contar estadísticas
        if (estado.toLowerCase() == 'presente') {
          totalPresentes++;
        } else if (estado.toLowerCase() == 'falta') {
          totalFaltas++;
        }
      }
    }
    
    // 4. Calcular estadísticas adicionales
    double porcentajeAsistencia = fechas.isEmpty 
        ? 0.0 
        : (totalPresentes / fechas.length) * 100;
    
    // Calcular racha actual
    int rachaActual = 0;
    if (asistencias.isNotEmpty) {
      String ultimoEstado = asistencias.last.toLowerCase();
      for (int i = asistencias.length - 1; i >= 0; i--) {
        if (asistencias[i].toLowerCase() == ultimoEstado) {
          rachaActual++;
        } else {
          break;
        }
      }
      if (ultimoEstado == 'falta') {
        rachaActual = -rachaActual;
      }
    }
    
    // Calcular mejor racha
    int mejorRacha = 0;
    int rachaTemp = 0;
    for (String estado in asistencias) {
      if (estado.toLowerCase() == 'presente') {
        rachaTemp++;
        if (rachaTemp > mejorRacha) {
          mejorRacha = rachaTemp;
        }
      } else {
        rachaTemp = 0;
      }
    }
    
    // Calcular tendencia
    String tendencia = 'Sin suficientes datos';
    if (asistencias.length >= 14) {
      int mitad = asistencias.length ~/ 2;
      int presentesPrimera = asistencias.sublist(0, mitad)
          .where((a) => a.toLowerCase() == 'presente').length;
      int presentesSegunda = asistencias.sublist(mitad)
          .where((a) => a.toLowerCase() == 'presente').length;
      
      double porcentajePrimera = presentesPrimera / mitad;
      double porcentajeSegunda = presentesSegunda / (asistencias.length - mitad);
      double diferencia = porcentajeSegunda - porcentajePrimera;
      
      if (diferencia > 0.1) {
        tendencia = 'Mejorando ↑';
      } else if (diferencia < -0.1) {
        tendencia = 'Empeorando ↓';
      } else {
        tendencia = 'Estable →';
      }
    }
    
    // 5. Calcular patrón semanal
    Map<String, double> patronSemanal = {};
    Map<String, int> totalPorDia = {};
    Map<String, int> presentesPorDia = {};
    
    for (int i = 0; i < fechas.length; i++) {
      try {
        DateTime fecha = DateTime.parse(fechas[i]);
        String diaSemana = _getDiaSemana(fecha.weekday);
        
        totalPorDia[diaSemana] = (totalPorDia[diaSemana] ?? 0) + 1;
        if (asistencias[i].toLowerCase() == 'presente') {
          presentesPorDia[diaSemana] = (presentesPorDia[diaSemana] ?? 0) + 1;
        }
      } catch (e) {
        // Ignorar fechas inválidas
      }
    }
    
    totalPorDia.forEach((dia, total) {
      patronSemanal[dia] = ((presentesPorDia[dia] ?? 0) / total) * 100;
    });
    
    print("✓ Datos procesados exitosamente para predicción");
    
    return {
      'success': true,
      'alumno': {
        'id': userId,
        'nombre': alumno['nombre'] ?? 'Sin nombre',
        'matricula': alumno['matricula'] ?? 'N/A',
        'grupo': alumno['grupo'] ?? 'N/A',
      },
      'fechas': fechas,
      'asistencias': asistencias,
      'estadisticas': {
        'totalClases': fechas.length,
        'totalPresentes': totalPresentes,
        'totalFaltas': totalFaltas,
        'porcentajeAsistencia': porcentajeAsistencia,
        'rachaActual': rachaActual,
        'mejorRacha': mejorRacha,
        'tendencia': tendencia,
      },
      'patronSemanal': patronSemanal,
    };
  } catch (e) {
    print("✗ Excepción en getDatosPrediccionAlumno: $e");
    return {
      'success': false,
      'message': 'Error al procesar datos: $e',
    };
  }
}

/// Obtiene los datos de predicción para todos los alumnos de una clase
/// Útil para ver predicciones en lote
Future<List<Map<String, dynamic>>> getDatosPrediccionClase(String claseId) async {
  try {
    print("=== OBTENIENDO DATOS DE PREDICCIÓN PARA CLASE ===");
    print("Clase ID: $claseId");
    
    // 1. Obtener todos los alumnos que tienen asistencias en esta clase
    final response = await http.get(
      Uri.parse('$baseUrl/attendance?clase_id=eq.$claseId&select=user_id,users:user_id(id,nombre,matricula,grupo)'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      print("✗ Error al obtener alumnos de la clase");
      return [];
    }
    
    final List<dynamic> data = jsonDecode(response.body);
    
    // Extraer IDs únicos de alumnos
    final Set<String> alumnosIds = {};
    for (var registro in data) {
      final userId = registro['user_id'] as String?;
      if (userId != null) {
        alumnosIds.add(userId);
      }
    }
    
    print("✓ ${alumnosIds.length} alumnos únicos encontrados");
    
    // 2. Obtener datos de predicción para cada alumno
    List<Map<String, dynamic>> resultados = [];
    
    for (String alumnoId in alumnosIds) {
      final datosAlumno = await getDatosPrediccionAlumno(alumnoId, claseId);
      if (datosAlumno['success'] == true) {
        resultados.add(datosAlumno);
      }
    }
    
    // Ordenar por nombre de alumno
    resultados.sort((a, b) {
      final nombreA = a['alumno']?['nombre'] ?? '';
      final nombreB = b['alumno']?['nombre'] ?? '';
      return nombreA.compareTo(nombreB);
    });
    
    print("✓ ${resultados.length} alumnos procesados para predicción");
    
    return resultados;
  } catch (e) {
    print("✗ Excepción en getDatosPrediccionClase: $e");
    return [];
  }
}

/// Obtiene el historial de asistencias de un alumno en una clase específica
/// ordenado cronológicamente (de más antiguo a más reciente)
/// 
/// Retorna una lista de Maps con 'fecha' y 'estado'
Future<List<Map<String, String>>> getHistorialAsistenciasAlumno(String userId, String claseId) async {
  try {
    print("=== OBTENIENDO HISTORIAL DE ASISTENCIAS ===");
    
    final response = await http.get(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$claseId&select=fecha,estado&order=fecha.asc'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      print("✗ Error al obtener historial");
      return [];
    }
    
    final List<dynamic> data = jsonDecode(response.body);
    
    List<Map<String, String>> historial = [];
    
    for (var registro in data) {
      final fecha = registro['fecha'] as String?;
      final estado = registro['estado'] as String?;
      
      if (fecha != null && estado != null) {
        historial.add({
          'fecha': fecha.split('T')[0],
          'estado': estado,
        });
      }
    }
    
    print("✓ ${historial.length} registros en historial");
    
    return historial;
  } catch (e) {
    print("✗ Excepción en getHistorialAsistenciasAlumno: $e");
    return [];
  }
}

/// Helper function para obtener nombre del día de la semana
String _getDiaSemana(int weekday) {
  switch (weekday) {
    case 1: return 'Lunes';
    case 2: return 'Martes';
    case 3: return 'Miércoles';
    case 4: return 'Jueves';
    case 5: return 'Viernes';
    case 6: return 'Sábado';
    case 7: return 'Domingo';
    default: return 'Desconocido';
  }
}

// REEMPLAZA el método updateAsistencia que ya tienes al final de tu ApiService

Future<void> updateAsistencia(
  String materiaId,
  String userId,
  String fecha,
  String nuevoEstado,
) async {
  try {
    print("=== ACTUALIZANDO ASISTENCIA ===");
    print("Materia ID: $materiaId");
    print("User ID: $userId");
    print("Fecha: $fecha");
    print("Nuevo estado: $nuevoEstado");
    
    // La fecha viene como "2024-01-15", necesitamos buscar registros de ese día
    // Supabase guarda fechas como "2024-01-15T10:30:00+00:00"
    final fechaInicio = '${fecha}T00:00:00';
    final fechaFin = '${fecha}T23:59:59';
    
    // Actualizar en la tabla attendance
    final response = await http.patch(
      Uri.parse('$baseUrl/attendance?user_id=eq.$userId&clase_id=eq.$materiaId&fecha=gte.$fechaInicio&fecha=lte.$fechaFin'),
      headers: headers,
      body: jsonEncode({
        'estado': nuevoEstado,
      }),
    );

    print("Status code updateAsistencia: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('✓ Asistencia actualizada exitosamente');
    } else {
      print('✗ Error al actualizar asistencia: ${response.statusCode} - ${response.body}');
      throw Exception('Error al actualizar asistencia: ${response.body}');
    }
  } catch (e) {
    print('✗ Error en updateAsistencia: $e');
    throw Exception('Error al actualizar la asistencia: $e');
  }
}



}