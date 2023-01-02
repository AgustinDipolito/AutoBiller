import 'dart:convert';

import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';

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
      ));

      final stockJson = json.encode(stock);
      UserPreferences.setStock(stockJson, 'Unique');
      // print('ID:::');
      // print(lastId);

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

class Stock {
  int cant;
  String name;
  final int id;

  Stock({required this.cant, required this.name, required this.id});

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        cant: int.parse(json['cant']),
        name: json['name'],
        id: int.parse(json['id']),
      );

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "cant": cant.toString(),
      "id": id.toString(),
    };
  }
}
