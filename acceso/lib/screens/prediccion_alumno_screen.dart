import 'package:flutter/material.dart';
import 'dart:math';
import '../service/api_service.dart';

/// Red Neuronal simple para predicción de asistencias
class AttendancePredictor {
  final int inputSize;
  final int hiddenSize;
  final int outputSize;
  
  late List<List<double>> weightsInputHidden;
  late List<double> biasHidden;
  late List<List<double>> weightsHiddenOutput;
  late List<double> biasOutput;
  
  final double learningRate;
  final Random _random = Random(42);

  AttendancePredictor({
    this.inputSize = 7,
    this.hiddenSize = 10,
    this.outputSize = 1,
    this.learningRate = 0.1,
  }) {
    _initializeWeights();
  }

  void _initializeWeights() {
    double limitIH = sqrt(6 / (inputSize + hiddenSize));
    double limitHO = sqrt(6 / (hiddenSize + outputSize));

    weightsInputHidden = List.generate(
      inputSize,
      (_) => List.generate(hiddenSize, (_) => (_random.nextDouble() * 2 - 1) * limitIH),
    );
    biasHidden = List.generate(hiddenSize, (_) => 0.0);
    weightsHiddenOutput = List.generate(
      hiddenSize,
      (_) => List.generate(outputSize, (_) => (_random.nextDouble() * 2 - 1) * limitHO),
    );
    biasOutput = List.generate(outputSize, (_) => 0.0);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x.clamp(-500, 500)));
  double _sigmoidDerivative(double x) => x * (1.0 - x);
  double _relu(double x) => x > 0 ? x : 0.0;
  double _reluDerivative(double x) => x > 0 ? 1.0 : 0.0;

  Map<String, dynamic> _forward(List<double> input) {
    List<double> hiddenInput = List.generate(hiddenSize, (j) {
      double sum = biasHidden[j];
      for (int i = 0; i < inputSize; i++) {
        sum += input[i] * weightsInputHidden[i][j];
      }
      return sum;
    });

    List<double> hiddenOutput = hiddenInput.map(_relu).toList();

    List<double> outputInput = List.generate(outputSize, (k) {
      double sum = biasOutput[k];
      for (int j = 0; j < hiddenSize; j++) {
        sum += hiddenOutput[j] * weightsHiddenOutput[j][k];
      }
      return sum;
    });

    return {
      'hiddenOutput': hiddenOutput,
      'output': outputInput.map(_sigmoid).toList(),
    };
  }

  double train(List<List<double>> inputs, List<double> targets, {int epochs = 100}) {
    double totalError = 0;

    for (int epoch = 0; epoch < epochs; epoch++) {
      totalError = 0;

      for (int sample = 0; sample < inputs.length; sample++) {
        List<double> input = inputs[sample];
        double target = targets[sample];

        var forward = _forward(input);
        List<double> hiddenOutput = forward['hiddenOutput'];
        List<double> output = forward['output'];

        double error = target - output[0];
        totalError += error * error;

        double outputDelta = error * _sigmoidDerivative(output[0]);

        List<double> hiddenDelta = List.generate(hiddenSize, (j) {
          return outputDelta * weightsHiddenOutput[j][0] * _reluDerivative(hiddenOutput[j]);
        });

        for (int j = 0; j < hiddenSize; j++) {
          weightsHiddenOutput[j][0] += learningRate * outputDelta * hiddenOutput[j];
        }
        biasOutput[0] += learningRate * outputDelta;

        for (int i = 0; i < inputSize; i++) {
          for (int j = 0; j < hiddenSize; j++) {
            weightsInputHidden[i][j] += learningRate * hiddenDelta[j] * input[i];
          }
        }
        for (int j = 0; j < hiddenSize; j++) {
          biasHidden[j] += learningRate * hiddenDelta[j];
        }
      }
    }

    return totalError / inputs.length;
  }

  double predict(List<double> input) {
    var forward = _forward(input);
    return forward['output'][0];
  }

  static List<double> prepareInput(List<String> asistencias) {
    List<double> input = [];
    int startIndex = asistencias.length > 7 ? asistencias.length - 7 : 0;
    
    for (int i = 0; i < 7 - (asistencias.length - startIndex); i++) {
      input.add(0.5);
    }
    
    for (int i = startIndex; i < asistencias.length; i++) {
      String estado = asistencias[i].toLowerCase();
      if (estado == 'presente') {
        input.add(1.0);
      } else if (estado == 'falta') {
        input.add(0.0);
      } else {
        input.add(0.5);
      }
    }
    
    return input;
  }

  static Map<String, dynamic> prepareTrainingData(List<String> asistencias) {
    List<List<double>> inputs = [];
    List<double> targets = [];
    
    if (asistencias.length < 8) {
      return {'inputs': inputs, 'targets': targets};
    }
    
    for (int i = 0; i <= asistencias.length - 8; i++) {
      List<double> input = [];
      
      for (int j = i; j < i + 7; j++) {
        String estado = asistencias[j].toLowerCase();
        if (estado == 'presente') {
          input.add(1.0);
        } else if (estado == 'falta') {
          input.add(0.0);
        } else {
          input.add(0.5);
        }
      }
      
      String targetEstado = asistencias[i + 7].toLowerCase();
      targets.add(targetEstado == 'presente' ? 1.0 : 0.0);
      inputs.add(input);
    }
    
    return {'inputs': inputs, 'targets': targets};
  }
}

