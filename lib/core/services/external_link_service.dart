
import 'package:flutter/foundation.dart';

import 'package:url_launcher/url_launcher.dart';

//Servicio que abre enlaces externos en el navegador del sistema
class ExternalLinkService {
 
 
  Future<bool> openExternalLink(Uri? uri) async {

    //verificar que la la url no sea nula
    if (uri == null) {
      return false;
    }
    //verificar que la url tenga esquema
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }
    //verificar que la url tenga host
    if (uri.host.isEmpty) {
      return false;
    }
    //verificar con el SO si url puede abrirse
    final can = await canOpen(uri);
    if(!can) {
      debugPrint('no hay app para abrir  este enlace: $uri');
      return false;
    }
    //intento verdadero para abrir enlace de forma externa en app
    try {
     final canLaunchExternal =  await launchUrl(uri, mode: LaunchMode.externalApplication);
      return canLaunchExternal;
    } catch (error) {
      debugPrint('error abriendo enlace: $error');
      return false;

    }

  
  }
}

Future<bool> canOpen(Uri? uri) async {
  //verificar que la la url no sea nula
  if (uri == null) {
    return false;
  }
  //verificar que la url tenga esquema
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return false;
  }
  try {
    //verificar si la url puede ser abierta externamente por un navegador o aplicacion
    final canLaunchResult = await canLaunchUrl(uri); 
    return canLaunchResult;
  } catch (error) {
    debugPrint('error en canOpen: $error');
    return false;
  }
}
