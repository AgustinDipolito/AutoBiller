import 'dart:convert';

import 'package:dist_v2/models/item_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListaService with ChangeNotifier {
  List<ItemResponse> all = [];
  final List<ItemResponse> _all = [];

  void readJson() async {
    final response = await rootBundle.loadString("assets/catalogo.json");
    final data = await json.decode(response);
    int i = 0;
    all.clear();
    while (i < data.length) {
      all.add(ItemResponse.fromJson(data[i]));
      i++;
      final ids = <dynamic>{};
      all.retainWhere((x) => ids.add(x.id));
    }
    notifyListeners();
    _all.addAll(all);
  }

  void searchItem(String cad) {
    final itemf = _all.where((item) {
      final nombreLow = item.nombre.toLowerCase();
      final searchLow = cad.toLowerCase();

      return nombreLow.contains(searchLow);
    }).toList();

    all = itemf.isEmpty ? _all : itemf;
    notifyListeners();
  }

  void sort() {
    all.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

    notifyListeners();
  }
}
