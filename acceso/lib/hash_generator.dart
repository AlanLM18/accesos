import 'package:bcrypt/bcrypt.dart';

void main() {
  // Cambia esta contraseña por la que quieras usar
  String password = 'Admin123!@#';
  
  // Generar el hash
  String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
  
  print('=================================');
  print('Contraseña original: $password');
  print('Hash bcrypt: $hashedPassword');
  print('=================================');
  print('\nCopia este SQL y ejecútalo en Supabase:\n');
  print('''
INSERT INTO users (nombre, correo, password, rol, matricula, activo, creado_en)
VALUES (
  'Administrador Principal',
  'admin@uteq.edu.mx',
  '$hashedPassword',
  'Admin',
  'ADMIN001',
  1,
  NOW()
);
  ''');
}