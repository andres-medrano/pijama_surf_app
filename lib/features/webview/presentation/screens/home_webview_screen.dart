import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pijama_surf_app/core/utils/constants.dart';
import 'package:pijama_surf_app/core/services/external_link_service.dart';
import 'package:pijama_surf_app/features/webview/presentation/widgets/external_link_dialog.dart';

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
  int _progress = 0; //contador para barra de progreso
  String? _errorMessage;


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
                  _errorMessage = null;
                  isLoading = true;
                });
              },
              onPageFinished: (url) {
                setState(() {
                  isLoading = false;
                });
              },
              onProgress: (value) {
                setState(() {
                  _progress = value;
                });
              },
              onWebResourceError: (error) {
                setState(() {
                  _progress = 0;
                  isLoading = false;
                  _errorMessage = error.description; //se guarda en la variable errormessage el mensaje del error en cuestion
                });
                debugPrint("Error al cargar la página: ${error.description}");
              },
              // Forzar https cuando el enlace venga en http (solo dominios permitidos)
              onNavigationRequest: (request) async {
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
                else if(allowedHosts.contains(host)) { //verifica si la url a abrir es interna y la abre
                  return NavigationDecision.navigate;
                } else {
                //en caso de que la url sea externa, se hace un llamado a la funcion externallinkservice para abrir enlace externo
                
                final confirm = await showExternalLinkDialog(context, uri); // instancia de la funcion showexternallinkdialog

                if (confirm) { 
                  final externalLinkService = ExternalLinkService();
                  await externalLinkService.openExternalLink(uri);
                  debugPrint('Enlace externo: $uri');
                }
                
                return NavigationDecision.prevent;
                }
                
              },
            ),
          )..loadRequest(Uri.parse(baseUrl)); // carga la pagina principal de pijama surf en el webview
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pijama Surf'), 
      actions: [
        IconButton(
          onPressed: () {
            _controller.reload();
          } , 
          icon: 
          const Icon(
            Icons.refresh,
          ),
          tooltip: 'Recargar',
        )
      ],
    ),
      body: SafeArea(
        child: Stack(
          children: [
            
            WebViewWidget(controller: _controller),


            if(_errorMessage != null) // mostrar mensaje de error en caso de problema con conexion
              Center(
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Color.fromARGB(255, 6, 4, 4),),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar la pagina.\n${_errorMessage!}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: const Color.fromARGB(255, 6, 4, 4)),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _controller.reload();
                        });
                      }, 
                      child: const Text('Reintentar'),
                      ),
                  ]
                  
                ),
              ),

            if (isLoading) //segunda capa del stack, se viasualiza encima del webviewwidget, condicional para mostrae el circularprogressindicator, dependiendo si la pagina esta o no cargando
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: Center(child: CircularProgressIndicator(),
                ),
              ),

            if(_progress > 0  &&  _progress < 100) // barra de progreso al cargar una pagina internamente
               Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(value: _progress / 100),
                
            ),
          ],
        ),
      ),
    );
  }
}
