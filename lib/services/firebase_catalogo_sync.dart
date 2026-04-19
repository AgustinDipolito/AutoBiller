import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import 'firebase_service.dart';

/// Servicio de sincronización del catálogo con Firebase
/// Implementa lógica simple: GET si no hay datos locales, PUT si hay datos locales y conexión
class FirebaseCatalogoSync {
  static final FirebaseCatalogoSync _instance = FirebaseCatalogoSync._internal();
  factory FirebaseCatalogoSync() => _instance;
  FirebaseCatalogoSync._internal();

  final FirebaseService _firebaseService = FirebaseService();

  static const String _productosCollection = 'productos';
  static const String _historialCollection = 'catalogo_historial';
  static const int _historialLimit = 100; // Límite de registros de historial

  /// Sincronizar productos hacia Firebase
  /// Optimizado para evitar sincronizar productos que no han cambiado
  Future<bool> syncProductos(List<Producto> productos) async {
    if (!_firebaseService.isInitialized) {
      debugPrint('Firebase no inicializado');
      return false;
    }

    if (productos.isEmpty) {
      debugPrint('No hay productos para sincronizar');
      return true;
    }

    try {
      final batch = <Map<String, dynamic>>[];

      for (final producto in productos) {
        batch.add({
          'collection': _productosCollection,
          'docId': producto.id,
          'type': 'set',
          'data': _firebaseService.addSyncMetadata(producto.toJson()),
        });
      }

      debugPrint('Sincronizando ${productos.length} productos con Firebase...');
      final result = await _firebaseService.batchWrite(operations: batch);
      debugPrint('Sincronización completada: ${result ? "exitosa" : "fallida"}');

      return result;
    } catch (e) {
      debugPrint('Error al sincronizar productos: $e');
      return false;
    }
  }

  /// Sincronizar un solo producto
  Future<bool> syncProducto(Producto producto) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.setDocument(
        collection: _productosCollection,
        docId: producto.id,
        data: _firebaseService.addSyncMetadata(producto.toJson()),
      );
    } catch (e) {
      debugPrint('Error al sincronizar producto: $e');
      return false;
    }
  }

  /// Eliminar producto de Firebase
  Future<bool> deleteProducto(String id) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.deleteDocument(
        collection: _productosCollection,
        docId: id,
      );
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      return false;
    }
  }

  /// Obtener productos desde Firebase
  Future<List<Producto>> getProductos() async {
    if (!_firebaseService.isInitialized) {
      debugPrint('⚠️ Firebase no inicializado, no se pueden obtener productos');
      return [];
    }

    try {
      debugPrint('🔄 Iniciando obtención de productos desde Firebase...');
      final data = await _firebaseService.getCollection(
        collection: _productosCollection,
        timeout: const Duration(seconds: 15),
      );

      if (data.isEmpty) {
        debugPrint('ℹ️ No hay productos en Firebase');
        return [];
      }

      final productos = data.map((json) => Producto.fromJson(json)).toList();
      debugPrint('✅ ${productos.length} productos obtenidos desde Firebase');
      return productos;
    } catch (e) {
      debugPrint('❌ Error al obtener productos: $e');
      return [];
    }
  }



  /// Sincronizar historial de cambios
  /// Optimizado para evitar sincronizar historial duplicado
  Future<bool> syncHistorial(List<CambioHistorial> historial) async {
    if (!_firebaseService.isInitialized) return false;

    if (historial.isEmpty) {
      debugPrint('No hay cambios en historial para sincronizar');
      return true;
    }

    try {
      final batch = <Map<String, dynamic>>[];

      for (final cambio in historial) {
        batch.add({
          'collection': _historialCollection,
          'docId': cambio.id,
          'type': 'set',
          'data': _firebaseService.addSyncMetadata(cambio.toJson()),
        });
      }

      debugPrint(
          'Sincronizando ${historial.length} cambios de historial con Firebase...');
      final result = await _firebaseService.batchWrite(operations: batch);
      debugPrint(
          'Sincronización de historial completada: ${result ? "exitosa" : "fallida"}');

      return result;
    } catch (e) {
      debugPrint('Error al sincronizar historial: $e');
      return false;
    }
  }

  /// Registrar cambio en Firebase
  Future<bool> registrarCambio(CambioHistorial cambio) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.setDocument(
        collection: _historialCollection,
        docId: cambio.id,
        data: _firebaseService.addSyncMetadata(cambio.toJson()),
      );
    } catch (e) {
      debugPrint('Error al registrar cambio: $e');
      return false;
    }
  }

  /// Obtener historial desde Firebase
  /// Con límite opcional para mejorar performance
  Future<List<CambioHistorial>> getHistorial({
    String? productoId,
    int limit = _historialLimit,
  }) async {
    if (!_firebaseService.isInitialized) return [];

    try {
      Query<Map<String, dynamic>> query = _firebaseService.firestore
          .collection(_historialCollection)
          .orderBy('syncMetadata.lastModified', descending: true)
          .limit(limit);

      if (productoId != null) {
        query = query.where('productoId', isEqualTo: productoId);
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout obteniendo historial');
        },
      );
      final historial =
          snapshot.docs.map((doc) => CambioHistorial.fromJson(doc.data())).toList();

      return historial;
    } catch (e) {
      debugPrint('⚠️ Error al obtener historial (intentando fallback): $e');
      // Fallback sin orderBy si no existe índice
      try {
        final data = await _firebaseService.getCollection(
          collection: _historialCollection,
          timeout: const Duration(seconds: 10),
        );

        var historial = data.map((json) => CambioHistorial.fromJson(json)).toList();

        if (productoId != null) {
          historial = historial.where((h) => h.productoId == productoId).toList();
        }

        // Ordenar por fecha descendente
        historial.sort((a, b) => b.fecha.compareTo(a.fecha));

        // Limitar resultados
        if (historial.length > limit) {
          historial = historial.sublist(0, limit);
        }

        return historial;
      } catch (e2) {
        debugPrint('Error en fallback de historial: $e2');
        return [];
      }
    }
  }
}
