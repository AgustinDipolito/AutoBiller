import 'dart:convert';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';
import '../models/stock.dart';
import 'firebase_stock_sync.dart';
import 'firebase_service.dart';

/// StockService CON SINCRONIZACIÓN FIREBASE INTEGRADA
class StockService with ChangeNotifier {
  // Servicio de sincronización Firebase
  final FirebaseStockSync _firebaseSync = FirebaseStockSync();
  final FirebaseService _firebaseService = FirebaseService();

  List<Stock> stock = [];
  List<Stock> stockFiltered = [];
  bool _syncEnabled = false;

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
      if (stock.isEmpty) {
        debugPrint('📥 No hay datos locales, obteniendo desde Firebase...');
        final remoteStock = await _firebaseSync.getStock();
        if (remoteStock.isNotEmpty) {
          stock = remoteStock;
          stock.sort((a, b) => a.id.compareTo(b.id));
          _guardarEnLocal();
          notifyListeners();
          debugPrint('✅ ${remoteStock.length} items descargados desde Firebase');
        } else {
          debugPrint('ℹ️ No hay datos en Firebase');
        }
      }
      // REGLA 2: Si hay datos locales Y hay conexión -> PUT a Firebase
      else {
        debugPrint('📤 Hay datos locales (${stock.length}), subiendo a Firebase...');
        await _syncPendientes();
        debugPrint('✅ Datos locales sincronizados a Firebase');
      }

