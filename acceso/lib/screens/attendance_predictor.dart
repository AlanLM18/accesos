import 'dart:math';

/// Red Neuronal simple para predicción de asistencias
/// Implementa un Perceptrón Multicapa (MLP) con backpropagation
class AttendancePredictor {
  // Arquitectura de la red
  final int inputSize;
  final int hiddenSize;
  final int outputSize;
  
  // Pesos y biases
  late List<List<double>> weightsInputHidden;
  late List<double> biasHidden;
  late List<List<double>> weightsHiddenOutput;
  late List<double> biasOutput;
  
  // Tasa de aprendizaje
  final double learningRate;
  
  // Random para inicialización
  final Random _random = Random(42);

  AttendancePredictor({
    this.inputSize = 7,  // Últimos 7 días de asistencia
    this.hiddenSize = 10,
    this.outputSize = 1, // Probabilidad de asistir
    this.learningRate = 0.1,
  }) {
    _initializeWeights();
  }

  /// Inicializa los pesos con valores aleatorios pequeños (Xavier initialization)
  void _initializeWeights() {
    double limitIH = sqrt(6 / (inputSize + hiddenSize));
    double limitHO = sqrt(6 / (hiddenSize + outputSize));

    // Pesos input -> hidden
    weightsInputHidden = List.generate(
      inputSize,
      (_) => List.generate(
        hiddenSize,
        (_) => (_random.nextDouble() * 2 - 1) * limitIH,
      ),
    );

    // Bias hidden
    biasHidden = List.generate(hiddenSize, (_) => 0.0);

    // Pesos hidden -> output
    weightsHiddenOutput = List.generate(
      hiddenSize,
      (_) => List.generate(
        outputSize,
        (_) => (_random.nextDouble() * 2 - 1) * limitHO,
      ),
    );

    // Bias output
    biasOutput = List.generate(outputSize, (_) => 0.0);
  }

