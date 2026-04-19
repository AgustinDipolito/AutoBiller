import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';
import 'package:universal_html/html.dart' as html;

class FileApi {
  /// Guarda un documento PDF
  /// En Android: guarda el archivo y retorna el File
  /// En Web: descarga automáticamente el archivo y retorna un File dummy
  static Future<File> saveDocument({required String name, required Document pdf}) async {
    final bytes = await pdf.save();

    if (kIsWeb) {
      // En Web: descargar el archivo directamente
      _downloadFileWeb(bytes, name);
      // Retornar un File "dummy" para mantener compatibilidad
      // Este File no tiene contenido real en web
      return File(name);
    } else {
      // En Android/iOS: guardar en el sistema de archivos
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  /// Abre un archivo
  /// En Android: abre con la app predeterminada
  /// En Web: no hace nada (el archivo ya se descargó)
  static Future<void> openFile(File file) async {
    if (!kIsWeb) {
      final url = file.path;
      await OpenFilex.open(url);
    }
    // En web, el archivo ya se descargó automáticamente al llamar saveDocument
  }

  /// Crea y guarda un archivo CSV
  /// En Android: guarda y opcionalmente abre el archivo
  /// En Web: descarga el archivo
  static Future<File?>? createCSV<T>(List<T> items, String name,
      {bool open = true}) async {
    try {
      final csv = items.map((e) => e.toString()).join('\n');

      if (kIsWeb) {
        // En Web: descargar el CSV directamente
        final bytes = utf8.encode(csv);
        if (open) {
          _downloadFileWeb(bytes, '$name.csv');
        }
        return File('$name.csv'); // File dummy para compatibilidad
      } else {
        // En Android/iOS: guardar y abrir
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$name.csv');
        await file.writeAsString(csv, encoding: Encoding.getByName('l1')!);
        if (open) await openFile(file);
        return file;
      }
    } catch (e) {
      return null;
    }
  }

  /// Descarga un archivo en navegadores web
  static void _downloadFileWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
