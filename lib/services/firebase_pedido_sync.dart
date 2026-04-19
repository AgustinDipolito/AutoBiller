import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import 'firebase_service.dart';

/// Servicio de sincronización de pedidos con Firebase
/// Implementa lógica simple: GET si no hay datos locales, PUT si hay datos locales y conexión
class FirebasePedidoSync {
  static final FirebasePedidoSync _instance = FirebasePedidoSync._internal();
  factory FirebasePedidoSync() => _instance;
  FirebasePedidoSync._internal();

  final FirebaseService _firebaseService = FirebaseService();

  static const String _carritosCollection = 'carritos';
  static const String _pedidosGuardadosCollection = 'pedidos_guardados';

  /// ID del carrito activo (por defecto usa el deviceId)
  String get _activeCarritoId => _firebaseService.deviceId;

  /// Sincronizar carrito actual hacia Firebase
  Future<bool> syncCarrito(List<Item> carrito) async {
    if (!_firebaseService.isInitialized) {
      debugPrint('Firebase no inicializado');
      return false;
    }

    try {
      final carritoData = {
        'items': carrito.map((item) => item.toJson()).toList(),
        'itemCount': carrito.length,
        'total': carrito.fold<int>(0, (suma, item) => suma + item.precioT),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      final result = await _firebaseService.setDocument(
        collection: _carritosCollection,
        docId: _activeCarritoId,
        data: _firebaseService.addSyncMetadata(carritoData),
      );

      if (result) {
        debugPrint('Carrito sincronizado: ${carrito.length} items');
      }

      return result;
    } catch (e) {
      debugPrint('Error al sincronizar carrito: $e');
      return false;
    }
  }

  /// Obtener carrito desde Firebase
  Future<List<Item>> getCarrito() async {
    if (!_firebaseService.isInitialized) return [];

    try {
      final data = await _firebaseService.getDocument(
        collection: _carritosCollection,
        docId: _activeCarritoId,
      );

      if (data == null || data['items'] == null) {
        return [];
      }

      final itemsList = data['items'] as List<dynamic>;
      return itemsList.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener carrito: $e');
      return [];
    }
  }

  /// Limpiar carrito en Firebase
  Future<bool> clearCarrito() async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.deleteDocument(
        collection: _carritosCollection,
        docId: _activeCarritoId,
      );
    } catch (e) {
      debugPrint('Error al limpiar carrito: $e');
      return false;
    }
  }

  /// Guardar pedido completado (historial)
  Future<bool> savePedido({
    required List<Item> items,
    required String customerName,
    String? notes,
  }) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      final pedidoId = DateTime.now().millisecondsSinceEpoch.toString();

      final pedidoData = {
        'id': pedidoId,
        'items': items.map((item) => item.toJson()).toList(),
        'itemCount': items.length,
        'total': items.fold<int>(0, (suma, item) => suma + item.precioT),
        'customerName': customerName,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceId': _firebaseService.deviceId,
      };

      final result = await _firebaseService.setDocument(
        collection: _pedidosGuardadosCollection,
        docId: pedidoId,
        data: pedidoData,
      );

      if (result) {
        debugPrint('Pedido guardado: $pedidoId');
      }

      return result;
    } catch (e) {
      debugPrint('Error al guardar pedido: $e');
      return false;
    }
  }

  /// Obtener pedidos guardados
  Future<List<Map<String, dynamic>>> getSavedPedidos({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_firebaseService.isInitialized) return [];

    try {
      final pedidos = await _firebaseService.getCollection(
        collection: _pedidosGuardadosCollection,
      );

      var filtered = pedidos;

      // Filtrar por fechas si se especifican
      if (startDate != null || endDate != null) {
        filtered = filtered.where((pedido) {
          final createdAt = pedido['createdAt'];
          if (createdAt == null) return false;

          final fecha = (createdAt as Timestamp).toDate();

          if (startDate != null && fecha.isBefore(startDate)) return false;
          if (endDate != null && fecha.isAfter(endDate)) return false;

          return true;
        }).toList();
      }

      // Ordenar por fecha descendente
      filtered.sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      // Limitar resultados si se especifica
      if (limit != null && filtered.length > limit) {
        filtered = filtered.sublist(0, limit);
      }

      return filtered;
    } catch (e) {
      debugPrint('Error al obtener pedidos guardados: $e');
      return [];
    }
  }

  /// Eliminar pedido guardado
  Future<bool> deleteSavedPedido(String pedidoId) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.deleteDocument(
        collection: _pedidosGuardadosCollection,
        docId: pedidoId,
      );
    } catch (e) {
      debugPrint('Error al eliminar pedido: $e');
      return false;
    }
  }

  /// Compartir carrito con otro dispositivo
  Future<String?> shareCarrito(List<Item> carrito) async {
    if (!_firebaseService.isInitialized) return null;

    try {
      final shareId = 'shared_${DateTime.now().millisecondsSinceEpoch}';

      final carritoData = {
        'items': carrito.map((item) => item.toJson()).toList(),
        'itemCount': carrito.length,
        'total': carrito.fold<int>(0, (suma, item) => suma + item.precioT),
        'sharedBy': _firebaseService.deviceId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      };

      final result = await _firebaseService.setDocument(
        collection: _carritosCollection,
        docId: shareId,
        data: carritoData,
      );

      return result ? shareId : null;
    } catch (e) {
      debugPrint('Error al compartir carrito: $e');
      return null;
    }
  }

  /// Importar carrito compartido
  Future<List<Item>?> importSharedCarrito(String shareId) async {
    if (!_firebaseService.isInitialized) return null;

    try {
      final data = await _firebaseService.getDocument(
        collection: _carritosCollection,
        docId: shareId,
      );

      if (data == null || data['items'] == null) {
        return null;
      }

      // Verificar si expiró
      final expiresAt = data['expiresAt'];
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (expiry.isBefore(DateTime.now())) {
          debugPrint('Carrito compartido expirado');
          return null;
        }
      }

      final itemsList = data['items'] as List<dynamic>;
      return itemsList.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al importar carrito compartido: $e');
      return null;
    }
  }
}
