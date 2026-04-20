import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

// funciones para manejo de imagenes - WEB ONLY
class FilesManager {
  // Función para obtener el directorio local
  static Future<String> getLocalPath() async {
    final directory = await getLocalWebPath();
    return directory;
  }

  /// No utiliza path provider porque estamos en web
  static Future<String> getLocalWebPath() async {
    // For web platforms, we don't have direct file system access
    // Return a consistent identifier for web storage
    return 'web_storage';
  }

  // Función para obtener el nombre de la imagen tomada por la camara
  static String getNameOfFile(String imagePath) {
    String filename = basename(imagePath);
    return filename;
  }

  // Función para eliminar un archivo (Web uses localStorage/indexedDB)
  static Future<bool> deleteFile(String imagePath) async {
    try {
      final fileName = getNameOfFile(imagePath);
      web.window.localStorage.removeItem('file_$fileName');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return false;
    }
  }

  // Funcion para comprimir un archivo de Imagen
  // static Future<XFile> compressImageFile(String imagePath) async {
  //   try {
  //     final compressedBytes = await FlutterImageCompress.compressWithFile(
  //       imagePath,
  //       quality: 10,
  //     );
  //     return XFile(imagePath, bytes: compressedBytes);
  //   } on Exception {
  //     return XFile(imagePath);
  //   }
  // }

  // Función para descargar archivo en web
  static Future<bool> downloadFile(String fileName, Uint8List bytes) async {
    try {
      // Crear blob con los bytes - usar JSArray para la conversión
      final jsArray = bytes.toJS;
      final parts = [jsArray].toJS;
      final blob = web.Blob(parts);
      final url = web.URL.createObjectURL(blob);

      // Crear elemento anchor para descarga
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.style.display = 'none';
      anchor.download = fileName;

      // Agregar al DOM, hacer click y limpiar
      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);
      web.URL.revokeObjectURL(url);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return false;
    }
  }

  // Función para guardar una imagen en web
  static Future<bool> saveImageFile(String imagePath) async {
    try {
      // if (comprimir) comprimida = await compressImageFile(imagePath);

      final fileName = getNameOfFile(imagePath);

      // En web, guardamos en localStorage o descargamos
      final bytes = await (XFile(imagePath).readAsBytes());
      await downloadFile(fileName, bytes);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return false;
    }
  }

  // Función para guardar datos en localStorage
  static Future<bool> saveToLocalStorage(String key, String data) async {
    try {
      web.window.localStorage.setItem(key, data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return false;
    }
  }

  // Función para leer datos de localStorage
  static String? readFromLocalStorage(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return null;
    }
  }

  /// fileName debe contener la extensión del archivo.
  /// coleccion es el nombre de la carpeta donde se guardará el archivo.
  /// En web, usamos IndexedDB o localStorage para simular el sistema de archivos
  static Future saveAsFile(
      {required String fileName,
      required List<int> bytes,
      required String coleccion}) async {
    try {
      // En web, podemos usar IndexedDB para almacenamiento más complejo
      // o simplemente descargar el archivo
      await downloadFile(fileName, Uint8List.fromList(bytes));

      // Alternativamente, guardar referencia en localStorage
      final key = '${coleccion}_$fileName';
      final base64Data = web.window.btoa(String.fromCharCodes(bytes));
      web.window.localStorage.setItem(key, base64Data);
    } catch (e) {
      rethrow;
    }
  }

  // Función para obtener archivos de una colección (simulado con localStorage)
  static Future<List<String>> getFilesFromCollection(String coleccion) async {
    try {
      final files = <String>[];
      final storage = web.window.localStorage;
      final length = storage.length;

      for (var i = 0; i < length; i++) {
        final key = storage.key(i);
        if (key != null && key.startsWith('${coleccion}_')) {
          files.add(key.substring(coleccion.length + 1));
        }
      }

      return files;
    } catch (e) {
      return [];
    }
  }

  // Función para obtener un archivo de localStorage
  static Future<Uint8List?> getFileFromStorage(String coleccion, String fileName) async {
    try {
      final key = '${coleccion}_$fileName';
      final base64Data = web.window.localStorage.getItem(key);

      if (base64Data != null) {
        final decodedString = web.window.atob(base64Data);
        return Uint8List.fromList(decodedString.codeUnits);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return null;
    }
  }
}
