import 'package:flutter/material.dart'; 
import 'package:pijama_surf_app/features/webview/presentation/screens/home_webview_screen.dart'; // Importa tu archivo app.dart

void main() {
  runApp( 
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WebviewScreen()
    ),
   );
}
