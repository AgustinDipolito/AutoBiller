import 'dart:convert';

import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';

import '../models/stock.dart';

class StockService with ChangeNotifier {
  List<Stock> stock = [];
  List<Stock> stockFiltered = [];

  void removeByName(String name) {
    stock.removeWhere((element) => element.name == name);
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
    notifyListeners();
  }

  void addCantToItem(int id, {int cant = 1}) {
    for (var element in stock) {
      if (element.id == id) {
        element.cant += cant;

        element.fechaMod = DateTime.now();
      }
    }
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
    notifyListeners();
  }

  void createNew(int cant, String name) {
    int lastId = 0;

    if (stock.isNotEmpty) {
      sort();
      lastId = stock.last.id + 1;
    }

    if (stock.every((element) => element.id != lastId)) {
      stock.add(Stock(
        cant: cant,
        name: name,
        id: lastId,
        fechaMod: DateTime.now(),
        ultimoMov: cant,
      ));

      final stockJson = json.encode(stock);
      UserPreferences.setStock(stockJson, 'Unique');

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

  void sort() {
    stock.sort((a, b) => a.id.compareTo(b.id));

    notifyListeners();
  }

  init() {
    stock = UserPreferences.getStock();

    notifyListeners();
  }
}
