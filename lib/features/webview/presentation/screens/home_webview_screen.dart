import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pijama_surf_app/core/utils/constants.dart';

//Única pantalla del MVP.

//Orquesta la WebView y la UI básica (AppBar, loading, banner offline).

//Punto de entrada de navegación (no hay más rutas en el MVP).

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});

  @override
  State<WebviewScreen> createState() {
    return _WebviewScreen();
  }
}

class _WebviewScreen extends State<WebviewScreen> {
  late final WebViewController _controller;
  bool isLoading = false; //esta variable indica si la página web está cargando o no.

  @override
  void initState() {
    // se usa unit state porque se necesita que el controlador de webview sea creadon y haga la peticion https antes de renderizar
    super.initState();
    _controller =
        WebViewController() // controlador principal del webview
          ..setJavaScriptMode(
            JavaScriptMode.unrestricted,
          ) // permite que flutter use javascript para mostrar y actualizar conteido de web PS
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                setState(() {
                  isLoading = true;
                });
              },
              onPageFinished: (url) {
                setState(() {
                  isLoading = false;
                });
              },
              onWebResourceError: (error) {
                print("Error al cargar la página: ${error.description}");
              },
              // Forzar https cuando el enlace venga en http (solo dominios permitidos)
              onNavigationRequest: (request) {
                final uri = Uri.parse(request.url);
                final host = uri.host.toLowerCase();
                final isHttp = uri.scheme == 'http';

                final isAllowedHost =
                    allowedHosts.contains(host) ||
                    host.endsWith('.pijamasurf.com');

                if (isHttp && isAllowedHost) {
                  final httpsUri = uri.replace(scheme: 'https');
                  _controller.loadRequest(httpsUri); // cargar versión segura
                  return NavigationDecision.prevent; // bloquear la http original
                }

                return NavigationDecision.navigate; // permitir lo demás
              },
            ),
          )..loadRequest(Uri.parse(baseUrl)); // carga la pagina principal de pijama surf en el webview
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pijama Surf'), 
      actions: [
        IconButton(
          onPressed: () {
            _controller.reload();
          } , 
          icon: 
          Icon(
            Icons.refresh,
          ),
          tooltip: 'Regargar',
        )
      ],
    ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading) //segunda capa del stack, se viasualiza encima del webviewwidget, condicional para mostrae el circularprogressindicator, dependiendo si la pagina esta o no cargando
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
