import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pijama_surf_app/core/utils/constants.dart';
import 'package:pijama_surf_app/core/services/external_link_service.dart';
// Si tienes un diálogo de confirmación propio, descomenta el import de aba

/// Única pantalla del MVP.
/// Orquesta la WebView y la UI básica (AppBar, loading, progreso superior, manejo de enlaces externos).
class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});

  @override
  State<WebviewScreen> createState() => _WebviewScreen();
}

class _WebviewScreen extends State<WebviewScreen> {
  late final WebViewController _controller;

  // --- Estados de carga/progreso ---
  bool isLoading = false;
  int _progress = 0;

  // --- Estados de navegación (historial) para habilitar/deshabilitar botones ---
  bool _canGoBack = false;
  bool _canGoForward = false;

  /// Helper que consulta al WebView si puede ir atrás/adelante y actualiza la UI.
  Future<void> _updateNavigationState() async {
    try {
      final back = await _controller.canGoBack();
      final fwd = await _controller.canGoForward();
      if (!mounted) return;
      setState(() {
        _canGoBack = back;
        _canGoForward = fwd;
      });
    } catch (_) {
      // Silenciar errores transitorios durante cambios rápidos de página.
    }
  }


  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..addJavaScriptChannel(
        'PSExternal', // nombre del canal JS
        onMessageReceived: (JavaScriptMessage msg) async {
          final url = msg.message;
          // Abre SIEMPRE fuera con tu servicio (intent, youtube, http externo, etc.)
          final uri = Uri.tryParse(url);
          if (uri != null) {
            await ExternalLinkService.openExternalLink(uri);
          }
        },
      )
      // Importante para que Pijama Surf renderice correctamente (usa bastante JS).
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Actualiza el progreso [0..100] para la barra superior.
          onProgress: (value) => setState(() => _progress = value),

