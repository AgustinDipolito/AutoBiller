import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

/// Servicio para gestionar imágenes en Firebase Storage
/// Maneja subida, descarga y eliminación de imágenes de productos
class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  static const String _productosFolder = 'productos';
  static const int _maxImageSizeBytes = 1024 * 1024; // 1MB

  /// Verificar si Firebase Storage está disponible
  bool get isAvailable => _firebaseService.isInitialized;

  /// Subir imagen de producto a Firebase Storage
  /// Retorna la URL de descarga o null si falla
  Future<String?> uploadProductImage(String productId, File imageFile) async {
    if (!isAvailable) {
      debugPrint('❌ Firebase Storage no disponible - Firebase no inicializado');
      return null;
    }

    try {
      // Validar tamaño del archivo
      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSizeBytes) {
        debugPrint('❌ Imagen demasiado grande: ${fileSize / 1024}KB (máx 1MB)');
        return null;
      }

      // Crear referencia única: productos/{productId}/imagen.jpg
      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = 'imagen$extension';
      final ref = FirebaseStorage.instance
          .ref()
          .child(_productosFolder)
          .child(productId)
          .child(fileName);

      debugPrint('📤 Subiendo imagen: $_productosFolder/$productId/$fileName');

      // Subir archivo con metadatos
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'productId': productId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Esperar a que termine la subida
      final snapshot = await uploadTask;

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Subir imagen de producto desde bytes (compatible con Web)
  /// Retorna la URL de descarga o null si falla
  Future<String?> uploadProductImageBytes(
    String productId,
    Uint8List imageBytes, {
    String extension = '.jpg',
  }) async {
    if (!isAvailable) {
      debugPrint('❌ Firebase Storage no disponible - Firebase no inicializado');
      return null;
    }

    try {
      final normalizedExtension = extension.startsWith('.')
          ? extension.toLowerCase()
          : '.${extension.toLowerCase()}';

      if (imageBytes.length > _maxImageSizeBytes) {
        debugPrint('❌ Imagen demasiado grande: ${imageBytes.length / 1024}KB (máx 1MB)');
        return null;
      }

      final fileName = 'imagen$normalizedExtension';
      final ref = FirebaseStorage.instance
          .ref()
          .child(_productosFolder)
          .child(productId)
          .child(fileName);

      debugPrint('📤 Subiendo imagen por bytes: $_productosFolder/$productId/$fileName');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: _getContentType(normalizedExtension),
          customMetadata: {
            'productId': productId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error al subir imagen por bytes: $e');
      return null;
    }
  }

  /// Eliminar imagen de producto desde Firebase Storage
  /// Retorna true si se eliminó exitosamente o no existía
  Future<bool> deleteProductImage(String productId) async {
    if (!isAvailable) {
      debugPrint('⚠️ Firebase Storage no disponible - imagen no eliminada');
      return true; // No es error crítico si no está disponible
    }

    try {
      // Intentar eliminar todos los formatos posibles
      final extensions = ['.jpg', '.jpeg', '.png', '.webp'];

      for (final ext in extensions) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child(_productosFolder)
              .child(productId)
              .child('imagen$ext');

          await ref.delete();
          debugPrint('✅ Imagen eliminada: $_productosFolder/$productId/imagen$ext');
        } catch (e) {
          // Ignorar error si el archivo no existe
          if (!e.toString().contains('object-not-found')) {
            debugPrint('⚠️ Error eliminando imagen$ext: $e');
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Eliminar imagen antigua y subir nueva (operación atómica)
  Future<String?> replaceProductImage(String productId, File newImageFile) async {
    try {
      // Primero subir la nueva imagen
      final newUrl = await uploadProductImage(productId, newImageFile);

      if (newUrl == null) {
        debugPrint('❌ No se pudo subir la nueva imagen');
        return null;
      }

      // Si la subida fue exitosa, la nueva imagen sobrescribió la anterior
      // (Firebase Storage sobrescribe automáticamente archivos con el mismo path)
      debugPrint('✅ Imagen reemplazada exitosamente');
      return newUrl;
    } catch (e) {
      debugPrint('❌ Error al reemplazar imagen: $e');
      return null;
    }
  }

  /// Obtener URL de descarga de imagen existente (sin subirla)
  Future<String?> getProductImageUrl(String productId) async {
    if (!isAvailable) {
      return null;
    }

    try {
      // Intentar con diferentes extensiones
      final extensions = ['.jpg', '.jpeg', '.png', '.webp'];

      for (final ext in extensions) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child(_productosFolder)
              .child(productId)
              .child('imagen$ext');

          final url = await ref.getDownloadURL();
          return url;
        } catch (e) {
          // Continuar con siguiente extensión
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error al obtener URL de imagen: $e');
      return null;
    }
  }

  /// Verificar si existe una imagen para el producto
  Future<bool> hasProductImage(String productId) async {
    final url = await getProductImageUrl(productId);
    return url != null;
  }

  /// Obtener tipo de contenido según extensión
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Obtener tamaño máximo permitido en MB
  double get maxImageSizeMB => _maxImageSizeBytes / (1024 * 1024);
}
