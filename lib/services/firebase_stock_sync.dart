import 'package:flutter/foundation.dart';
import '../models/stock.dart';
import 'firebase_service.dart';

/// Servicio de sincronización del stock con Firebase
/// Implementa lógica simple: GET si no hay datos locales, PUT si hay datos locales y conexión
class FirebaseStockSync {
  static final FirebaseStockSync _instance = FirebaseStockSync._internal();
  factory FirebaseStockSync() => _instance;
  FirebaseStockSync._internal();

  final FirebaseService _firebaseService = FirebaseService();

  static const String _stockCollection = 'stock';

  /// Sincronizar todo el stock hacia Firebase
  Future<bool> syncStock(List<Stock> stock) async {
    if (!_firebaseService.isInitialized) {
      debugPrint('Firebase no inicializado');
      return false;
    }

    try {
      final batch = <Map<String, dynamic>>[];

      for (final item in stock) {
        batch.add({
          'collection': _stockCollection,
          'docId': item.id.toString(),
          'type': 'set',
          'data': _firebaseService.addSyncMetadata(
            item.toJson(includeLocalFields: false),
          ),
        });
      }

      final result = await _firebaseService.batchWrite(operations: batch);

      if (result) {
        debugPrint('Stock sincronizado: ${stock.length} items');
      }

      return result;
    } catch (e) {
      debugPrint('Error al sincronizar stock: $e');
      return false;
    }
  }

  /// Sincronizar un solo item de stock
  Future<bool> syncStockItem(Stock item) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.setDocument(
        collection: _stockCollection,
        docId: item.id.toString(),
        data:
            _firebaseService.addSyncMetadata(item.toJson(includeLocalFields: false)),
      );
    } catch (e) {
      debugPrint('Error al sincronizar item de stock: $e');
      return false;
    }
  }

  /// Eliminar item de stock de Firebase
  Future<bool> deleteStockItem(int id) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.deleteDocument(
        collection: _stockCollection,
        docId: id.toString(),
      );
    } catch (e) {
      debugPrint('Error al eliminar item de stock: $e');
      return false;
    }
  }

  /// Eliminar item por nombre
  Future<bool> deleteStockByName(String name) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      // Primero obtener todos los items para encontrar el que coincida
      final items = await getStock();
      final itemToDelete = items.where((item) => item.name == name).toList();

      if (itemToDelete.isEmpty) {
        debugPrint('No se encontró item con nombre: $name');
        return false;
      }

      // Eliminar todos los items que coincidan
      final batch = <Map<String, dynamic>>[];
      for (final item in itemToDelete) {
        batch.add({
          'collection': _stockCollection,
          'docId': item.id.toString(),
          'type': 'delete',
        });
      }

      return await _firebaseService.batchWrite(operations: batch);
    } catch (e) {
      debugPrint('Error al eliminar item por nombre: $e');
      return false;
    }
  }

  /// Obtener todo el stock desde Firebase
  Future<List<Stock>> getStock() async {
    if (!_firebaseService.isInitialized) return [];

    try {
      final data = await _firebaseService.getCollection(
        collection: _stockCollection,
      );

      return data.map((json) => Stock.fromJson(json, fromFirebase: true)).toList();
    } catch (e) {
      debugPrint('Error al obtener stock: $e');
      return [];
    }
  }

  /// Actualizar cantidad de un item
  Future<bool> updateItemQuantity({
    required int id,
    required int cant,
    required int ultimoMov,
  }) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      final itemData = await _firebaseService.getDocument(
        collection: _stockCollection,
        docId: id.toString(),
      );

      if (itemData == null) {
        debugPrint('Item no encontrado en Firebase: $id');
        return false;
      }

      final item = Stock.fromJson(itemData, fromFirebase: true);
      item.cant = cant;
      item.ultimoMov = ultimoMov;
      item.fechaMod = DateTime.now();

      return await syncStockItem(item);
    } catch (e) {
      debugPrint('Error al actualizar cantidad: $e');
      return false;
    }
  }



  /// Buscar items por filtros
  Future<List<Stock>> searchStock({
    StockType? type,
    Proveedor? proveedor,
    int? maxCant,
  }) async {
    if (!_firebaseService.isInitialized) return [];

    try {
      var stock = await getStock();

      if (type != null) {
        stock = stock.where((item) => item.type == type).toList();
      }

      if (proveedor != null) {
        stock = stock.where((item) => item.proveedor == proveedor).toList();
      }

      if (maxCant != null) {
        stock = stock.where((item) => item.cant < maxCant).toList();
      }

      return stock;
    } catch (e) {
      debugPrint('Error al buscar stock: $e');
      return [];
    }
  }

  /// Obtener items con movimientos recientes
  Future<List<Stock>> getItemsWithMovements() async {
    if (!_firebaseService.isInitialized) return [];

    try {
      final stock = await getStock();
      return stock.where((item) => item.ultimoMov != 0).toList();
    } catch (e) {
      debugPrint('Error al obtener items con movimientos: $e');
      return [];
    }
  }

  /// Resetear movimientos de todos los items
  Future<bool> resetMovements() async {
    if (!_firebaseService.isInitialized) return false;

    try {
      final stock = await getStock();
      final batch = <Map<String, dynamic>>[];

      for (final item in stock) {
        if (item.ultimoMov != 0) {
          item.ultimoMov = 0;
          batch.add({
            'collection': _stockCollection,
            'docId': item.id.toString(),
            'type': 'set',
            'data': _firebaseService.addSyncMetadata(
              item.toJson(includeLocalFields: false),
            ),
          });
        }
      }

      if (batch.isEmpty) return true;

      return await _firebaseService.batchWrite(operations: batch);
    } catch (e) {
      debugPrint('Error al resetear movimientos: $e');
      return false;
    }
  }

}