          // Comienza carga: activa overlay + (opcional) limpia flags de error.
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
            _updateNavigationState();
          },

          // Finaliza carga: apaga overlay, fija progreso a 100 e inyecta JS.
          onPageFinished: (url) async {
            setState(() {
              isLoading = false;
              _progress = 100;
            });
            _updateNavigationState();

            // --- INYECCIÓN JS PARA MANEJAR target=_blank y window.open ---
            const jsInjection = r"""
              (function() {
                try {
                  if (window.__ps_injected__) return;
                  window.__ps_injected__ = true;

                  // Hook a window.open
                  (function() {
                    const originalOpen = window.open;
                    window.open = function(url, name, specs) {
                      if (url) {
                        try { PSExternal.postMessage(url.toString()); } catch(e) {}
                        return null;
                      }
                      return originalOpen && originalOpen.apply(window, arguments);
                    };
                  })();

                  function handleAnchorClick(e) {
                    const a = e.currentTarget;
                    if (!a) return;
                    var href = a.getAttribute('href');
                    if (!href) return;
                    try { href = new URL(href, window.location.href).toString(); } catch (err) {}
                    try {
                      PSExternal.postMessage(href);
                      e.preventDefault();
                      e.stopPropagation();
                      return false;
                    } catch (err) {}
                  }

                  function patchAnchors(root) {
                    const anchors = (root || document).querySelectorAll('a[target="_blank"], a[rel*="external"], a[data-external="true"]');
                    for (let i = 0; i < anchors.length; i++) {
                      const a = anchors[i];
                      if (!a.__ps_click_bound__) {
                        a.addEventListener('click', handleAnchorClick, true);
                        a.__ps_click_bound__ = true;
                      }
                    }
                  }

                  patchAnchors(document);

                  const observer = new MutationObserver(function(mutations) {
                    for (let i = 0; i < mutations.length; i++) {
                      const m = mutations[i];
                      if (m.addedNodes && m.addedNodes.length > 0) {
                        for (let j = 0; j < m.addedNodes.length; j++) {
                          const node = m.addedNodes[j];
                          if (node.nodeType === 1) {
                            patchAnchors(node);
                          }
                        }
                      }
                    }
                  });
                  observer.observe(document.documentElement, { childList: true, subtree: true });
                } catch (e) {
                  // Silenciar para no romper la página
                }
              })();
            """;

            try {
              await _controller.runJavaScript(jsInjection);
            } catch (e) {
              debugPrint('[WebView] JS injection failed: $e');
            }
          },

          // Errores de recursos/página: apagamos overlay y progreso.
          onWebResourceError: (error) {
            setState(() {
              isLoading = false;
              _progress = 0;
            });
            _updateNavigationState();
          },

          // Intercepta TODA navegación iniciada por el usuario o por la página
          // para: (1) forzar https en dominios permitidos,
          //       (2) abrir fuera todo lo no permitido o no http/https (intent, vnd.youtube, etc.).
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);
            final scheme = uri.scheme.toLowerCase();
            final host = uri.host.toLowerCase();

            // ¿Es un host que permitimos dentro del WebView?
            final isAllowedHost =
                allowedHosts.contains(host) || host.endsWith('.pijamasurf.com');

            // (1) Si es http en un host permitido → forzar a https para evitar net::ERR_CLEARTEXT_NOT_PERMITTED
            if (scheme == 'http' && isAllowedHost) {
              final httpsUri = uri.replace(scheme: 'https');
              await _controller.loadRequest(httpsUri);
              return NavigationDecision.prevent;
            }

            // (2) Si NO es http/https (ej: intent://, vnd.youtube://) → abrir fuera
            if (scheme != 'http' && scheme != 'https') {
              // (Opcional) Diálogo de confirmación:
              // final confirm = await showExternalLinkDialog(context, uri);
              // if (!confirm) return NavigationDecision.prevent;

              await ExternalLinkService.openExternalLink(uri);
              return NavigationDecision.prevent;
            }

            // (3) Si es http/https PERO el host NO es permitido → abrir fuera
            if (!isAllowedHost) {
              // (Opcional) Diálogo de confirmación:
              // final confirm = await showExternalLinkDialog(context, uri);
              // if (!confirm) return NavigationDecision.prevent;

              await ExternalLinkService.openExternalLink(uri);
              return NavigationDecision.prevent;
            }

            // (4) Si pasa todas las validaciones → permitir navegación interna
            return NavigationDecision.navigate;
          },
        ),
      )
      // URL base de Pijama Surf (definida en constants.dart)
      ..loadRequest(Uri.parse(baseUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope (
      // maneja el boton atras de los dispositivos android. cuando no hay historial para regresar, el boton atras cierra la app
      canPop: !_canGoBack,
      onPopInvokedWithResult: (bool didPop, Object ? result) async { 
        if(didPop) {
          return ;
        } else {
          if( didPop == false && await _controller.canGoBack()) {
             await _controller.goBack();
            
          }
          
        }
      } ,
      child: Scaffold(
        // AppBar con navegación tipo navegador: Atrás/Adelante/Recargar
        appBar: AppBar(
          title: const Text('Pijama Surf'),
          // Botón "Atrás" a la izquierda
          leading: 
          IconButton(
            tooltip: 'Atrás',
            icon: const Icon(Icons.arrow_back),
            onPressed: _canGoBack
                ? () async {
                    await _controller.goBack();
                  }
                : null,
          ),
          actions: [
            // Botón "Adelante"
            IconButton(
              tooltip: 'Adelante',
              icon: const Icon(Icons.arrow_forward),
              onPressed: _canGoForward
                  ? () async {
                      await _controller.goForward();
                    }
                  : null,
            ),
            // Botón "Recargar" (se deshabilita mientras carga)
            IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        _progress = 0; // feedback inmediato (opcional)
                        isLoading = true;
                      });
                      await _controller.reload();
                    },
            ),
          ],
        ),
      
        // Capa principal: WebView + progreso + overlay de carga
        body: SafeArea(
          child: Stack(
            children: [
              // Contenido web
              WebViewWidget(controller: _controller),
      
              // Barra de progreso superior (solo visible entre 1% y 99%)
              if (_progress > 0 && _progress < 100)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(value: _progress / 100),
                ),
      
              // Overlay de carga
              if (isLoading)
                Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