// ============================================================================
// PANTALLA DE PREDICCIÓN SIMPLIFICADA
// ============================================================================

class PrediccionAlumnoScreen extends StatefulWidget {
  final String alumnoId;
  final String nombreAlumno;
  final String matricula;
  final String claseId;

  const PrediccionAlumnoScreen({
    Key? key,
    required this.alumnoId,
    required this.nombreAlumno,
    required this.matricula,
    required this.claseId,
  }) : super(key: key);

  @override
  State<PrediccionAlumnoScreen> createState() => _PrediccionAlumnoScreenState();
}

class _PrediccionAlumnoScreenState extends State<PrediccionAlumnoScreen> {
  final ApiService _apiService = ApiService();
  late AttendancePredictor _predictor;
  
  Map<String, dynamic>? _datosPrediccion;
  bool _isLoadingData = true;
  String? _errorMessage;
  
  double _prediccion = 0.0;
  bool _isCalculating = false;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    _predictor = AttendancePredictor();
    _cargarDatosDelAPI();
  }

  Future<void> _cargarDatosDelAPI() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final datos = await _apiService.getDatosPrediccionAlumno(
        widget.alumnoId, 
        widget.claseId,
      );
      
      if (datos['success'] == true) {
        setState(() {
          _datosPrediccion = datos;
          _isLoadingData = false;
        });
        // Calcular predicción automáticamente
        _calcularPrediccion();
      } else {
        setState(() {
          _errorMessage = datos['message'] ?? 'Error al cargar datos';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _calcularPrediccion() async {
    if (_datosPrediccion == null) return;
    
    setState(() {
      _isCalculating = true;
    });

    try {
      List<String> asistencias = List<String>.from(_datosPrediccion!['asistencias'] ?? []);
      
      var trainingData = AttendancePredictor.prepareTrainingData(asistencias);
      List<List<double>> inputs = trainingData['inputs'];
      List<double> targets = trainingData['targets'];

      if (inputs.isEmpty) {
        // Si no hay suficientes datos, usar el porcentaje de asistencia
        final estadisticas = _datosPrediccion!['estadisticas'];
        final porcentaje = (estadisticas?['porcentajeAsistencia'] ?? 0.0) as double;
        
        setState(() {
          _prediccion = porcentaje / 100;
          _isCalculating = false;
          _hasCalculated = true;
        });
        return;
      }

      // Entrenar la red
      for (int i = 0; i < 10; i++) {
        _predictor.train(inputs, targets, epochs: 50);
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Hacer predicción
      List<double> inputPrediccion = AttendancePredictor.prepareInput(asistencias);
      double prediccion = _predictor.predict(inputPrediccion);

      setState(() {
        _prediccion = prediccion;
        _isCalculating = false;
        _hasCalculated = true;
      });
      
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text(
          'Predicción de Asistencia',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4A9FD8)),
          SizedBox(height: 16),
          Text(
            'Cargando datos...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatosDelAPI,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9FD8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final estadisticas = _datosPrediccion?['estadisticas'] ?? {};
    final patronSemanal = _datosPrediccion?['patronSemanal'] as Map<String, dynamic>? ?? {};
    final fechas = _datosPrediccion?['fechas'] as List? ?? [];
    final asistencias = _datosPrediccion?['asistencias'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del alumno
          _buildAlumnoCard(estadisticas),
          const SizedBox(height: 20),
          
          // Predicción principal
          _buildPrediccionCard(),
          const SizedBox(height: 20),
          
          // Estadísticas
          _buildEstadisticasCard(estadisticas),
          const SizedBox(height: 20),
          
          // Patrón semanal
          if (patronSemanal.isNotEmpty) _buildPatronSemanalCard(patronSemanal),
          if (patronSemanal.isNotEmpty) const SizedBox(height: 20),
          
          // Historial reciente
          if (fechas.isNotEmpty) _buildHistorialCard(fechas, asistencias),
        ],
      ),
    );
  }

  Widget _buildAlumnoCard(Map<String, dynamic> estadisticas) {
    final porcentaje = (estadisticas['porcentajeAsistencia'] ?? 0.0) as double;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2E5A8F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9FD8).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.nombreAlumno.isNotEmpty 
                    ? widget.nombreAlumno[0].toUpperCase() 
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                  widget.nombreAlumno,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matrícula: ${widget.matricula}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getColorPorPorcentaje(porcentaje),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${porcentaje.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrediccionCard() {
    if (_isCalculating) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A44),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF4A9FD8)),
              SizedBox(height: 16),
              Text(
                'Calculando predicción...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasCalculated) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A44),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Cargando...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    Color colorPrediccion = _getColorPorPorcentaje(_prediccion * 100);
    String textoPrediccion = _getTextoPrediccion(_prediccion);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorPrediccion.withOpacity(0.3),
            colorPrediccion.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorPrediccion, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Predicción para mañana',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Círculo de predicción grande
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: _prediccion,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colorPrediccion),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(_prediccion * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: colorPrediccion,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'probabilidad',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Texto de predicción
          Text(
            textoPrediccion,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorPrediccion,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Recomendación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getRecomendacion(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCard(Map<String, dynamic> estadisticas) {
    final totalPresentes = estadisticas['totalPresentes'] ?? 0;
    final totalFaltas = estadisticas['totalFaltas'] ?? 0;
    final totalClases = estadisticas['totalClases'] ?? 0;
    final rachaActual = estadisticas['rachaActual'] ?? 0;
    final mejorRacha = estadisticas['mejorRacha'] ?? 0;
    final tendencia = estadisticas['tendencia'] ?? 'Sin datos';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF4A9FD8), size: 24),
              SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Presentes', totalPresentes.toString(), Colors.green, Icons.check_circle)),
              Expanded(child: _buildStatItem('Faltas', totalFaltas.toString(), Colors.red, Icons.cancel)),
              Expanded(child: _buildStatItem('Total', totalClases.toString(), Colors.blue, Icons.calendar_today)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Racha', _formatRacha(rachaActual), rachaActual >= 0 ? Colors.green : Colors.red, Icons.local_fire_department)),
              Expanded(child: _buildStatItem('Mejor', '$mejorRacha días', Colors.amber, Icons.emoji_events)),
              Expanded(child: _buildStatItem('Tendencia', tendencia, _getTendenciaColor(tendencia), Icons.trending_up)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatronSemanalCard(Map<String, dynamic> patron) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_view_week, color: Color(0xFF4A9FD8), size: 24),
              SizedBox(width: 8),
              Text(
                'Patrón Semanal',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
              .where((dia) => patron.containsKey(dia))
              .map((dia) => _buildDiaBar(dia, (patron[dia] as num).toDouble())),
        ],
      ),
    );
  }

  Widget _buildDiaBar(String dia, double porcentaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(dia, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: porcentaje / 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getColorPorPorcentaje(porcentaje),
                          _getColorPorPorcentaje(porcentaje).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '${porcentaje.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getColorPorPorcentaje(porcentaje),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialCard(List fechas, List asistencias) {
    int totalMostrar = fechas.length > 14 ? 14 : fechas.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF4A9FD8), size: 24),
              SizedBox(width: 8),
              Text(
                'Historial Reciente',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(totalMostrar, (index) {
              int reverseIndex = fechas.length - 1 - index;
              return _buildHistorialItem(
                fechas[reverseIndex].toString(), 
                asistencias[reverseIndex].toString(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialItem(String fecha, String estado) {
    Color color;
    IconData icon;
    
    switch (estado.toLowerCase()) {
      case 'presente':
        color = Colors.green;
        icon = Icons.check;
        break;
      case 'falta':
        color = Colors.red;
        icon = Icons.close;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }

    String fechaFormateada;
    try {
      DateTime date = DateTime.parse(fecha);
      fechaFormateada = '${date.day}/${date.month}';
    } catch (e) {
      fechaFormateada = fecha;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            fechaFormateada,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getColorPorPorcentaje(double porcentaje) {
    if (porcentaje >= 80) return Colors.green;
    if (porcentaje >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getTextoPrediccion(double prediccion) {
    if (prediccion >= 0.8) return 'Muy probable que asista';
    if (prediccion >= 0.6) return 'Probable que asista';
    if (prediccion >= 0.4) return 'Puede asistir o no';
    if (prediccion >= 0.2) return 'Probable que falte';
    return 'Muy probable que falte';
  }

  String _formatRacha(int racha) {
    if (racha == 0) return '0';
    if (racha > 0) return '+$racha';
    return '${racha.abs()} F';
  }

  Color _getTendenciaColor(String tendencia) {
    if (tendencia.contains('↑')) return Colors.green;
    if (tendencia.contains('↓')) return Colors.red;
    return Colors.blue;
  }

  String _getRecomendacion() {
    if (_prediccion >= 0.8) {
      return 'El alumno muestra un patrón consistente de asistencia.';
    } else if (_prediccion >= 0.6) {
      return 'Buena probabilidad de asistir mañana.';
    } else if (_prediccion >= 0.4) {
      return 'Patrón irregular. Se recomienda seguimiento.';
    } else if (_prediccion >= 0.2) {
      return 'Alta probabilidad de inasistencia. Contactar al alumno.';
    } else {
      return 'Patrón de inasistencias frecuentes. Requiere atención.';
    }
  }
}