  /// Función de activación Sigmoid
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x.clamp(-500, 500)));
  }

  /// Derivada de sigmoid
  double _sigmoidDerivative(double x) {
    return x * (1.0 - x);
  }

  /// Función de activación ReLU
  double _relu(double x) {
    return x > 0 ? x : 0.0;
  }

  /// Derivada de ReLU
  double _reluDerivative(double x) {
    return x > 0 ? 1.0 : 0.0;
  }

  /// Forward pass - propaga la entrada a través de la red
  Map<String, dynamic> _forward(List<double> input) {
    // Capa oculta
    List<double> hiddenInput = List.generate(hiddenSize, (j) {
      double sum = biasHidden[j];
      for (int i = 0; i < inputSize; i++) {
        sum += input[i] * weightsInputHidden[i][j];
      }
      return sum;
    });

    List<double> hiddenOutput = hiddenInput.map(_relu).toList();

    // Capa de salida
    List<double> outputInput = List.generate(outputSize, (k) {
      double sum = biasOutput[k];
      for (int j = 0; j < hiddenSize; j++) {
        sum += hiddenOutput[j] * weightsHiddenOutput[j][k];
      }
      return sum;
    });

    List<double> output = outputInput.map(_sigmoid).toList();

    return {
      'hiddenInput': hiddenInput,
      'hiddenOutput': hiddenOutput,
      'outputInput': outputInput,
      'output': output,
    };
  }

  /// Entrena la red con un conjunto de datos
  double train(List<List<double>> inputs, List<double> targets, {int epochs = 100}) {
    double totalError = 0;

    for (int epoch = 0; epoch < epochs; epoch++) {
      totalError = 0;

      for (int sample = 0; sample < inputs.length; sample++) {
        List<double> input = inputs[sample];
        double target = targets[sample];

        // Forward pass
        var forward = _forward(input);
        List<double> hiddenOutput = forward['hiddenOutput'];
        List<double> hiddenInput = forward['hiddenInput'];
        List<double> output = forward['output'];

        // Calcular error
        double error = target - output[0];
        totalError += error * error;

        // Backpropagation
        // Error en la capa de salida
        double outputDelta = error * _sigmoidDerivative(output[0]);

        // Error en la capa oculta
        List<double> hiddenDelta = List.generate(hiddenSize, (j) {
          double sum = outputDelta * weightsHiddenOutput[j][0];
          return sum * _reluDerivative(hiddenOutput[j]);
        });

        // Actualizar pesos hidden -> output
        for (int j = 0; j < hiddenSize; j++) {
          weightsHiddenOutput[j][0] += learningRate * outputDelta * hiddenOutput[j];
        }
        biasOutput[0] += learningRate * outputDelta;

        // Actualizar pesos input -> hidden
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

    return totalError / inputs.length; // MSE
  }

  /// Predice la probabilidad de asistencia
  double predict(List<double> input) {
    var forward = _forward(input);
    return forward['output'][0];
  }

  /// Convierte el historial de asistencias a formato de entrada
  static List<double> prepareInput(List<String> asistencias) {
    List<double> input = [];
    
    // Tomar los últimos 7 registros (o rellenar con 0.5 si hay menos)
    int startIndex = asistencias.length > 7 ? asistencias.length - 7 : 0;
    
    // Rellenar con valores neutrales si hay menos de 7 registros
    for (int i = 0; i < 7 - (asistencias.length - startIndex); i++) {
      input.add(0.5); // Valor neutral
    }
    
    // Agregar los registros disponibles
    for (int i = startIndex; i < asistencias.length; i++) {
      String estado = asistencias[i].toLowerCase();
      if (estado == 'presente') {
        input.add(1.0);
      } else if (estado == 'falta') {
        input.add(0.0);
      } else {
        input.add(0.5); // Sin registro
      }
    }
    
    return input;
  }

  /// Prepara datos de entrenamiento a partir del historial
  static Map<String, dynamic> prepareTrainingData(List<String> asistencias) {
    List<List<double>> inputs = [];
    List<double> targets = [];
    
    // Necesitamos al menos 8 registros para entrenar (7 input + 1 target)
    if (asistencias.length < 8) {
      return {'inputs': inputs, 'targets': targets};
    }
    
    // Crear ventanas deslizantes
    for (int i = 0; i <= asistencias.length - 8; i++) {
      List<double> input = [];
      
      // 7 días de entrada
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
      
      // Target: día 8
      String targetEstado = asistencias[i + 7].toLowerCase();
      double target = targetEstado == 'presente' ? 1.0 : 0.0;
      
      inputs.add(input);
      targets.add(target);
    }
    
    return {'inputs': inputs, 'targets': targets};
  }
}

/// Clase para análisis estadístico de asistencias
class AttendanceAnalytics {
  final List<String> asistencias;
  final List<String> fechas;

  AttendanceAnalytics({
    required this.asistencias,
    required this.fechas,
  });

  /// Calcula el porcentaje de asistencia
  double get porcentajeAsistencia {
    if (asistencias.isEmpty) return 0;
    int presentes = asistencias.where((a) => a.toLowerCase() == 'presente').length;
    return (presentes / asistencias.length) * 100;
  }

  /// Cuenta total de asistencias
  int get totalPresentes {
    return asistencias.where((a) => a.toLowerCase() == 'presente').length;
  }

  /// Cuenta total de faltas
  int get totalFaltas {
    return asistencias.where((a) => a.toLowerCase() == 'falta').length;
  }

  /// Calcula la racha actual (positiva = presentes consecutivos, negativa = faltas)
  int get rachaActual {
    if (asistencias.isEmpty) return 0;
    
    int racha = 0;
    String ultimoEstado = asistencias.last.toLowerCase();
    
    for (int i = asistencias.length - 1; i >= 0; i--) {
      if (asistencias[i].toLowerCase() == ultimoEstado) {
        racha++;
      } else {
        break;
      }
    }
    
    return ultimoEstado == 'presente' ? racha : -racha;
  }

  /// Calcula la mejor racha de asistencias
  int get mejorRacha {
    if (asistencias.isEmpty) return 0;
    
    int mejorRacha = 0;
    int rachaActual = 0;
    
    for (String asistencia in asistencias) {
      if (asistencia.toLowerCase() == 'presente') {
        rachaActual++;
        if (rachaActual > mejorRacha) mejorRacha = rachaActual;
      } else {
        rachaActual = 0;
      }
    }
    
    return mejorRacha;
  }

  /// Analiza patrones por día de la semana
  Map<String, double> get patronSemanal {
    Map<String, int> totalPorDia = {};
    Map<String, int> presentesPorDia = {};
    
    for (int i = 0; i < asistencias.length && i < fechas.length; i++) {
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
    
    Map<String, double> patron = {};
    totalPorDia.forEach((dia, total) {
      patron[dia] = ((presentesPorDia[dia] ?? 0) / total) * 100;
    });
    
    return patron;
  }

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

  /// Tendencia de las últimas semanas
  String get tendencia {
    if (asistencias.length < 14) return 'Sin suficientes datos';
    
    int mitad = asistencias.length ~/ 2;
    
    int presentesPrimera = asistencias.sublist(0, mitad)
        .where((a) => a.toLowerCase() == 'presente').length;
    int presentesSegunda = asistencias.sublist(mitad)
        .where((a) => a.toLowerCase() == 'presente').length;
    
    double porcentajePrimera = presentesPrimera / mitad;
    double porcentajeSegunda = presentesSegunda / (asistencias.length - mitad);
    
    double diferencia = porcentajeSegunda - porcentajePrimera;
    
    if (diferencia > 0.1) {
      return 'Mejorando ↑';
    } else if (diferencia < -0.1) {
      return 'Empeorando ↓';
    } else {
      return 'Estable →';
    }
  }
}