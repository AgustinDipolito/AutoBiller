import 'dart:convert';

import 'package:dist_v2/models/item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListaService with ChangeNotifier {
  List<Item> _todo = [];
  Future<List<Item>> get todo async => _todo.toSet().toList();

  void readJson() async {
    final response = await rootBundle.loadString("assets/catalogo.json");
    final data = await json.decode(response);
    int i = 0;
    while (i < data.length) {
      _todo.add(Item.fromJson(data[i]));
      i++;
      final ids = <dynamic>{};
      _todo.retainWhere((x) => ids.add(x.id));
    }
  }

  void searchItem(String cad) {
    final itemf = _todo.where((item) {
      final nombreLow = item.nombre.toLowerCase();
      final searchLow = cad.toLowerCase();

      return nombreLow.contains(searchLow);
    }).toList();

    _todo = itemf;
    notifyListeners();
  }

  void sort() {
    _todo.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

    notifyListeners();
  }
}
