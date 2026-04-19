import 'dart:convert';

import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

/// ClienteService CON SINCRONIZACIÓN FIREBASE INTEGRADA
class ClienteService with ChangeNotifier {
  // Servicio Firebase
  final FirebaseService _firebaseService = FirebaseService();

  /// Extrae el hash único de una key tipo "[<[<[#0966f]>]>]" o similar
  String _extractHash(String key) {
    final regex = RegExp(r'#([a-fA-F0-9]+)');
    final match = regex.firstMatch(key);
    if (match != null) {
      return match.group(0)!;
    }
    return key;
  }

  /// Compara dos keys por su hash
  bool _keysMatch(Key? key1, Key? key2) {
    if (key1 == null || key2 == null) return false;
    return _extractHash(key1.toString()) == _extractHash(key2.toString());
  }

  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => _clientes;
  set setClientes(List<Pedido> lista) => _clientes = lista;

  bool _syncEnabled = false;

  static const String _pedidosCollection = 'pedidos';

  /// Activar/desactivar sincronización con Firebase
  /// Reglas simples:
  /// - Si NO hay datos locales -> GET de Firebase
  /// - Si hay datos locales Y hay conexión -> PUT a Firebase
  Future<void> setFirebaseSync(bool enabled) async {
    if (enabled && !_firebaseService.isInitialized) {
      debugPrint('Firebase no está inicializado. Inicializando...');
      final initialized = await _firebaseService.initialize();
      if (!initialized) {
        debugPrint('No se pudo inicializar Firebase');
        return;
      }
    }

    _syncEnabled = enabled;

    if (enabled) {
      // REGLA 1: Si NO hay datos locales -> GET de Firebase
      if (_clientes.isEmpty) {
        debugPrint('📥 No hay datos locales, obteniendo desde Firebase...');
        final remotePedidos = await _getPedidosFromFirebase();
        if (remotePedidos.isNotEmpty) {
          _clientes = remotePedidos;
          _guardarEnLocal();
          notifyListeners();
          debugPrint('✅ ${remotePedidos.length} pedidos descargados desde Firebase');
        } else {
          debugPrint('ℹ️ No hay datos en Firebase');
        }
      }
      // REGLA 2: Si hay datos locales Y hay conexión -> PUT a Firebase
      else {
        debugPrint('📤 Hay datos locales (${_clientes.length}), subiendo a Firebase...');
        await _syncPedidos(_clientes);
        debugPrint('✅ Datos locales sincronizados a Firebase');
      }

      debugPrint('✅ Sincronización Firebase activada');
    } else {
      debugPrint('❌ Sincronización Firebase desactivada');
    }
  }

  /// Verificar si Firebase está habilitado
  bool get isFirebaseEnabled => _syncEnabled && _firebaseService.isInitialized;

  void init() {
    setClientes = UserPreferences.getPedidos();
    notifyListeners();
  }

  /// Inicializar con Firebase
  Future<void> initWithFirebase() async {
    // Cargar desde local primero
    setClientes = UserPreferences.getPedidos();

    // Activar sincronización Firebase automáticamente
    await removeDuplicates();
    // Aplicar reglas simples: GET si no hay datos locales, PUT si hay datos locales y conexión
    await setFirebaseSync(true);
    await removeDuplicates();

    notifyListeners();
  }

  Future<Pedido> guardarPedido(String name, List<Item> list, int tot,
      [DateTime? date, Key? key]) async {
    Pedido pedido = Pedido(
      nombre: name,
      fecha: date ?? DateTime.now(),
      lista: list,
      key: key ?? UniqueKey(),
      total: tot,
    );

    // Check if the order already exists in the list using hash comparison
    final existingIndex =
        _clientes.indexWhere((element) => _keysMatch(element.key, pedido.key));
    if (existingIndex != -1) {
      // If it exists, remove the old order
      await UserPreferences.deleteOne(_clientes[existingIndex].key.toString());

      // Eliminar de Firebase si está habilitado
      if (_syncEnabled) {
        await _deletePedidoFromFirebase(_clientes[existingIndex].key.toString());
      }

      _clientes.removeAt(existingIndex);
    }
    // Add the new order to the lists
    _clientes = [pedido, ..._clientes];

    notifyListeners();
    String pedidoString = json.encode(pedido);

    await UserPreferences.setPedido(pedidoString, "${pedido.key}");

    init();

    // Sincronizar con Firebase si está habilitado
    if (_syncEnabled) {
      await _syncPedido(pedido);
    }

    return pedido;
  }

