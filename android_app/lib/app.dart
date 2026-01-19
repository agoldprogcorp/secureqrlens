import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/about/about_screen.dart';
import 'features/history/history_provider.dart';
import 'features/history/history_screen.dart';
import 'features/scanner/scanner_controller.dart';
import 'features/scanner/scanner_screen.dart';

class SecureQRLensApp extends StatelessWidget {
  const SecureQRLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
        ChangeNotifierProxyProvider<HistoryProvider, ScannerController>(
          create: (context) => ScannerController(context.read<HistoryProvider>()),
          update: (context, history, previous) =>
              previous ?? ScannerController(history),
        ),
      ],
      child: MaterialApp(
        title: 'Secure QR Lens',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const ScannerScreen(),
        routes: {
          '/history': (context) => const HistoryScreen(),
          '/about': (context) => const AboutScreen(),
        },
      ),
    );
  }
}
