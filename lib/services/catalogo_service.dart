import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import '../models/producto.dart';
import '../models/stock.dart' show StockType, Proveedor, GroupType;

/// Servicio para gestionar el catálogo de productos
/// Preparado para migración a Firebase (cambiar _useFirebase a true)
class CatalogoService {
  static final CatalogoService _instance = CatalogoService._internal();
  factory CatalogoService() => _instance;
  CatalogoService._internal();

  // Flag para alternar entre local y Firebase (para migración futura)

  List<Producto> _productos = [];
  List<CambioHistorial> _historial = [];

  bool _isLoaded = false;

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

  /// Crear nuevo producto
  Future<bool> crearProducto(Producto producto) async {
    try {
      // Verificar que no exista el ID
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

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar producto existente
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
      );

      _productos[index] = productoActualizado;
      await _guardarProductos();

      return true;
    } catch (e) {
      return false;
    }
  }

  /*
  /// Eliminar producto - DESHABILITADO POR SEGURIDAD
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

      return true;
    } catch (e) {
      print('Error al eliminar producto: $e');
      return false;
    }
  }
  */

  /// Actualización masiva de precios
  /// [porcentaje] puede ser positivo (incremento) o negativo (descuento)
  /// [filtros] permite aplicar solo a ciertos productos (por familia, marca, etc)
  Future<int> actualizarPreciosMasivo({
    required double porcentaje,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Aplicar filtros
        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        // Calcular nuevo precio
        final precioAnterior = producto.precio;
        final nuevoPrecio = (precioAnterior * (1 + porcentaje / 100)).round();

        // Actualizar
        _productos[i] = producto.copyWith(
          precio: nuevoPrecio,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: nuevoPrecio.toString(),
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Sumar monto fijo a precios masivamente
  Future<int> sumarAPreciosMasivo({
    required int monto,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Aplicar filtros
        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        // Calcular nuevo precio
        final precioAnterior = producto.precio;
        final nuevoPrecio = precioAnterior + monto;

        // Validar que el precio no sea negativo
        if (nuevoPrecio < 0) continue;

        // Actualizar
        _productos[i] = producto.copyWith(
          precio: nuevoPrecio,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: nuevoPrecio.toString(),
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Asignar precio fijo masivamente
  Future<int> asignarPrecioMasivo({
    required int precio,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Aplicar filtros
        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final precioAnterior = producto.precio;

        // Actualizar
        _productos[i] = producto.copyWith(
          precio: precio,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'precio',
          valorAnterior: precioAnterior.toString(),
          valorNuevo: precio.toString(),
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Activar/Desactivar productos masivamente
  Future<int> cambiarEstadoMasivo({
    required bool activo,
    StockType? familia,
    Proveedor? marca,
    GroupType? tipo,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Aplicar filtros
        if (familia != null && producto.familia != familia) continue;
        if (marca != null && producto.marca != marca) continue;
        if (tipo != null && producto.grupo != tipo) continue;

        final estadoAnterior = producto.activo;

        // Actualizar
        _productos[i] = producto.copyWith(
          activo: activo,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'estado',
          valorAnterior: estadoAnterior ? 'Activo' : 'Inactivo',
          valorNuevo: activo ? 'Activo' : 'Inactivo',
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Asignar familia masivamente
  Future<int> asignarFamiliaMasivo({
    required StockType? nuevaFamilia,
    String? nuevaFamiliaCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Si se especificaron IDs, solo actualizar esos productos
        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final familiaAnterior = producto.familia;
        final familiaCustomAnterior = producto.familiaCustom;

        // Actualizar
        _productos[i] = producto.copyWith(
          familia: nuevaFamilia,
          familiaCustom: nuevaFamiliaCustom,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'familia',
          valorAnterior: familiaAnterior?.name ?? familiaCustomAnterior ?? 'Sin familia',
          valorNuevo: nuevaFamilia?.name ?? nuevaFamiliaCustom ?? 'Sin familia',
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Asignar marca masivamente
  Future<int> asignarMarcaMasivo({
    required Proveedor? nuevaMarca,
    String? nuevaMarcaCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Si se especificaron IDs, solo actualizar esos productos
        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final marcaAnterior = producto.marca;
        final marcaCustomAnterior = producto.marcaCustom;

        // Actualizar
        _productos[i] = producto.copyWith(
          marca: nuevaMarca,
          marcaCustom: nuevaMarcaCustom,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'marca',
          valorAnterior: marcaAnterior?.name ?? marcaCustomAnterior ?? 'Sin marca',
          valorNuevo: nuevaMarca?.name ?? nuevaMarcaCustom ?? 'Sin marca',
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Asignar grupo masivamente
  Future<int> asignarGrupoMasivo({
    required GroupType? nuevoGrupo,
    String? nuevoGrupoCustom,
    List<String>? productosIds,
  }) async {
    try {
      int actualizados = 0;

      for (var i = 0; i < _productos.length; i++) {
        final producto = _productos[i];

        // Si se especificaron IDs, solo actualizar esos productos
        if (productosIds != null && !productosIds.contains(producto.id)) continue;

        final grupoAnterior = producto.grupo;
        final grupoCustomAnterior = producto.grupoCustom;

        // Actualizar
        _productos[i] = producto.copyWith(
          grupo: nuevoGrupo,
          grupoCustom: nuevoGrupoCustom,
          fechaModificacion: DateTime.now(),
        );

        // Registrar cambio
        await _registrarCambio(
          productoId: producto.id,
          nombreProducto: producto.nombre,
          campo: 'grupo',
          valorAnterior: grupoAnterior?.toString() ?? grupoCustomAnterior ?? 'Sin grupo',
          valorNuevo: nuevoGrupo?.toString() ?? nuevoGrupoCustom ?? 'Sin grupo',
        );

        actualizados++;
      }

      if (actualizados > 0) {
        await _guardarProductos();
      }

      return actualizados;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener historial de cambios (últimos 100)
  Future<List<CambioHistorial>> getHistorial({String? productoId}) async {
    if (productoId != null) {
      return _historial.where((h) => h.productoId == productoId).toList();
    }
    return List.from(_historial);
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

  /// Obtener familias únicas (para filtros) - Ya no se usa, los enums se obtienen directamente
  @Deprecated('Use StockType.values directamente')
  Future<List<String>> getFamilias() async {
    return StockType.values.map((e) => e.name).toList();
  }

  /// Obtener marcas únicas (para filtros) - Ya no se usa, los enums se obtienen directamente
  @Deprecated('Use Proveedor.values directamente')
  Future<List<String>> getMarcas() async {
    return Proveedor.values.map((e) => e.name).toList();
  }

  /// Obtener tipos únicos (para filtros) - Ya no se usa, los enums se obtienen directamente
  @Deprecated('Use groupType.values directamente')
  Future<List<String>> getTipos() async {
    return GroupType.values.map((e) => e.toString()).toList();
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Cargar productos desde almacenamiento
  Future<void> _cargarProductos() async {
    try {
      await _cargarDesdeLocal();
      _isLoaded = true;
    } catch (e) {
      _productos = [];
    }
  }

  /// Cargar desde archivo local
  Future<void> _cargarDesdeLocal() async {
    try {
      // Intentar cargar desde archivo modificado
      final prefs = await SharedPreferences.getInstance();
      final catalogoModificado = prefs.getString('catalogo_modificado');

      if (catalogoModificado != null) {
        final List<dynamic> jsonList = json.decode(catalogoModificado);
        _productos = jsonList.map((json) => Producto.fromJson(json)).toList();
      } else {
        // Cargar desde assets (primera vez)
        final String jsonString = await rootBundle.loadString('assets/catalogo.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        _productos = jsonList.map((json) => Producto.fromJson(json)).toList();
      }

      // Cargar historial
      final historialJson = prefs.getString('catalogo_historial');
      if (historialJson != null) {
        final List<dynamic> historialList = json.decode(historialJson);
        _historial = historialList.map((json) => CambioHistorial.fromJson(json)).toList();
      }
    } catch (e) {
      _productos = [];
    }
  }

  /// Guardar productos en almacenamiento
  Future<void> _guardarProductos() async {
    try {
      await _guardarEnLocal();
    } catch (_) {}
  }

  /// Guardar en SharedPreferences
  Future<void> _guardarEnLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _productos.map((p) => p.toJson()).toList();
      await prefs.setString('catalogo_modificado', json.encode(jsonList));

      // Guardar historial (últimos 100 cambios)
      final historialLimitado = _historial.length > 100
          ? _historial.sublist(_historial.length - 100)
          : _historial;
      final historialJson = historialLimitado.map((h) => h.toJson()).toList();
      await prefs.setString('catalogo_historial', json.encode(historialJson));
    } catch (_) {}
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

  /// Registrar cambio en historial
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

    // Mantener solo últimos 100 cambios en memoria
    if (_historial.length > 100) {
      _historial = _historial.sublist(_historial.length - 100);
    }
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
      if (!excel.tables.containsKey('Catálogo')) {
        throw Exception('No se encontró la hoja "Catálogo" en el archivo Excel');
      }

      final sheet = excel.tables['Catálogo']!;
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
      errores.add('Error general: $e');
      return {
        'importados': importados,
        'actualizados': actualizados,
        'errores': errores,
      };
    }
  }

  /// Recargar productos (útil después de importar)
  Future<void> recargar() async {
    _isLoaded = false;
    await _cargarProductos();
  }
}
