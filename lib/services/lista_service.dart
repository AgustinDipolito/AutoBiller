import 'dart:convert';

import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/item_response.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListaService with ChangeNotifier {
  List<ItemResponse> allView = [];
  final List<ItemResponse> _all = [];

  void readJson() async {
    final response = await rootBundle.loadString("assets/catalogo.json");
    final data = await json.decode(response);
    int i = 0;
    allView.clear();
    while (i < data.length) {
      allView.add(ItemResponse.fromJson(data[i]));
      i++;
      final ids = <dynamic>{};
      allView.retainWhere((x) => ids.add(x.id));
    }
    notifyListeners();
    _all.addAll(allView);
  }

  void searchItem(String cad, List<Pedido> pedidos) {
    allView.clear();
    final itemsFound = _all.where((item) {
      final nombreLow = item.nombre.toLowerCase();
      final searchLow = cad.toLowerCase();

      return nombreLow.contains(searchLow);
    }).toList();

    final allItems =
        pedidos.fold<List<Item>>([], (prev, element) => [...prev, ...element.lista]);

    final candidatos = allItems
        .where((item) => item.nombre.toLowerCase().contains(cad.toLowerCase()))
        .take(4)
        .map((e) => ItemResponse(e.nombre, e.tipo, e.precio, e.id.toString()))
        .toList();

    allView.addAll([...itemsFound, ...candidatos]);

    notifyListeners();
  }

  void sort() {
    allView.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

    notifyListeners();
  }
}
