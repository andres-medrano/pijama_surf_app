// lib/core/services/external_link_service.dart
import 'package:url_launcher/url_launcher.dart';


class ExternalLinkService {
  /// Abre un enlace fuera de tu app, intentando la app nativa cuando aplica.
  static Future<void> openExternalLink(Uri uri) async {
    // 1) Normaliza/convierte ciertos esquemas a URLs abribles por apps nativas
    final normalized = _normalizeUri(uri);

    // 2) Intenta abrir como app externa
    if (await canLaunchUrl(normalized)) {
      await launchUrl(
        normalized,
        mode: LaunchMode.externalApplication, // fuerza abrir fuera
      );
      return;
    }

    // 3) Si no hay app, y es http/https → abre en navegador del sistema
    if (normalized.scheme == 'http' || normalized.scheme == 'https') {
      await launchUrl(
        normalized,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // 4) Último recurso: intenta convertir a https si es posible
    final httpsFallback = _toHttpsFallback(normalized);
    if (httpsFallback != null && await canLaunchUrl(httpsFallback)) {
      await launchUrl(httpsFallback, mode: LaunchMode.externalApplication);
    }
  }

  /// Reglas simples para abrir app nativa cuando corresponde.
  static Uri _normalizeUri(Uri uri) {
    final s = uri.scheme.toLowerCase();

    // Casos directos soportados por url_launcher (no toques):
    // tel:, sms:, mailto:, geo: → ya funcionan con launchUrl

    // YouTube intents o esquemas especiales
    if (s == 'vnd.youtube') {
      // vnd.youtube:VIDEO_ID → https://www.youtube.com/watch?v=VIDEO_ID
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (id.isNotEmpty) {
        return Uri.parse('https://www.youtube.com/watch?v=$id');
      }
    }

    // WhatsApp
    if (s == 'whatsapp') {
      // whatsapp://send?text=... → https://wa.me/?text=...
      final text = uri.queryParameters['text'];
      final phone = uri.queryParameters['phone'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.parse('https://wa.me/$phone');
      }
      if (text != null && text.isNotEmpty) {
        return Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      }
      return Uri.parse('https://wa.me/');
    }

    // Google Maps
    if (s == 'geo') {
  // geo:0,0?q=Place → https://www.google.com/maps/search/?api=1&query=Place
  final q = uri.queryParameters['q'] ?? uri.path; // geo:lat,lng o query
  if (q.isNotEmpty) {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
  }
}

    // Android intent://
    if (s == 'intent') {
      final https = _intentToHttps(uri);
      if (https != null) return https;
    }

    // iOS universal links: no hace falta convertir, Safari/OS resuelve
    return uri;
  }

  /// Convierte intent://... a su fallback https si existe.
  static Uri? _intentToHttps(Uri intentUri) {
    // Los intent traen a menudo browser_fallback_url o package/path
    // Ej: intent://watch?v=ID#Intent;scheme=https;package=com.google.android.youtube;S.browser_fallback_url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DID;end
    final raw = intentUri.toString();

    // 1) Busca browser_fallback_url
    final matchFallback = RegExp(r'browser_fallback_url=([^;#]+)')
        .firstMatch(raw);
    if (matchFallback != null) {
      final enc = matchFallback.group(1)!;
      final decoded = Uri.decodeComponent(enc);
      return Uri.tryParse(decoded);
    }

    // 2) Reconstruye a partir de scheme= y path si aplica
    final schemeMatch =
        RegExp(r';scheme=([a-zA-Z][a-zA-Z0-9+.\-]*);').firstMatch(raw);
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!;
      // Extrae la parte antes de #Intent;
      final idx = raw.indexOf('#Intent');
      final path = raw.substring('intent://'.length, idx >= 0 ? idx : raw.length);
      final rebuilt = Uri.parse('$scheme://$path');
      // Si termina siendo http/https, úsalo
      if (rebuilt.scheme == 'http' || rebuilt.scheme == 'https') return rebuilt;
    }

    return null;
  }

  /// Para esquemas no soportados, intenta una versión https del host conocido.
  static Uri? _toHttpsFallback(Uri uri) {
    // Si viene como app-específica (ej: twitter://) conviértelo a web simple:
    // twitter://user?screen_name=foo → https://twitter.com/foo
    if (uri.scheme == 'twitter') {
      final user = uri.queryParameters['screen_name'];
      if (user != null && user.isNotEmpty) {
        return Uri.parse('https://twitter.com/$user');
      }
      return Uri.parse('https://twitter.com/');
    }

    // Último recurso: si tiene host, fuerza https
    if (uri.host.isNotEmpty) {
      return uri.replace(scheme: 'https');
    }
    return null;
  }
}
