import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/models/item.dart';
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
      // Find matching item once instead of multiple times
      final matchingItem = pedido.lista.firstWhere(
          (e) => e.nombre.trim().toUpperCase() == item.nombre.trim().toUpperCase(),
          orElse: () =>
              Item(nombre: 'error', precio: 0, cantidad: 0, id: 0, precioT: 0, tipo: ''));

      if (matchingItem.nombre != 'error') {
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
    for (var date = startDate; date.isBefore(today); date = date.add(Duration(days: 1))) {
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
