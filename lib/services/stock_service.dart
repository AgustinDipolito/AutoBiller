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
        ultCant: cant,
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

  void setLastNumber(int id, int cant) {
    for (var element in stock) {
      if (element.id == id) {
        element.ultCant = cant;
      }
    }
    final stockJson = json.encode(stock);
    UserPreferences.setStock(stockJson, 'Unique');
    notifyListeners();
  }
}

class Stock {
  final int id;
  int cant;
  String name;
  DateTime fechaMod;
  int ultCant;

  Stock(
      {required this.fechaMod,
      required this.ultCant,
      required this.cant,
      required this.name,
      required this.id});

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        cant: int.parse(json['cant']),
        name: json['name'],
        id: int.parse(json['id']),
        fechaMod: json['date'] != null ? DateTime.parse(json['date']) : DateTime(2023),
        ultCant: json['ultimaCant'] != null ? int.parse(json['ultimaCant']) : 0,
      );

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "cant": cant.toString(),
      "id": id.toString(),
      "date": fechaMod.toString(),
      "ultimaCant": ultCant.toString(),
    };
  }
}
