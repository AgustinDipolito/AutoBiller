import 'dart:convert';

import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:dist_v2/models/item.dart';

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
        element.ultimoMov = cant;
        element.fechaMod = DateTime.now();
      }
    }
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
    notifyListeners();
  }

  void updateItem(Stock item) {
    stock = stock.map((e) {
      if (e.id == item.id) {
        e = item;
      }
      return e;
    }).toList();

    stockFiltered.clear();
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
    notifyListeners();
  }

  void createNew({
    required int cant,
    required String name,
    required Proveedor proveedor,
    required StockType type,
  }) {
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
        proveedor: proveedor,
        type: type,
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

  /// cant es cantidad maxima a buscar, busca menores a eso
  void searchLowerThan(int cant) {
    stockFiltered = stockFiltered.where((element) => element.cant < cant).toList();

    notifyListeners();
  }

  /// type es type o preveedor, cant es cantidad maxima a buscar, busca menores a eso
  void searchLowerThanWithType(int cant, dynamic type) {
    stockFiltered = stockFiltered
        .where((element) =>
            element.cant < cant && (element.type == type || element.proveedor == type))
        .toList();

    notifyListeners();
  }

  void searchByType(StockType type) {
    stockFiltered.clear();

    stockFiltered = stock.where((element) => element.type == type).toList();

    notifyListeners();
  }

  void searchByProvider(Proveedor provider) {
    stockFiltered.clear();

    stockFiltered = stock.where((element) => element.proveedor == provider).toList();

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

  void filterMovements() {
    stockFiltered = stock.where((element) => element.ultimoMov != 0).toList();

    notifyListeners();
  }
}
