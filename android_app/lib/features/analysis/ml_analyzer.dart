import 'dart:math';
import '../../models/verdict.dart';
import 'feature_extractor.dart';
import 'ml_weights.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MlResult {
  final Verdict verdict;
  final Map<String, double> probabilities;
  final String details;
  final bool usedTflite;

  const MlResult({
    required this.verdict,
    required this.probabilities,
    required this.details,
    required this.usedTflite,
  });
}

class MlAnalyzer {
  static Interpreter? _interpreter;
  static bool _tfliteAvailable = false;

  static Future<void> initialize() async {
    if (_tfliteAvailable) return;
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      _tfliteAvailable = true;
    } catch (_) {
      _tfliteAvailable = false;
    }
  }

  static MlResult analyze(String url) {
    final features = UrlFeatureExtractor.extract(url);
    if (_tfliteAvailable && _interpreter != null) {
      return _runTflite(features);
    }
    return _runPureDart(features);
  }

  static MlResult _runTflite(List<double> features) {
    try {
      final input = [features];
      final output = List.generate(1, (_) => List.filled(3, 0.0));
      _interpreter!.run(input, output);
      return _buildResult(output[0], usedTflite: true);
    } catch (_) {
      return _runPureDart(features);
    }
  }

  static MlResult _runPureDart(List<double> features) {
    final scaled = List<double>.generate(
      features.length,
      (i) => (features[i] - MlWeights.scalerMean[i]) / MlWeights.scalerScale[i],
    );

    final scores = List<double>.generate(MlWeights.classes.length, (k) {
      double z = MlWeights.intercept[k];
      for (int i = 0; i < scaled.length; i++) {
        z += MlWeights.coef[k][i] * scaled[i];
      }
      return z;
    });

    return _buildResult(_softmax(scores), usedTflite: false);
  }

  static List<double> _softmax(List<double> scores) {
    final maxScore = scores.reduce(max);
    final exps = scores.map((s) => exp(s - maxScore)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  static MlResult _buildResult(List<double> probs, {required bool usedTflite}) {
    final classes = MlWeights.classes;
    int maxIdx = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxIdx]) maxIdx = i;
    }

    final predictedClass = classes[maxIdx];
    final verdict = _verdictFromClass(predictedClass);
    final probMap = {
      for (int i = 0; i < classes.length; i++) classes[i]: probs[i],
    };

    final pct = (probs[maxIdx] * 100).round();
    final engine = usedTflite ? 'TFLite' : 'LogReg';

    return MlResult(
      verdict: verdict,
      probabilities: probMap,
      details: 'ML ($engine): $predictedClass $pct%',
      usedTflite: usedTflite,
    );
  }

  static Verdict _verdictFromClass(String cls) {
    switch (cls) {
      case 'safe':
        return Verdict.safe;
      case 'danger':
        return Verdict.danger;
      case 'suspicious':
        return Verdict.suspicious;
      default:
        return Verdict.unknown;
    }
  }
}
