import 'package:collection/collection.dart';
import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/helpers/fuzzy_matcher.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:flutter/material.dart';

class AnalysisService with ChangeNotifier {
  List<VipItem> vipItems = <VipItem>[];
  int i = 0;
  List<VipItem> _filteredItems = <VipItem>[];

  // Add getter for filtered items
  List<VipItem> get filteredItems => _filteredItems.isEmpty ? vipItems : _filteredItems;

  // Add search method
  void searchItems(String query) {
    if (query.isEmpty) {
      _filteredItems.clear();
      notifyListeners();
      return;
    }

    _filteredItems = vipItems.where((item) {
      final nameLower = item.nombre.toLowerCase();
      final searchLower = query.toLowerCase();

      return nameLower.contains(searchLower);
    }).toList();

    // Sort results by relevance
    _filteredItems.sort((a, b) {
      final aStarts = a.nombre.toLowerCase().startsWith(query.toLowerCase());
      final bStarts = b.nombre.toLowerCase().startsWith(query.toLowerCase());

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return a.nombre.compareTo(b.nombre);
    });

    notifyListeners();
  }

  // Update clearAll to also clear filtered items
  void clearAll() {
    vipItems.clear();
    _filteredItems.clear();
    notifyListeners();
  }

  void init(List<Pedido> pedidos) {
// get shared_preferences y sino checar historial si hay procesarlo, en caso negativo, list vacia
    clearAll();
    for (var pedido in pedidos) {
      for (var it in pedido.lista) {
        var vip = VipItem(
          id: it.id,
          cantTotal: it.cantidad,
          recaudado: it.precioT,
          nombre: it.nombre.trim(),
        );
        var pos = vipItems.indexWhere((element) =>
            element.nombre.trim().toUpperCase() == vip.nombre.trim().toUpperCase());

        if (pos < 0) {
          vipItems.add(vip);
        } else {
          addInfo(vip, pos);
        }
      }
    }

    notifyListeners();
  }

  // gen time series for item with cant
  Map<DateTime, int> getItemTimeSeries(VipItem item, List<Pedido> pedidos) {
    List<DateTime> dates = [];
    List<int> cant = [];

    for (var pedido in pedidos) {
      // Find matching item using fuzzy matching to handle name variations
      final itemNames = pedido.lista.map((e) => e.nombre).toList();
      final matchResult = FuzzyMatcher.findBestMatch(
        item.nombre,
        itemNames,
        minConfidence: 85,
      );

      if (matchResult != null) {
        final matchingItem = pedido.lista[matchResult.index];
        final normalizedDate =
            DateTime(pedido.fecha.year, pedido.fecha.month, pedido.fecha.day);

        final indexDate = dates.indexOf(normalizedDate);
        if (indexDate >= 0) {
          cant[indexDate] += matchingItem.cantidad;
        } else {
          dates.add(normalizedDate);
          cant.add(matchingItem.cantidad);
        }
      }
    }

    Map<DateTime, int> timeSeries = {};
    for (int i = 0; i < dates.length; i++) {
      timeSeries[dates[i]] = cant[i];
    }

// completes day with 0 sells

    // ignore: sdk_version_since
    final startDate = dates.lastOrNull ?? DateTime.now();
    final today = DateTime.now();

    // for startDate to today, if date is not in dates, add it with 0 sells
    for (var date = startDate;
        date.isBefore(today);
        date = date.add(const Duration(days: 1))) {
      if (!dates.contains(date)) {
        timeSeries[date] = 0;
      }
    }
    // sort by date
    timeSeries = Map.fromEntries(
        timeSeries.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));

