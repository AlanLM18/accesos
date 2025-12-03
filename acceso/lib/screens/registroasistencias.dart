import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AttendanceRegistryScreen(),
    );
  }
}

class AttendanceRegistryScreen extends StatelessWidget {
  const AttendanceRegistryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              // Imagen de fondo
              Container(
                height: 240,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              // Overlay azul
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF004C8C).withOpacity(0.9),
                      const Color(0xFF004C8C).withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              // Logo
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'CONTROL+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Contenido principal
          Expanded(
            child: Container(
              color: const Color(0xFFE8E8E8),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro diario de asistencias',
                    style: TextStyle(
                      color: Color(0xFF004C8C),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '4 de septiembre 2025',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Lista de asistencias
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView(
                        children: [
                          _buildAttendanceItem(
                            'Ana López',
                            true,
                          ),
                          const SizedBox(height: 16),
                          _buildAttendanceItem(
                            'Pedro Gómez',
                            true,
                          ),
                          const SizedBox(height: 16),
                          _buildAttendanceItem(
                            'María Rodárguez',
                            true,
                          ),
                          const SizedBox(height: 16),
                          _buildAttendanceItem(
                            'Luis Fernández',
                            false,
                          ),
                          const SizedBox(height: 16),
                          _buildAttendanceItem(
                            'Sofía Díaz',
                            false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String name, bool isPresent) {
    return Row(
      children: [
        // Avatar circular
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF004C8C),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Nombre
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Color(0xFF004C8C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Badge de estado
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isPresent 
                ? const Color(0xFF4CAF50) 
                : const Color(0xFFE57373),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isPresent ? 'Presente' : 'Ausente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}