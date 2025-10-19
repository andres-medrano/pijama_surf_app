import 'package:flutter/material.dart';

// widget de servicio que muestra un dialogo antes de abrir enlace externo
Future<bool> showExternalLinkDialog(BuildContext context, Uri uri) async {
  final message =
      'Vas a salir de Pijama Surf para abrir: ${uri.host}. ¿Deseas continuar?';

  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Abrir enlace externo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir'),
          ),
        ],
      );
    },
  );

  // Si el usuario cierra el diálogo sin elegir (toca fuera), result será null.
  return result ?? false;
}