    return timeSeries;
  }

  void addInfo(VipItem vip, int index) {
    if (vipItems.isEmpty) {
      vipItems.add(vip);
      return;
    }
    vipItems[index].cantTotal += vip.cantTotal;
    vipItems[index].recaudado += vip.recaudado;
    vipItems[index].repeticiones++;
  }

  // notifyListeners();

  /// Calculates statistics for a specific product based on sales history
  /// Used for stock level recommendations
  Map<String, num> calculateProductStats(VipItem item, List<Pedido> pedidos) {
    final timeSeries = getItemTimeSeries(item, pedidos);

    // Group by week (starting Monday)
    final Map<DateTime, int> weeklyMovements = {};
    for (var entry in timeSeries.entries) {
      final weekStart = entry.key.subtract(
        Duration(days: entry.key.weekday - 1),
      );
      weeklyMovements.update(
        weekStart,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }

    if (weeklyMovements.isEmpty) {
      return {
        'avgWeeklySales': 0,
        'minSales': 0,
        'maxSales': 0,
        'efficiency': 0,
        'totalWeeks': 0,
        'zeroSalesWeeks': 0,
        'trend': 0,
      };
    }

    final nonZeroSales = weeklyMovements.values.where((e) => e > 0);
    final totalWeeks = weeklyMovements.values.length;
    final sortedSales = weeklyMovements.values.toList()..sort();
    final avgWeeklySales = sortedSales.isEmpty
      ? 0
      : (sortedSales.length.isOdd
        ? sortedSales[sortedSales.length ~/ 2]
        : ((sortedSales[sortedSales.length ~/ 2 - 1] + sortedSales[sortedSales.length ~/ 2]) / 2).ceil());
    final minSales = nonZeroSales.isEmpty ? 0 : nonZeroSales.min;
    final maxSales = nonZeroSales.isEmpty ? 0 : nonZeroSales.max;
    final zeroSalesWeeks = totalWeeks - nonZeroSales.length;
    final efficiency = weeklyMovements.values.isEmpty
        ? 0
        : ((nonZeroSales.length / totalWeeks) * 100).round();
    final trend = nonZeroSales.isEmpty || nonZeroSales.length < 2
        ? 0
        : ((nonZeroSales.last - nonZeroSales.first) / nonZeroSales.first * 100).round();

    return {
      'avgWeeklySales': avgWeeklySales,
      'minSales': minSales,
      'maxSales': maxSales,
      'efficiency': efficiency,
      'totalWeeks': totalWeeks,
      'zeroSalesWeeks': zeroSalesWeeks,
      'trend': trend,
    };
  }

  List<VipItem> getTopRaised({int? limit}) {
    vipItems.sort((a, b) => b.recaudado.compareTo(a.recaudado));
    var tops = vipItems.sublist(0, limit);
    return tops;
  }

  List<VipItem> getTopSelled({int? limit}) {
    vipItems.sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
    var tops = vipItems.sublist(0, limit);
    return tops;
  }

  List<VipItem> sortList(SortBy by) {
    switch (by) {
      case SortBy.nameUp:
        vipItems.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case SortBy.nameDown:
        vipItems.sort((a, b) => b.nombre.compareTo(a.nombre));
        break;
      case SortBy.raisedUp:
        vipItems.sort((a, b) => a.recaudado.compareTo(b.recaudado));
        break;
      case SortBy.raisedDown:
        vipItems.sort((a, b) => b.recaudado.compareTo(a.recaudado));
        break;
      case SortBy.repsUp:
        vipItems.sort((a, b) => a.repeticiones.compareTo(b.repeticiones));
        break;
      case SortBy.repsDown:
        vipItems.sort((a, b) => b.repeticiones.compareTo(a.repeticiones));
        break;
      case SortBy.cantUp:
        vipItems.sort((a, b) => a.cantTotal.compareTo(b.cantTotal));
        break;
      case SortBy.cantDown:
        vipItems.sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
        break;
    }
    notifyListeners();
    return vipItems;
    // notifyListeners();
  }

  void export() async {
    final rows = [VipItem.propTittles, ...vipItems.map((e) => e.toString())];
    await FileApi.createCSV(rows, 'vip_items');
  }

  /// Exporta un dataset completo para minería de datos
  /// Incluye métricas agregadas por producto y métricas temporales
  Future<void> exportDataset(List<Pedido> pedidos) async {
    final rows = <String>[];

    // Header con todas las columnas relevantes
    rows.add('producto_id,producto_nombre,cantidad_total,repeticiones,recaudado_total,'
        'precio_promedio,precio_min,precio_max,primer_venta,ultima_venta,'
        'dias_activo,frecuencia_venta_dias,recaudado_por_venta,cantidad_por_venta,'
        'variacion_precio,es_producto_frecuente,es_alto_valor,categoria_volumen');

    // Calcular métricas por producto
    for (var vipItem in vipItems) {
      // Obtener todas las ventas del producto
      final ventasProducto = <Map<String, dynamic>>[];
      final precios = <int>[];

      for (var pedido in pedidos) {
        for (var item in pedido.lista) {
          if (item.nombre.trim().toUpperCase() == vipItem.nombre.trim().toUpperCase()) {
            ventasProducto.add({
              'fecha': pedido.fecha,
              'cantidad': item.cantidad,
              'precio': item.precio,
              'precioTotal': item.precioT,
              'cliente': pedido.nombre,
            });
            precios.add(item.precio);
          }
        }
      }

      if (ventasProducto.isEmpty) continue;

      // Ordenar por fecha
      ventasProducto
          .sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));

      final primerVenta = ventasProducto.first['fecha'] as DateTime;
      final ultimaVenta = ventasProducto.last['fecha'] as DateTime;
      final diasActivo = ultimaVenta.difference(primerVenta).inDays + 1;

      // Métricas de precio
      final precioPromedio = precios.reduce((a, b) => a + b) / precios.length;
      final precioMin = precios.reduce((a, b) => a < b ? a : b);
      final precioMax = precios.reduce((a, b) => a > b ? a : b);
      final variacionPrecio = precioMax - precioMin;

      // Métricas de frecuencia
      final frecuenciaVentaDias = diasActivo > 0 ? vipItem.repeticiones / diasActivo : 0;
      final recaudadoPorVenta =
          vipItem.repeticiones > 0 ? vipItem.recaudado / vipItem.repeticiones : 0;
      final cantidadPorVenta =
          vipItem.repeticiones > 0 ? vipItem.cantTotal / vipItem.repeticiones : 0;

      // Clasificaciones
      final esProductoFrecuente = vipItem.repeticiones >= 30 ? 1 : 0;
      final esAltoValor = vipItem.recaudado >= 50000 ? 1 : 0;

      String categoriaVolumen;
      if (vipItem.cantTotal >= 30) {
        categoriaVolumen = 'alto';
      } else if (vipItem.cantTotal >= 10) {
        categoriaVolumen = 'medio';
      } else {
        categoriaVolumen = 'bajo';
      }

      // Escapar nombre para CSV
      final nombreEscapado = vipItem.nombre.contains(',')
          ? '"${vipItem.nombre.replaceAll('"', '""')}"'
          : vipItem.nombre;

      rows.add('${vipItem.id},'
          '$nombreEscapado,'
          '${vipItem.cantTotal},'
          '${vipItem.repeticiones},'
          '${vipItem.recaudado},'
          '${precioPromedio.toStringAsFixed(2)},'
          '$precioMin,'
          '$precioMax,'
          '${primerVenta.toIso8601String()},'
          '${ultimaVenta.toIso8601String()},'
          '$diasActivo,'
          '${frecuenciaVentaDias.toStringAsFixed(4)},'
          '${recaudadoPorVenta.toStringAsFixed(2)},'
          '${cantidadPorVenta.toStringAsFixed(2)},'
          '$variacionPrecio,'
          '$esProductoFrecuente,'
          '$esAltoValor,'
          '$categoriaVolumen');
    }

    await FileApi.createCSV(
        rows, 'dataset_productos_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Exporta dataset de transacciones individuales (nivel pedido-item)
  Future<void> exportTransactionDataset(List<Pedido> pedidos) async {
    final rows = <String>[];

    // Header
    rows.add('pedido_id,fecha,año,mes,dia,dia_semana,cliente,'
        'producto_id,producto_nombre,cantidad,precio_unitario,precio_total,'
        'total_pedido,items_en_pedido,es_cliente_frecuente');

    // Contador de pedidos por cliente
    final clienteFrecuencia = <String, int>{};
    for (var pedido in pedidos) {
      clienteFrecuencia[pedido.nombre] = (clienteFrecuencia[pedido.nombre] ?? 0) + 1;
    }

    // [<[<[#b3349]>]>] suele venir asi, solo quedarse con letras y numeros.
    final keyRegex = RegExp(r'[^a-zA-Z0-9]');

    // Generar filas por cada item de cada pedido
    for (var pedido in pedidos) {
      final pKeyFormatted = pedido.key.toString().replaceAll(keyRegex, '');

      if (pKeyFormatted.isEmpty) {
        continue;
      }

      final esClienteFrecuente = (clienteFrecuencia[pedido.nombre] ?? 0) >= 3 ? 1 : 0;
      final itemsEnPedido = pedido.lista.length;

      for (var item in pedido.lista) {
        // Limpiar nombre: remover comas, saltos de línea, tabs y espacios múltiples
        final nombreEscapado = item.nombre
            .replaceAll(',', '')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll('\t', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        // Limpiar cliente de la misma manera
        final clienteEscapado = pedido.nombre
            .replaceAll(',', '')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll('\t', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (item.cantidad <= 0) {
          continue;
        }

        rows.add('$pKeyFormatted,'
            '${pedido.fecha.toIso8601String()},'
            '${pedido.fecha.year},'
            '${pedido.fecha.month},'
            '${pedido.fecha.day},'
            '${pedido.fecha.weekday},'
            '$clienteEscapado,'
            '${item.id},'
            '$nombreEscapado,'
            '${item.cantidad},'
            '${item.precio},'
            '${item.precioT},'
            '${pedido.total},'
            '$itemsEnPedido,'
            '$esClienteFrecuente');
      }
    }

    await FileApi.createCSV(
        rows, 'dataset_transacciones_${DateTime.now().millisecondsSinceEpoch}');
  }
}

enum SortBy {
  nameUp,
  nameDown,
  raisedUp,
  raisedDown,
  repsUp,
  repsDown,
  cantUp,
  cantDown,
}
