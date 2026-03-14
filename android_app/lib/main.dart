import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/analysis/ml_analyzer.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.loadWhitelists();
  await MlAnalyzer.initialize();
  runApp(const SecureQRLensApp());
}
