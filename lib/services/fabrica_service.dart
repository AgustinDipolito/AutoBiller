import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import '../models/fabrica_item.dart';
import '../models/fabrica_source.dart';
import '../models/producto.dart';
import '../models/stock.dart';
import 'catalogo_service_with_firebase.dart';
import 'firebase_service.dart';

/// Servicio para gestionar fábricas/proveedores y sus archivos de productos
/// Almacena datos en Firebase Firestore
class FabricaService {
  static final FabricaService _instance = FabricaService._internal();
  factory FabricaService() => _instance;
  FabricaService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CatalogoService _catalogoService = CatalogoService();

  static const String _fabricasCollection = 'fabricas';
  static const String _fabricaItemsCollection = 'fabrica_items';

  List<FabricaSource> _fabricas = [];
  Map<String, List<FabricaItem>> _itemsPorFabrica = {};
  bool _isLoaded = false;

  // ==================== PUBLIC API ====================

  /// Obtener todas las fábricas
  Future<List<FabricaSource>> getFabricas() async {
    if (!_isLoaded) await _cargarDatos();
    return List.from(_fabricas);
  }

  /// Obtener fábrica por ID
  Future<FabricaSource?> getFabricaById(String id) async {
    if (!_isLoaded) await _cargarDatos();
    try {
      return _fabricas.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtener items de una fábrica
  Future<List<FabricaItem>> getItemsByFabrica(String fabricaId) async {
    if (!_isLoaded) await _cargarDatos();
    return List.from(_itemsPorFabrica[fabricaId] ?? []);
  }

  /// Obtener todos los items de todas las fábricas
  Future<List<FabricaItem>> getTodosLosItems() async {
    if (!_isLoaded) await _cargarDatos();
    return _itemsPorFabrica.values.expand((items) => items).toList();
  }

  /// Buscar items en todas las fábricas
  Future<List<FabricaItem>> buscarEnTodasFabricas(String query) async {
    if (!_isLoaded) await _cargarDatos();
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final allItems = _itemsPorFabrica.values.expand((items) => items).toList();
    return allItems.where((item) {
      return item.nombre.toLowerCase().contains(queryLower) ||
          (item.codigo?.toLowerCase().contains(queryLower) ?? false) ||
          (item.descripcion?.toLowerCase().contains(queryLower) ?? false) ||
          (item.categoria?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Comparar precios de un producto con fuzzy matching
  /// Retorna items similares de todas las fábricas + precio actual del catálogo si existe
  Future<Map<String, dynamic>> compararPrecios(String nombreProducto) async {
    if (!_isLoaded) await _cargarDatos();

    final allItems = _itemsPorFabrica.values.expand((items) => items).toList();

    // Fuzzy match con threshold
    final similares = <FabricaItem>[];
    final queryLower = nombreProducto.toLowerCase();

    for (final item in allItems) {
      final ratio = weightedRatio(nombreProducto, item.nombre);
      final containsMatch = item.nombre.toLowerCase().contains(queryLower) ||
          (item.codigo?.toLowerCase().contains(queryLower) ?? false);

      if (ratio >= 60 || containsMatch) {
        similares.add(item);
      }
    }

    // Ordenar por relevancia (mejor match primero)
    similares.sort((a, b) {
      final ratioA = weightedRatio(nombreProducto, a.nombre);
      final ratioB = weightedRatio(nombreProducto, b.nombre);
      return ratioB.compareTo(ratioA);
    });

    // Buscar en catálogo actual
    final productosActuales = await _catalogoService.getProductos();
    List<Producto> productosEnCatalogo = [];
    for (final p in productosActuales) {
      final ratio = weightedRatio(p.nombre, nombreProducto);
      final containsMatch = p.nombre.toLowerCase().contains(queryLower) ||
          (p.codigoStock?.toLowerCase().contains(queryLower) ?? false);

      if (ratio >= 70 || containsMatch) {
        productosEnCatalogo.add(p);
      }
    }

    return {
      'similares': similares,
      'productosEnCatalogo': productosEnCatalogo,
      'fabricas': _fabricas, // para resolver nombres
    };
  }

  /// Importar archivo Excel como nueva fábrica
  /// Retorna la fábrica creada con la preview de datos para mapeo
  Future<Map<String, dynamic>> prepararImportExcel({
    required List<int> bytes,
    required String fileName,
    required String nombreFabrica,
  }) async {
    try {
      final excel = Excel.decodeBytes(bytes);

      // Obtener hojas disponibles
      final hojas = excel.tables.keys.toList();
      if (hojas.isEmpty) {
        throw Exception('El archivo Excel está vacío');
      }

      // Usar primera hoja por defecto
      final hojaNombre = hojas.first;
      final sheet = excel.tables[hojaNombre]!;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        throw Exception('La hoja "$hojaNombre" está vacía');
      }

      // Extraer headers (primera fila)
      final headers = rows[0]
          .map((cell) => cell?.value?.toString() ?? '')
          .where((h) => h.isNotEmpty)
          .toList();

      // Auto-detectar mapeo de columnas
      final autoMapping = _autoDetectMapping(headers);

      // Obtener preview (primeras 5 filas de datos)
      final preview = <List<String>>[];
      for (var i = 1; i < rows.length && i <= 5; i++) {
        final row = rows[i].map((cell) => cell?.value?.toString() ?? '').toList();
        preview.add(row);
      }

      return {
        'hojas': hojas,
        'hojaSeleccionada': hojaNombre,
        'headers': headers,
        'autoMapping': autoMapping,
        'preview': preview,
        'totalRows': rows.length - 1, // sin header
      };
    } catch (e) {
      debugPrint('Error al preparar importación Excel: $e');
      rethrow;
    }
  }

  /// Confirmar importación con el mapeo definido por el usuario
  Future<FabricaSource> confirmarImportExcel({
    required List<int> bytes,
    required String fileName,
    required String nombreFabrica,
    required Map<String, String> columnMapping,
    String? hojaExcel,
    int filaInicio = 1,
    String? fabricaIdExistente, // para actualizar fábrica existente
  }) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final hoja = hojaExcel ?? excel.tables.keys.first;
      final sheet = excel.tables[hoja]!;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        throw Exception('La hoja "$hoja" está vacía');
      }

      // Headers
      final headers = rows[0].map((cell) => cell?.value?.toString() ?? '').toList();

      // Crear o actualizar fábrica
      final fabricaId =
          fabricaIdExistente ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Si se actualiza, eliminar items anteriores
      if (fabricaIdExistente != null) {
        await _eliminarItemsDeFabrica(fabricaIdExistente);
      }

      // Parsear items
      final items = <FabricaItem>[];
      for (var i = filaInicio; i < rows.length; i++) {
        final row = rows[i];

        // Saltar filas vacías
        if (row.isEmpty ||
            row.every(
                (cell) => cell?.value == null || cell!.value.toString().trim().isEmpty)) {
          continue;
        }

        // Construir rawData
        final rawData = <String, String>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          if (headers[j].isNotEmpty) {
            rawData[headers[j]] = row[j]?.value?.toString() ?? '';
          }
        }

        // Mapear campos
        String nombre = '';
        String? codigo;
        double? precio;
        String? descripcion;
        String? unidad;
        String? categoria;

        for (final entry in columnMapping.entries) {
          final headerName = entry.key; // nombre de la columna en el archivo
          final fieldName = entry.value; // campo mapeado (nombre, precio, etc)
          final value = rawData[headerName] ?? '';

          if (value.isEmpty) continue;

          switch (fieldName) {
            case FabricaFieldMapping.nombre:
              nombre = value;
              break;
            case FabricaFieldMapping.codigo:
              codigo = value;
              break;
            case FabricaFieldMapping.precio:
              precio = _parsePrecio(value);
              break;
            case FabricaFieldMapping.descripcion:
              descripcion = value;
              break;
            case FabricaFieldMapping.unidad:
              unidad = value;
              break;
            case FabricaFieldMapping.categoria:
              categoria = value;
              break;
          }
        }

        // Saltar si no tiene nombre
        if (nombre.isEmpty) continue;

        items.add(FabricaItem(
          id: '${fabricaId}_$i',
          fabricaSourceId: fabricaId,
          nombre: nombre,
          codigo: codigo,
          precio: precio,
          descripcion: descripcion,
          unidad: unidad,
          categoria: categoria,
          rawData: rawData,
        ));
      }

      final fabrica = FabricaSource(
        id: fabricaId,
        nombre: nombreFabrica,
        archivoNombre: fileName,
        tipoArchivo: 'xlsx',
        cantidadItems: items.length,
        columnMapping: columnMapping,
        hojaExcel: hoja,
        filaInicio: filaInicio,
        fechaActualizacion: fabricaIdExistente != null ? DateTime.now() : null,
      );

      // Guardar
      await _guardarFabrica(fabrica);
      await _guardarItems(fabricaId, items);

      // Actualizar cache local
      if (fabricaIdExistente != null) {
        _fabricas.removeWhere((f) => f.id == fabricaIdExistente);
      }
      _fabricas.add(fabrica);
      _itemsPorFabrica[fabricaId] = items;

      return fabrica;
    } catch (e) {
      debugPrint('Error al confirmar importación Excel: $e');
      rethrow;
    }
  }

  /// Registrar un PDF como referencia (sin parseo)
  Future<FabricaSource> importarPdf({
    required String fileName,
    required String nombreFabrica,
  }) async {
    final fabricaId = DateTime.now().millisecondsSinceEpoch.toString();

    final fabrica = FabricaSource(
      id: fabricaId,
      nombre: nombreFabrica,
      archivoNombre: fileName,
      tipoArchivo: 'pdf',
      cantidadItems: 0,
    );

    await _guardarFabrica(fabrica);
    _fabricas.add(fabrica);
    _itemsPorFabrica[fabricaId] = [];

    return fabrica;
  }

  /// Agregar item de fábrica al catálogo del usuario
  /// Aplica un porcentaje de markup al precio
  Future<Producto?> copiarACatalogo(
    FabricaItem item, {
    required double porcentajeMarkup,
    double porcentajeDescuento = 0,
  }) async {
    try {
      final nextId = await _catalogoService.getNextId();

      // Calcular precio: (base * (1 - desc)) * (1 + markup)
      final precioOriginal = item.precio ?? 0;
      final precioConDescuento = precioOriginal * (1 - porcentajeDescuento / 100);
      final precioFinal = (precioConDescuento * (1 + porcentajeMarkup / 100)).round();

      final fabricaNombre = getNombreFabrica(item.fabricaSourceId);

      // Intentar encontrar el proveedor en el enum, si no usar custom
      Proveedor marca = Proveedor.otro;
      String? marcaCustom;

      try {
        marca = Proveedor.values.firstWhere(
          (e) => e.name.toLowerCase() == fabricaNombre.toLowerCase(),
          orElse: () => Proveedor.otro,
        );
        if (marca == Proveedor.otro) {
          marcaCustom = fabricaNombre;
        }
      } catch (_) {
        marcaCustom = fabricaNombre;
      }

      final producto = Producto(
        id: nextId,
        nombre: item.nombre,
        precio: precioFinal,
        tipo: item.categoria ?? '',
        descripcion: item.descripcion,
        codigoStock: item.codigo,
        marca: marca,
        marcaCustom: marcaCustom,
      );

      final exito = await _catalogoService.crearProducto(producto);
      if (exito) {
        // Marcar item como agregado
        item.agregadoACatalogo = true;
        item.catalogoProductoId = nextId;
        await _actualizarItem(item);
        return producto;
      }
      return null;
    } catch (e) {
      debugPrint('Error al copiar al catálogo: $e');
      return null;
    }
  }

  /// Agregar múltiples items al catálogo
  Future<int> copiarMultiplesACatalogo(
    List<FabricaItem> items, {
    required double porcentajeMarkup,
    double porcentajeDescuento = 0,
  }) async {
    int agregados = 0;
    for (final item in items) {
      if (!item.agregadoACatalogo) {
        final resultado = await copiarACatalogo(
          item,
          porcentajeMarkup: porcentajeMarkup,
          porcentajeDescuento: porcentajeDescuento,
        );
        if (resultado != null) agregados++;
      }
    }
    return agregados;
  }

  /// Eliminar una fábrica y todos sus items
  Future<bool> eliminarFabrica(String fabricaId) async {
    try {
      await _eliminarItemsDeFabrica(fabricaId);
      await _firebaseService.deleteDocument(
        collection: _fabricasCollection,
        docId: fabricaId,
      );

      _fabricas.removeWhere((f) => f.id == fabricaId);
      _itemsPorFabrica.remove(fabricaId);

      return true;
    } catch (e) {
      debugPrint('Error al eliminar fábrica: $e');
      return false;
    }
  }

  /// Crear relación manual entre items de distintas fábricas
  Future<void> relacionarItems(String itemId1, String itemId2) async {
    final allItems = _itemsPorFabrica.values.expand((items) => items).toList();

    final item1 = allItems.firstWhere((i) => i.id == itemId1);
    final item2 = allItems.firstWhere((i) => i.id == itemId2);

    if (!item1.relacionesIds.contains(itemId2)) {
      item1.relacionesIds.add(itemId2);
      await _actualizarItem(item1);
    }
    if (!item2.relacionesIds.contains(itemId1)) {
      item2.relacionesIds.add(itemId1);
      await _actualizarItem(item2);
    }
  }

  /// Obtener nombre de fábrica por ID
  String getNombreFabrica(String fabricaId) {
    try {
      return _fabricas.firstWhere((f) => f.id == fabricaId).nombre;
    } catch (_) {
      return 'Desconocida';
    }
  }

  /// Forzar recarga desde Firebase
  Future<void> recargar() async {
    _isLoaded = false;
    await _cargarDatos();
  }

  // ==================== AUTO DETECTION ====================

  /// Auto-detectar mapeo de columnas basado en keywords
  Map<String, String> _autoDetectMapping(List<String> headers) {
    final mapping = <String, String>{};

    for (final header in headers) {
      final headerLower = header.toLowerCase().trim();

      for (final field in FabricaFieldMapping.allFields) {
        final keywords = FabricaFieldMapping.autoDetectKeywords[field] ?? [];

        for (final keyword in keywords) {
          if (headerLower.contains(keyword) && !mapping.containsValue(field)) {
            mapping[header] = field;
            break;
          }
        }
        if (mapping.containsKey(header)) break;
      }
    }

    return mapping;
  }

  /// Parsear precio de string con distintos formatos
  double? _parsePrecio(String value) {
    if (value.isEmpty) return null;

    // Limpiar: eliminar $, espacios, etc.
    var cleaned = value.replaceAll(RegExp(r'[^\d.,\-]'), '');

    if (cleaned.isEmpty) return null;

    // Manejar formato argentino: 1.234,56 → 1234.56
    if (cleaned.contains(',') && cleaned.contains('.')) {
      // Si el punto viene antes de la coma: 1.234,56
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');

      if (lastDot < lastComma) {
        // Formato: 1.234,56
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Formato: 1,234.56
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      // Solo coma: 1234,56 → 1234.56
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  // ==================== FIREBASE PERSISTENCE ====================

  Future<void> _cargarDatos() async {
    try {
      if (!_firebaseService.isInitialized) {
        await _firebaseService.initialize();
      }

      // Cargar fábricas
      final fabricasData = await _firebaseService.getCollection(
        collection: _fabricasCollection,
      );
      _fabricas = fabricasData.map((json) => FabricaSource.fromJson(json)).toList();

      // Cargar items de cada fábrica
      _itemsPorFabrica = {};
      for (final fabrica in _fabricas) {
        final itemsData = await _firebaseService.firestore
            .collection(_fabricaItemsCollection)
            .where('fabricaSourceId', isEqualTo: fabrica.id)
            .get();

        _itemsPorFabrica[fabrica.id] =
            itemsData.docs.map((doc) => FabricaItem.fromJson(doc.data())).toList();
      }

      _isLoaded = true;
      debugPrint('✅ FabricaService: ${_fabricas.length} fábricas cargadas');
    } catch (e) {
      debugPrint('❌ Error al cargar datos de fábricas: $e');
      _fabricas = [];
      _itemsPorFabrica = {};
      _isLoaded =
          true; // Marcar como loaded aunque falle para no reintentar infinitamente
    }
  }

  Future<void> _guardarFabrica(FabricaSource fabrica) async {
    try {
      await _firebaseService.setDocument(
        collection: _fabricasCollection,
        docId: fabrica.id,
        data: _firebaseService.addSyncMetadata(fabrica.toJson()),
      );
    } catch (e) {
      debugPrint('Error al guardar fábrica: $e');
      rethrow;
    }
  }

  Future<void> _guardarItems(String fabricaId, List<FabricaItem> items) async {
    try {
      // Batch write en chunks de 100
      final operations = items.map((item) {
        return {
          'collection': _fabricaItemsCollection,
          'docId': item.id,
          'type': 'set',
          'data': _firebaseService.addSyncMetadata(item.toJson()),
        };
      }).toList();

      if (operations.isNotEmpty) {
        await _firebaseService.batchWrite(operations: operations);
      }
    } catch (e) {
      debugPrint('Error al guardar items de fábrica: $e');
      rethrow;
    }
  }

  Future<void> _actualizarItem(FabricaItem item) async {
    try {
      await _firebaseService.setDocument(
        collection: _fabricaItemsCollection,
        docId: item.id,
        data: _firebaseService.addSyncMetadata(item.toJson()),
      );

      // Actualizar cache local
      final items = _itemsPorFabrica[item.fabricaSourceId];
      if (items != null) {
        final idx = items.indexWhere((i) => i.id == item.id);
        if (idx >= 0) {
          items[idx] = item;
        }
      }
    } catch (e) {
      debugPrint('Error al actualizar item: $e');
    }
  }

  Future<void> _eliminarItemsDeFabrica(String fabricaId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_fabricaItemsCollection)
          .where('fabricaSourceId', isEqualTo: fabricaId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final operations = snapshot.docs.map((doc) {
        return <String, dynamic>{
          'collection': _fabricaItemsCollection,
          'docId': doc.id,
          'type': 'delete',
        };
      }).toList();

      await _firebaseService.batchWrite(operations: operations);
    } catch (e) {
      debugPrint('Error al eliminar items de fábrica: $e');
    }
  }
}