  Future<int> renameItems(List<String> itemsNamesToRename, String newName) async {
    // Create a set of item names to rename for efficient lookup
    final itemNames = itemsNamesToRename.sublist(1);

    int cantModificados = 0;
    // Update items in all orders
    for (var pedido in _clientes) {
      bool pedidoModified = false;

      for (var item in pedido.lista) {
        if (itemNames.contains(item.nombre.toLowerCase())) {
          item.nombre = newName;
          pedidoModified = true;
        }
      }

      // If pedido was modified, update it in storage
      if (pedidoModified) {
        await UserPreferences.deleteOne("${pedido.key}");

        String pedidoString = json.encode(pedido);
        await UserPreferences.setPedido(pedidoString, "${pedido.key}");
        cantModificados++;
      }
    }
    init();

    // notifyListeners();
    return cantModificados;
  }

  editMessage(String msg, Pedido pedido) async {
    pedido.msg = msg;

    final i = _clientes
        .indexWhere((element) => element.key.toString() == pedido.key.toString());
    String pedidoString = json.encode(pedido);

    if (i != -1) {
      // Actualizar el pedido en la lista sin eliminarlo
      await UserPreferences.setPedido(pedidoString, "${_clientes[i].key}");
      _clientes[i] = pedido;
    } else {
      await UserPreferences.setPedido(pedidoString, "${pedido.key}");
      _clientes.add(pedido);
    }

    notifyListeners();

    // Sincronizar con Firebase si está habilitado
    if (_syncEnabled) {
      await _syncPedido(pedido);
    }
  }

  Future<List<Pedido>> loadClientes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? listString = prefs.getString("pedidosKey") ?? "";

    if (listString.isEmpty) return [];

    _clientes = jsonDecode(listString);
    notifyListeners();

