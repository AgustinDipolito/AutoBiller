import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/item_response.dart';
import '../models/stock.dart' show StockType, Proveedor, GroupType;
import 'firebase_catalogo_sync.dart';
import 'firebase_service.dart';

/// Servicio para gestionar el catálogo de productos
/// CON SINCRONIZACIÓN FIREBASE INTEGRADA
class CatalogoService {
  static final CatalogoService _instance = CatalogoService._internal();
  factory CatalogoService() => _instance;
  CatalogoService._internal();

  // Servicio de sincronización Firebase
  final FirebaseCatalogoSync _firebaseSync = FirebaseCatalogoSync();
  final FirebaseService _firebaseService = FirebaseService();

  List<Producto> _productos = [];
  List<CambioHistorial> _historial = [];

  // Flag para alternar entre local y Firebase
  bool _useFirebase = true;
  bool _isLoaded = false;
  bool _syncEnabled = true;

  // Modo de catálogo: 'firebase' o 'offline'
  String _catalogoMode = 'firebase';
  String get catalogoMode => _catalogoMode;

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

    _useFirebase = enabled;
    _syncEnabled = enabled;

    if (enabled) {
      // REGLA 1: Si NO hay datos locales -> GET de Firebase
      if (_productos.isEmpty) {
        debugPrint('📥 No hay productos locales, obteniendo desde Firebase...');
        final productosFirebase = await _firebaseSync.getProductos();
        if (productosFirebase.isNotEmpty) {
          _productos = productosFirebase;
          await _guardarEnLocal();
          debugPrint(
              '✅ ${productosFirebase.length} productos descargados desde Firebase');
        } else {
          debugPrint('ℹ️ No hay productos en Firebase');
        }
      }
      // REGLA 2: Si hay datos locales Y hay conexión -> PUT a Firebase
      else {
        debugPrint(
            '📤 Hay productos locales (${_productos.length}), subiendo a Firebase...');
        await _firebaseSync.syncProductos(_productos);
        debugPrint('✅ Productos locales sincronizados a Firebase');
      }

      // Sincronizar historial si existe
      if (_historial.isNotEmpty) {
        await _firebaseSync.syncHistorial(_historial);
      }

      debugPrint('✅ Sincronización Firebase activada');
    } else {
      debugPrint('❌ Sincronización Firebase desactivada');
    }
  }

  /// Verificar si Firebase está habilitado y funcionando
  bool get isFirebaseEnabled => _useFirebase && _firebaseService.isInitialized;

  /// Cambiar modo de catálogo (firebase/offline)
  void setCatalogoMode(String mode) {
    if (mode != 'firebase' && mode != 'offline') {
      debugPrint('❌ Modo inválido: $mode. Use "firebase" o "offline"');
      return;
    }
    _catalogoMode = mode;
    debugPrint('🔄 Modo de catálogo cambiado a: $mode');
  }

  /// Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    if (!_isLoaded) {
      await _cargarProductos();
    }
    return List.from(_productos);
  }

  /// Obtener producto por ID
  Future<Producto?> getProductoById(String id) async {
    if (!_isLoaded) {
      await _cargarProductos();
    }
    try {
      return _productos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Buscar productos por nombre
  Future<List<Producto>> buscarPorNombre(String query) async {
    if (!_isLoaded) {
      await _cargarProductos();
    }
    if (query.isEmpty) return _productos;

    final queryLower = query.toLowerCase();
    return _productos.where((p) => p.nombre.toLowerCase().contains(queryLower)).toList();
  }

  /// Obtener productos como ItemResponse para compatibilidad con ListaService
  Future<List<ItemResponse>> getProductosAsItemResponse() async {
    if (!_isLoaded) {
      await _cargarProductos();
    }

    return _productos
        .where((p) => p.activo) // Solo productos activos
        .map((p) => ItemResponse(
              p.nombre,
              p.tipo,
              p.precio,
              p.id,
            ))
        .toList();
  }

  /// Buscar productos como ItemResponse
  Future<List<ItemResponse>> buscarProductosAsItemResponse(String query) async {
    if (!_isLoaded) {
      await _cargarProductos();
    }

    if (query.isEmpty) {
      return getProductosAsItemResponse();
    }

    final queryLower = query.toLowerCase();
    return _productos
        .where((p) => p.activo && p.nombre.toLowerCase().contains(queryLower))
        .map((p) => ItemResponse(
              p.nombre,
              p.tipo,
              p.precio,
              p.id,
            ))
        .toList();
  }

  /// Crear nuevo producto (CON SYNC)
  Future<bool> crearProducto(Producto producto) async {
    try {
      if (_productos.any((p) => p.id == producto.id)) {
        throw Exception('Ya existe un producto con el ID ${producto.id}');
      }

      _productos.add(producto);
      await _guardarProductos();

      // Registrar en historial
      await _registrarCambio(
        productoId: producto.id,
        nombreProducto: producto.nombre,
        campo: 'Creación',
        valorNuevo: 'Producto creado',
      );

      // Sincronizar con Firebase si está habilitado
      if (_syncEnabled) {
        await _firebaseSync.syncProducto(producto);
      }

      return true;
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      return false;
    }
  }

  /// Actualizar producto existente (CON SYNC)
  Future<bool> actualizarProducto(Producto productoActualizado) async {
    try {
      final index = _productos.indexWhere((p) => p.id == productoActualizado.id);
      if (index == -1) {
        throw Exception('Producto no encontrado');
      }

      final productoAnterior = _productos[index];

      // Registrar cambios en historial
      await _compararYRegistrarCambios(productoAnterior, productoActualizado);

      // Actualizar fecha de modificación
      productoActualizado = productoActualizado.copyWith(
        fechaModificacion: DateTime.now(),
        grupo: productoAnterior.grupo,
        familia: productoAnterior.familia,
        marca: productoAnterior.marca,
        imagenUrl: productoAnterior.imagenUrl, // Mantener imagen si no se actualiza
        activo: productoAnterior.activo, // Mantener estado si no se actualiza
        familiaCustom: productoAnterior.familiaCustom,
        marcaCustom: productoAnterior.marcaCustom,
        grupoCustom: productoAnterior.grupoCustom,
        esOferta: productoAnterior.esOferta,
      );

      _productos[index] = productoActualizado;
      await _guardarProductos();

      // Sincronizar con Firebase si está habilitado
      if (_syncEnabled) {
        await _firebaseSync.syncProducto(productoActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      return false;
    }
  }

  /*
  /// Eliminar producto (CON SYNC) - DESHABILITADO POR SEGURIDAD
  Future<bool> eliminarProducto(String id) async {
    try {
      final producto = _productos.firstWhere((p) => p.id == id);
      _productos.removeWhere((p) => p.id == id);
      await _guardarProductos();

      // Registrar en historial
      await _registrarCambio(
        productoId: id,
        nombreProducto: producto.nombre,
        campo: 'Eliminación',
        valorAnterior: 'Producto eliminado',
      );

      // Sincronizar con Firebase si está habilitado
      if (_syncEnabled) {
        await _firebaseSync.deleteProducto(id);
      }

      return true;
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      return false;
    }
  }
  */

  /// Actualización masiva de precios (CON SYNC)
  Future<int> actualizarPreciosMasivo({
    required double porcentaje,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final precioAnterior = producto.precio;
        final nuevoPrecio = (precioAnterior * (1 + porcentaje / 100)).round();

        _productos[i] = producto.copyWith(
          precio: nuevoPrecio,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        // Acumular cambios en vez de registrarlos uno por uno
        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: nuevoPrecio.toString(),
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        // Agregar cambios al historial local
        _historial.addAll(cambiosBatch);
        if (_historial.length > 100) {
          _historial = _historial.sublist(_historial.length - 100);
        }

        // Guardar todo en batch
        await _guardarEnLocal();

        // Sincronizar con Firebase en batch si está habilitado
        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en actualización masiva: $e');
      return 0;
    }
  }

  /// Sumar monto fijo a precios masivamente (CON SYNC)
  Future<int> sumarAPreciosMasivo({
    required int monto,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final precioAnterior = producto.precio;
        final nuevoPrecio = precioAnterior + monto;

        // Validar que el precio no sea negativo
        if (nuevoPrecio < 0) continue;

        _productos[i] = producto.copyWith(
          precio: nuevoPrecio,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: nuevoPrecio.toString(),
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en suma masiva: $e');
      return 0;
    }
  }

  /// Asignar precio fijo masivamente (CON SYNC)
  Future<int> asignarPrecioMasivo({
    required int precio,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final precioAnterior = producto.precio;

        _productos[i] = producto.copyWith(
          precio: precio,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: precio.toString(),
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en asignación masiva: $e');
      return 0;
    }
  }

  /// Activar/Desactivar productos masivamente (CON SYNC)
  Future<int> cambiarEstadoMasivo({
    required bool activo,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final estadoAnterior = producto.activo;

        _productos[i] = producto.copyWith(
          activo: activo,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'activo',
          valorAnterior: estadoAnterior.toString(),
          valorNuevo: activo.toString(),
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en cambio de estado masivo: $e');
      return 0;
    }
  }

  /// Asignar familia masivamente (CON SYNC)
  Future<int> asignarFamiliaMasivo({
    required StockType? nuevaFamilia,
    String? nuevaFamiliaCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final familiaAnterior = producto.familia;
        final familiaCustomAnterior = producto.familiaCustom;

        _productos[i] = producto.copyWith(
          familia: nuevaFamilia,
          familiaCustom: nuevaFamiliaCustom,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'familia',
          valorAnterior: familiaAnterior?.name ?? familiaCustomAnterior ?? 'Sin familia',
          valorNuevo: nuevaFamilia?.name ?? nuevaFamiliaCustom ?? 'Sin familia',
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en asignación masiva de familia: $e');
      return 0;
    }
  }

  /// Asignar marca masivamente (CON SYNC)
  Future<int> asignarMarcaMasivo({
    required Proveedor? nuevaMarca,
    String? nuevaMarcaCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final marcaAnterior = producto.marca;
        final marcaCustomAnterior = producto.marcaCustom;

        _productos[i] = producto.copyWith(
          marca: nuevaMarca,
          marcaCustom: nuevaMarcaCustom,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'marca',
          valorAnterior: marcaAnterior?.name ?? marcaCustomAnterior ?? 'Sin marca',
          valorNuevo: nuevaMarca?.name ?? nuevaMarcaCustom ?? 'Sin marca',
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en asignación masiva de marca: $e');
      return 0;
    }
  }

  /// Asignar grupo masivamente (CON SYNC)
  Future<int> asignarGrupoMasivo({
    required GroupType? nuevoGrupo,
    String? nuevoGrupoCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;
      List<Producto> productosModificados = [];
      List<CambioHistorial> cambiosBatch = [];

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final grupoAnterior = producto.grupo;
        final grupoCustomAnterior = producto.grupoCustom;

        _productos[i] = producto.copyWith(
          grupo: nuevoGrupo,
          grupoCustom: nuevoGrupoCustom,
          fechaModificacion: DateTime.now(),
        );

        productosModificados.add(_productos[i]);

        cambiosBatch.add(CambioHistorial(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'grupo',
          valorAnterior: grupoAnterior?.toString() ?? grupoCustomAnterior ?? 'Sin grupo',
          valorNuevo: nuevoGrupo?.toString() ?? nuevoGrupoCustom ?? 'Sin grupo',
        ));

        actualizados++;
      }

      if (actualizados > 0) {
        _historial.addAll(cambiosBatch);

        await _guardarEnLocal();

        if (_syncEnabled && productosModificados.isNotEmpty) {
          await _firebaseSync.syncProductos(productosModificados);
          await _firebaseSync.syncHistorial(cambiosBatch);
        }
      }

      return actualizados;
    } catch (e) {
      debugPrint('Error en asignación masiva de grupo: $e');
      return 0;
    }
  }

  /// Obtener historial de cambios
  Future<List<CambioHistorial>> getHistorial({String? productoId}) async {
    if (_syncEnabled) {
      // Obtener desde Firebase si está habilitado
      return await _firebaseSync.getHistorial(productoId: productoId);
    }

    if (productoId != null) {
      return _historial.where((h) => h.productoId == productoId).toList();
    }
    return List.from(_historial);
  }

  /// Cargar productos desde almacenamiento
  Future<void> _cargarProductos() async {
    try {
      if (_useFirebase && _firebaseService.isInitialized) {
        await _cargarDesdeFirebase();
      } else {
        await _cargarDesdeLocal();
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      _productos = [];
    }
  }

  /// Cargar desde archivo local
  Future<void> _cargarDesdeLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catalogoModificado = prefs.getString('catalogo_modificado');

      if (catalogoModificado != null) {
        final List<dynamic> jsonList = json.decode(catalogoModificado);
        _productos = jsonList.map((json) => Producto.fromJson(json)).toList();
      } else {
        final String jsonString = await rootBundle.loadString('assets/catalogo.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        _productos = jsonList.map((json) => Producto.fromJson(json)).toList();
      }

      final historialJson = prefs.getString('catalogo_historial');
      if (historialJson != null) {
        final List<dynamic> historialList = json.decode(historialJson);
        _historial = historialList.map((json) => CambioHistorial.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error al cargar desde local: $e');
      _productos = [];
    }
  }

  /// Guardar productos en almacenamiento
  Future<void> _guardarProductos() async {
    try {
      // Siempre guardar backup local primero
      await _guardarEnLocal();

      // Solo sincronizar con Firebase si está habilitado
      // (evitar doble sincronización en operaciones masivas)
      if (_useFirebase && _firebaseService.isInitialized && !_syncEnabled) {
        await _guardarEnFirebase();
      }
    } catch (e) {
      debugPrint('Error al guardar productos: $e');
    }
  }

  /// Guardar en SharedPreferences
  Future<void> _guardarEnLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _productos.map((p) => p.toJson()).toList();
      await prefs.setString('catalogo_modificado', json.encode(jsonList));

      final historialLimitado = _historial.length > 100
          ? _historial.sublist(_historial.length - 100)
          : _historial;
      final historialJson = historialLimitado.map((h) => h.toJson()).toList();
      await prefs.setString('catalogo_historial', json.encode(historialJson));
    } catch (e) {
      debugPrint('Error al guardar en local: $e');
    }
  }

  /// Cargar desde Firebase
  Future<void> _cargarDesdeFirebase() async {
    try {
      debugPrint('🔄 Intentando cargar catálogo desde Firebase...');

      // Usar timeout global para toda la operación
      _productos = await _firebaseSync.getProductos().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⏱️ Timeout cargando productos');
          return [];
        },
      );

      _historial = await _firebaseSync.getHistorial().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout cargando historial');
          return [];
        },
      );

      if (_productos.isNotEmpty) {
        debugPrint('✅ Cargados ${_productos.length} productos desde Firebase');
        // Guardar backup local
        await _guardarEnLocal();
      } else {
        debugPrint('⚠️ Firebase no tiene productos, usando local');
        await _cargarDesdeLocal();
      }
    } catch (e) {
      debugPrint('❌ Error al cargar desde Firebase: $e');
      // Fallback a local si falla Firebase
      await _cargarDesdeLocal();
    }
  }

  /// Guardar en Firebase
  Future<void> _guardarEnFirebase() async {
    try {
      await _firebaseSync.syncProductos(_productos);
      await _firebaseSync.syncHistorial(_historial);
    } catch (e) {
      debugPrint('Error al guardar en Firebase: $e');
    }
  }

  /// Comparar productos y registrar cambios
  Future<void> _compararYRegistrarCambios(
    Producto anterior,
    Producto nuevo,
  ) async {
    if (anterior.precio != nuevo.precio) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'precio',
        valorAnterior: anterior.precio.toString(),
        valorNuevo: nuevo.precio.toString(),
      );
    }

    if (anterior.nombre != nuevo.nombre) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'nombre',
        valorAnterior: anterior.nombre,
        valorNuevo: nuevo.nombre,
      );
    }

    if (anterior.tipo != nuevo.tipo) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'tipo',
        valorAnterior: anterior.tipo,
        valorNuevo: nuevo.tipo,
      );
    }

    if (anterior.marca != nuevo.marca || anterior.marcaCustom != nuevo.marcaCustom) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'marca',
        valorAnterior: anterior.marca?.name ?? anterior.marcaCustom,
        valorNuevo: nuevo.marca?.name ?? nuevo.marcaCustom,
      );
    }

    if (anterior.familia != nuevo.familia ||
        anterior.familiaCustom != nuevo.familiaCustom) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'familia',
        valorAnterior: anterior.familia?.name ?? anterior.familiaCustom,
        valorNuevo: nuevo.familia?.name ?? nuevo.familiaCustom,
      );
    }

    if (anterior.grupo != nuevo.grupo || anterior.grupoCustom != nuevo.grupoCustom) {
      await _registrarCambio(
        productoId: nuevo.id,
        nombreProducto: nuevo.nombre,
        campo: 'grupo',
        valorAnterior: anterior.grupo?.toString() ?? anterior.grupoCustom,
        valorNuevo: nuevo.grupo?.toString() ?? nuevo.grupoCustom,
      );
    }
  }

  /// Registrar cambio en historial (CON SYNC)
  Future<void> _registrarCambio({
    required String productoId,
    required String nombreProducto,
    required String campo,
    String? valorAnterior,
    String? valorNuevo,
  }) async {
    final cambio = CambioHistorial(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productoId: productoId,
      nombreProducto: nombreProducto,
      campo: campo,
      valorAnterior: valorAnterior,
      valorNuevo: valorNuevo,
    );

    _historial.add(cambio);

    // Sincronizar con Firebase si está habilitado
    if (_syncEnabled) {
      await _firebaseSync.registrarCambio(cambio);
    }
  }

  /// Recargar productos
  Future<void> recargar() async {
    _isLoaded = false;
    await _cargarProductos();
  }

  /// Obtener siguiente ID disponible
  Future<String> getNextId() async {
    if (!_isLoaded) {
      await _cargarProductos();
    }

    if (_productos.isEmpty) return '1';

    final ids =
        _productos.map((p) => int.tryParse(p.id) ?? 0).where((id) => id > 0).toList();

    if (ids.isEmpty) return '1';

    final maxId = ids.reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }

  /// Importar productos desde Excel
  /// Retorna un mapa con:
  /// - 'importados': cantidad de productos importados
  /// - 'actualizados': cantidad de productos actualizados
  /// - 'errores': lista de errores encontrados
  Future<Map<String, dynamic>> importarDesdeExcel(List<int> bytes) async {
    int importados = 0;
    int actualizados = 0;
    List<String> errores = [];

    try {
      // Decodificar Excel
      final excel = Excel.decodeBytes(bytes);

      // Buscar hoja "Catálogo"
      // if (!excel.tables.containsKey('Catálogo')) {
      //   throw Exception('No se encontró la hoja "Catálogo" en el archivo Excel');
      // }

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        throw Exception('El archivo Excel está vacío');
      }

      // Validar encabezados (primera fila)
      final headers = rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
      final expectedHeaders = [
        'ID',
        'Nombre',
        'Precio',
        'Tipo',
        'Marca',
        'Código Stock',
        'Familia',
        'Descripción',
        'Activo',
        'Es Oferta',
        'Fecha Creación',
        'Fecha Modificación',
      ];

      for (var i = 0; i < expectedHeaders.length && i < headers.length; i++) {
        if (headers[i] != expectedHeaders[i]) {
          errores.add(
              'Advertencia: Encabezado "${headers[i]}" no coincide con "${expectedHeaders[i]}"');
        }
      }

      // Procesar filas de datos (desde la segunda fila)
      for (var i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];

          // Saltar filas vacías
          if (row.isEmpty ||
              row.every(
                  (cell) => cell?.value == null || cell!.value.toString().isEmpty)) {
            continue;
          }

          // Extraer valores
          final id = row.isNotEmpty ? row[0]?.value?.toString() ?? '' : '';
          final nombre = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
          final precioStr = row.length > 2 ? row[2]?.value?.toString() ?? '0' : '0';
          final tipo = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';
          final marcaStr = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';
          final codigoStock = row.length > 5 ? row[5]?.value?.toString() : null;
          final familiaStr = row.length > 6 ? row[6]?.value?.toString() ?? '' : '';
          final descripcion = row.length > 7 ? row[7]?.value?.toString() : null;
          final activoStr = row.length > 8 ? row[8]?.value?.toString() ?? 'Sí' : 'Sí';
          final esOfertaStr = row.length > 9 ? row[9]?.value?.toString() ?? 'No' : 'No';

          // Validar campos obligatorios
          if (id.isEmpty || nombre.isEmpty || tipo.isEmpty) {
            errores.add('Fila ${i + 1}: Campos obligatorios vacíos (ID, Nombre o Tipo)');
            continue;
          }

          // Parsear precio
          final precio = int.tryParse(precioStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          if (precio < 0) {
            errores.add('Fila ${i + 1}: Precio inválido para producto $id');
            continue;
          }

          // Parsear marca
          Proveedor? marca;
          String? marcaCustom;
          if (marcaStr.isNotEmpty) {
            try {
              marca = Proveedor.values.firstWhere(
                (e) => e.name.toLowerCase() == marcaStr.toLowerCase(),
                orElse: () => Proveedor.otro,
              );
              if (marca == Proveedor.otro && marcaStr.toLowerCase() != 'otro') {
                marcaCustom = marcaStr;
              }
            } catch (e) {
              marca = Proveedor.otro;
              marcaCustom = marcaStr;
            }
          }

          // Parsear familia
          StockType? familia;
          String? familiaCustom;
          if (familiaStr.isNotEmpty) {
            try {
              familia = StockType.values.firstWhere(
                (e) => e.name.toLowerCase() == familiaStr.toLowerCase(),
                orElse: () => StockType.otro,
              );
              if (familia == StockType.otro && familiaStr.toLowerCase() != 'otro') {
                familiaCustom = familiaStr;
              }
            } catch (e) {
              familia = StockType.otro;
              familiaCustom = familiaStr;
            }
          }

          // Parsear activo y esOferta
          final activo = activoStr.toLowerCase() == 'sí' ||
              activoStr.toLowerCase() == 'si' ||
              activoStr.toLowerCase() == 'true' ||
              activoStr == '1';

          final esOferta = esOfertaStr.toLowerCase() == 'sí' ||
              esOfertaStr.toLowerCase() == 'si' ||
              esOfertaStr.toLowerCase() == 'true' ||
              esOfertaStr == '1';

          // Crear producto
          final producto = Producto(
            id: id,
            nombre: nombre,
            precio: precio,
            tipo: tipo,
            marca: marca,
            marcaCustom: marcaCustom,
            codigoStock: codigoStock?.isEmpty == true ? null : codigoStock,
            familia: familia,
            familiaCustom: familiaCustom,
            descripcion: descripcion?.isEmpty == true ? null : descripcion,
            activo: activo,
            esOferta: esOferta,
          );

          // Verificar si existe el producto
          final existe = _productos.any((p) => p.id == id);

          if (existe) {
            // Actualizar producto existente
            final success = await actualizarProducto(producto);
            if (success) {
              actualizados++;
            } else {
              errores.add('Fila ${i + 1}: Error al actualizar producto $id');
            }
          } else {
            // Crear nuevo producto
            final success = await crearProducto(producto);
            if (success) {
              importados++;
            } else {
              errores.add('Fila ${i + 1}: Error al crear producto $id');
            }
          }
        } catch (e) {
          errores.add('Fila ${i + 1}: Error al procesar - $e');
        }
      }

      // Registrar en historial
      await _registrarCambio(
        productoId: 'SISTEMA',
        nombreProducto: 'Importación Excel',
        campo: 'Importación',
        valorNuevo: 'Importados: $importados, Actualizados: $actualizados',
      );

      return {
        'importados': importados,
        'actualizados': actualizados,
        'errores': errores,
      };
    } catch (e) {
      print('Error al importar desde Excel: $e');
      errores.add('Error general: $e');
      return {
        'importados': importados,
        'actualizados': actualizados,
        'errores': errores,
      };
    }
  }
}
