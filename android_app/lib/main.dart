import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загрузка whitelist'ов из assets
  await AppConstants.loadWhitelists();
  
  runApp(const SecureQRLensApp());
}