    return _clientes;
  }

  deletePedido(int i, String key) async {
    await UserPreferences.deleteOne(key);

    // Eliminar de Firebase si está habilitado

    clientes.removeAt(i);
    notifyListeners();

    if (_syncEnabled) {
      await _deletePedidoFromFirebase(key);
    }
  }

  /// [0] para items, [1] para clientes
  List<List<Object>> searchOnPedidos(String word) {
    final allItems =
        clientes.fold<List<Item>>([], (prev, element) => [...prev, ...element.lista]);

    List<Item> itemsCoincidencia = allItems
        .where((element) => element.nombre.toLowerCase().contains(word.toLowerCase()))
        .take(4)
        .toList();

    final clientesCoincidencia = clientes
        .where((cliente) =>
            cliente.nombre.toLowerCase().contains(word.toLowerCase()) ||
            cliente.lista.any(
                (element) => element.nombre.toLowerCase().contains(word.toLowerCase())))
        .toList();

    return [itemsCoincidencia, clientesCoincidencia];
  }

  // ========== MÉTODOS DE SINCRONIZACIÓN FIREBASE ==========

  Future<void> _savePedidoLocal(Pedido pedido) async {
    String pedidoString = json.encode(pedido);
    await UserPreferences.setPedido(pedidoString, "${pedido.key}");
  }

  /// Sincronizar un solo pedido con Firebase
  Future<bool> _syncPedido(Pedido pedido) async {
    if (!_firebaseService.isInitialized) return false;
    if (pedido.firebaseSynced) return true;

    try {
      final result = await _firebaseService.setDocument(
        collection: _pedidosCollection,
        docId: pedido.key.toString(),
        data: _firebaseService.addSyncMetadata(pedido.toJson()),
      );
      if (result) {
        pedido.firebaseSynced = true;
        await _savePedidoLocal(pedido);
      }
      return result;
    } catch (e) {
      debugPrint('Error al sincronizar pedido: $e');
      return false;
    }
  }

  /// Sincronizar todos los pedidos con Firebase
  Future<bool> _syncPedidos(List<Pedido> pedidos) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      final pendientes = pedidos.where((p) => !p.firebaseSynced).toList();

      if (pendientes.isEmpty) {
        debugPrint('No hay pedidos para sincronizar');
        return true;
      }

      final batch = <Map<String, dynamic>>[];

      for (final pedido in pendientes) {
        batch.add({
          'collection': _pedidosCollection,
          'docId': pedido.key.toString(),
          'type': 'set',
          'data': _firebaseService.addSyncMetadata(pedido.toJson()),
        });
      }

      // batchWrite ya maneja la división en chunks de 100
      final result = await _firebaseService.batchWrite(operations: batch);

      if (result) {
        for (final pedido in pendientes) {
          pedido.firebaseSynced = true;
          await _savePedidoLocal(pedido);
        }
        debugPrint('✅ Pedidos sincronizados: ${pendientes.length} items');
      } else {
        debugPrint('❌ Error al sincronizar pedidos');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error al sincronizar pedidos: $e');
      return false;
    }
  }

  /// Eliminar pedido de Firebase
  Future<bool> _deletePedidoFromFirebase(String key) async {
    if (!_firebaseService.isInitialized) return false;

    try {
      return await _firebaseService.deleteDocument(
        collection: _pedidosCollection,
        docId: key,
      );
    } catch (e) {
      debugPrint('Error al eliminar pedido de Firebase: $e');
      return false;
    }
  }

  /// Obtener todos los pedidos desde Firebase
  Future<List<Pedido>> _getPedidosFromFirebase() async {
    if (!_firebaseService.isInitialized) return [];

    try {
      final data = await _firebaseService.getCollection(
        collection: _pedidosCollection,
      );

      return data.map((json) {
        final pedido = Pedido.fromJson(json);
        pedido.firebaseSynced = true;
        return pedido;
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener pedidos desde Firebase: $e');
      return [];
    }
  }

  /// Guardar en local (backup)
  void _guardarEnLocal() {
    for (var pedido in _clientes) {
      String pedidoString = json.encode(pedido);
      UserPreferences.setPedido(pedidoString, "${pedido.key}");
    }
  }

  /// Sincronizar manualmente con Firebase
  Future<bool> syncNow() async {
    if (!_syncEnabled || !_firebaseService.isInitialized) {
      debugPrint('Firebase no está habilitado');
      return false;
    }

    try {
      return await _syncPedidos(_clientes);
    } catch (e) {
      debugPrint('Error al sincronizar pedidos: $e');
      return false;
    }
  }

  /// Cargar datos desde Firebase
  Future<bool> loadFromFirebase() async {
    if (!_syncEnabled || !_firebaseService.isInitialized) {
      debugPrint('Firebase no está habilitado');
      return false;
    }

    try {
      final firebasePedidos = await _getPedidosFromFirebase();
      _clientes = firebasePedidos;
      _guardarEnLocal();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al cargar desde Firebase: $e');
      return false;
    }
  }

  /// Verificar estado de sincronización
  Future<Map<String, dynamic>> getSyncStatus() async {
    final status = {
      'localPedidos': _clientes.length,
      'firebaseEnabled': _syncEnabled,
      'firebaseInitialized': _firebaseService.isInitialized,
      'firebasePedidos': 0,
      'lastSync': DateTime.now().toIso8601String(),
    };

    if (_syncEnabled && _firebaseService.isInitialized) {
      try {
        final firebasePedidos = await _getPedidosFromFirebase();
        status['firebasePedidos'] = firebasePedidos.length;
      } catch (e) {
        status['error'] = e.toString();
      }
    }

    return status;
  }

  /// Elimina pedidos duplicados de la lista local y de SharedPreferences
  Future<int> removeDuplicates() async {
    final seenHashes = <String>{};
    final uniqueClientes = <Pedido>[];
    int removedCount = 0;

    // Ordenar por fecha descendente para mantener el más reciente
    final sortedClientes = List<Pedido>.from(_clientes)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    for (var pedido in sortedClientes) {
      final hash = _extractHash(pedido.key.toString());
      if (!seenHashes.contains(hash)) {
        seenHashes.add(hash);
        uniqueClientes.add(pedido);
      } else {
        // Es un duplicado, eliminarlo
        await UserPreferences.deleteOne(pedido.key.toString());
        if (_syncEnabled) {
          await _deletePedidoFromFirebase(pedido.key.toString());
        }
        removedCount++;
        debugPrint('🗑️ Duplicado eliminado: ${pedido.nombre} ($hash)');
      }
    }

    // También limpiar duplicados en SharedPreferences
    final prefsRemoved = await UserPreferences.removeDuplicates();
    removedCount += prefsRemoved;

    _clientes = uniqueClientes;
    notifyListeners();

    debugPrint('✅ Limpieza completada: $removedCount duplicados eliminados');
    return removedCount;
  }

  /// Obtener diagnóstico de keys (para debug)
  Map<String, dynamic> getDiagnostics() {
    final hashes = <String, int>{};
    for (var pedido in _clientes) {
      final hash = _extractHash(pedido.key.toString());
      hashes[hash] = (hashes[hash] ?? 0) + 1;
    }

    final duplicates = hashes.entries.where((e) => e.value > 1).toList();

    return {
      'totalPedidos': _clientes.length,
      'uniqueHashes': hashes.length,
      'duplicatesCount': duplicates.fold<int>(0, (sum, e) => sum + e.value - 1),
      'duplicateHashes': duplicates.map((e) => '${e.key}: ${e.value}x').toList(),
      'prefsKeys': UserPreferences.getAllPedidoKeys(),
    };
  }
}