      debugPrint('✅ Sincronización Firebase activada');
    } else {
      debugPrint('❌ Sincronización Firebase desactivada');
    }
  }

  /// Verificar si Firebase está habilitado
  bool get isFirebaseEnabled => _syncEnabled && _firebaseService.isInitialized;

  void removeByName(String name) {
    stock.removeWhere((element) => element.name == name);
    _guardarYSincronizar();

    // Eliminar de Firebase si está habilitado
    if (_syncEnabled) {
      _firebaseSync.deleteStockByName(name);
    }

    notifyListeners();
  }

  void addCantToItem(int id, {int cant = 1}) {
    for (var element in stock) {
      if (element.id == id) {
        element.cant += cant;
        element.ultimoMov = cant;
        element.fechaMod = DateTime.now();
        element.cambiosPendientes = true;
      }
    }
    _guardarYSincronizar();
    notifyListeners();
  }

  void updateItem(Stock item) {
    item.cambiosPendientes = true;
    stock = stock.map((e) {
      if (e.id == item.id) {
        e = item;
      }
      return e;
    }).toList();

    stockFiltered.clear();
    _guardarYSincronizar();
    notifyListeners();
  }

  void createNew({
    required int cant,
    required String name,
    required Proveedor proveedor,
    required StockType type,
  }) {
    int lastId = 0;

    if (stock.isNotEmpty) {
      sort();
      lastId = stock.last.id + 1;
    }

    if (stock.every((element) => element.id != lastId)) {
      final newStock = Stock(
        cant: cant,
        name: name,
        id: lastId,
        proveedor: proveedor,
        type: type,
        fechaMod: DateTime.now(),
        ultimoMov: cant,
        cambiosPendientes: true,
      );

      stock.add(newStock);
      _guardarYSincronizar();
      notifyListeners();
    }
  }

  void searchItem(String cad) {
    final search = cad.toUpperCase();
    stockFiltered.clear();

    stockFiltered = stock.where((item) {
      final nombreLow = item.name.toUpperCase();
      return nombreLow.contains(search);
    }).toList();

    notifyListeners();
  }

  void searchLowerThan(int cant) {
    stockFiltered = stockFiltered.where((element) => element.cant < cant).toList();
    notifyListeners();
  }

  void searchLowerThanWithType(int cant, dynamic type) {
    stockFiltered = stockFiltered
        .where((element) =>
            element.cant < cant && (element.type == type || element.proveedor == type))
        .toList();
    notifyListeners();
  }

  void searchByType(StockType type) {
    stockFiltered.clear();
    stockFiltered = stock.where((element) => element.type == type).toList();
    notifyListeners();
  }

  void searchByProvider(Proveedor provider) {
    stockFiltered.clear();
    stockFiltered = stock.where((element) => element.proveedor == provider).toList();
    notifyListeners();
  }

  void sort() {
    stock.sort((a, b) => a.id.compareTo(b.id));
    notifyListeners();
  }

  Future<void> init() async {
    // Cargar desde local primero
    stock = UserPreferences.getStock();
    notifyListeners();

    // Si Firebase está habilitado, intentar cargar desde allí
    if (_syncEnabled && _firebaseService.isInitialized) {
      await setFirebaseSync(true);
    }

    notifyListeners();
  }

  void filterMovements() {
    stockFiltered = stock.where((element) => element.ultimoMov != 0).toList();
    notifyListeners();
  }

  /// Resetear movimientos (útil al finalizar un período)
  Future<void> resetAllMovements() async {
    for (var item in stock) {
      item.ultimoMov = 0;
      item.cambiosPendientes = true;
    }

    _guardarYSincronizar();

    // Sincronizar con Firebase si está habilitado
    if (_syncEnabled) {
      await _firebaseSync.resetMovements();
    }

    notifyListeners();
  }

  /// Guardar en local y sincronizar con Firebase si está habilitado
  void _guardarYSincronizar() {
    _guardarEnLocal();

    if (_syncEnabled) {
      _syncPendientes();
    }
  }

  /// Guardar solo en local (backup)
  void _guardarEnLocal() {
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
  }

  /// Sincronizar manualmente con Firebase
  Future<bool> syncNow() async {
    if (!_syncEnabled || !_firebaseService.isInitialized) {
      debugPrint('Firebase no está habilitado');
      return false;
    }

    try {
      return await _syncPendientes();
    } catch (e) {
      debugPrint('Error al sincronizar stock: $e');
      return false;
    }
  }

  Future<bool> _syncPendientes() async {
    final pendientes = stock.where((item) => item.cambiosPendientes).toList();
    if (pendientes.isEmpty) return true;

    final result = await _firebaseSync.syncStock(pendientes);
    if (result) {
      for (final item in pendientes) {
        item.cambiosPendientes = false;
      }
      _guardarEnLocal();
    }
    return result;
  }

  /// Cargar datos desde Firebase
  Future<bool> loadFromFirebase() async {
    if (!_syncEnabled || !_firebaseService.isInitialized) {
      debugPrint('Firebase no está habilitado');
      return false;
    }

    try {
      final firebaseStock = await _firebaseSync.getStock();
      stock = firebaseStock;
      _guardarEnLocal();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al cargar desde Firebase: $e');
      return false;
    }
  }

  /// Primera sincronización segura (para migración Android → Firebase)
  ///
  /// Este método asegura que tus datos de Android no se pierdan:
  /// 1. Sube tus datos locales a Firebase
  /// 2. Espera confirmación
  /// 3. Recién después activa la sincronización bidireccional
  Future<bool> firstSyncFromAndroid() async {
    try {
      // Paso 1: Verificar que hay datos locales
      if (stock.isEmpty) {
        debugPrint('⚠️ No hay datos locales para sincronizar');
        return false;
      }

      debugPrint('🔄 Iniciando primera sincronización...');
      debugPrint('📱 Datos locales: ${stock.length} items');

      // Paso 2: Inicializar Firebase si no está listo
      if (!_firebaseService.isInitialized) {
        final initialized = await _firebaseService.initialize();
        if (!initialized) {
          debugPrint('❌ Error: No se pudo inicializar Firebase');
          return false;
        }
      }

      // Paso 3: Subir TODOS los datos locales a Firebase
      debugPrint('📤 Subiendo datos a Firebase...');
      final uploaded = await _firebaseSync.syncStock(stock);

      if (!uploaded) {
        debugPrint('❌ Error al subir datos a Firebase');
        return false;
      }

      debugPrint('✅ Datos subidos correctamente a Firebase');

      // Paso 4: Verificar que se subieron correctamente
      await Future.delayed(const Duration(seconds: 2)); // Dar tiempo a Firebase
      final firebaseStock = await _firebaseSync.getStock();

      debugPrint('🔍 Verificando: Firebase tiene ${firebaseStock.length} items');

      if (firebaseStock.length != stock.length) {
        debugPrint('⚠️ Advertencia: Discrepancia en cantidad de items');
        debugPrint('   Local: ${stock.length}, Firebase: ${firebaseStock.length}');
      }

      // Paso 5: Activar sincronización
      _syncEnabled = true;

      debugPrint('✅ Primera sincronización completada');
      debugPrint('🔄 Sincronización activada');

      return true;
    } catch (e) {
      debugPrint('❌ Error en primera sincronización: $e');
      return false;
    }
  }

  /// Verificar estado de sincronización (útil para debugging)
  Future<Map<String, dynamic>> getSyncStatus() async {
    final status = {
      'localItems': stock.length,
      'firebaseEnabled': _syncEnabled,
      'firebaseInitialized': _firebaseService.isInitialized,
      'firebaseItems': 0,
      'lastSync': DateTime.now().toIso8601String(),
    };

    if (_syncEnabled && _firebaseService.isInitialized) {
      try {
        final firebaseStock = await _firebaseSync.getStock();
        status['firebaseItems'] = firebaseStock.length;
      } catch (e) {
        status['error'] = e.toString();
      }
    }

    return status;
  }
}
