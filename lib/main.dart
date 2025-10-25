import 'package:flutter/material.dart'; 
import 'package:pijama_surf_app/features/webview/presentation/screens/home_webview_screen.dart'; // Importa tu archivo app.dart
import 'package:pijama_surf_app/core/utils/theme.dart';

void main() {
  runApp( 
    MaterialApp(
      theme: AppTheme.lightTheme, // aplica el tema global
      darkTheme: AppTheme.darkTheme, // modo oscuro
      themeMode: ThemeMode.system, //la app toma el tema del sistema
      debugShowCheckedModeBanner: false, //muestra banner de debug cuando app corre en modod debug
      home: const WebviewScreen()
    ),
   );
}
