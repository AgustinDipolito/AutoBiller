import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/services/stock_service.dart';

class UserPreferences {
  static SharedPreferences? _preferences;
  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setPedido(String lista, String key) async {
    await _preferences!.setString("pedidos$key", lista);
  }

  static Future setStock(String stock, String key) async {
    await _preferences!.setString("stock$key", stock);
  }

  static List<Stock> getStock() {
    var key = _preferences!
        .getKeys()
        .firstWhere((element) => element.startsWith('stock'));
    // _preferences!.remove('stock1');
    // _preferences!.remove('stock2');

    try {
      List<Stock> stock = <Stock>[];

      final json = _preferences!.getString(key) ?? '';

      if (json.isNotEmpty) {
        final maps = jsonDecode(json);
        for (var map in maps) {
          final itemStock = Stock.fromJson(map);

          stock.add(itemStock);
        }
      }

      return stock;
    } catch (e) {
      return [];
    }
  }

  static List<Pedido> getPedidos() {
    var keys = _preferences!
        .getKeys()
        .where((element) => element.startsWith('pedido'));

    try {
      List<Pedido> pedidos = [];
      List<String> keysPedidos = [];
      var i = 0;
      for (var key in keys) {
        keysPedidos.add(_preferences!.getString(key)!);

        if (keysPedidos.isNotEmpty) {
          var map = jsonDecode(keysPedidos[i]);
          pedidos.add(Pedido.fromJson(map));
          i++;
        }
      }
      if (pedidos.length > 1) {
        pedidos.sort((a, b) => a.fecha.compareTo(b.fecha));
      }

      return pedidos.reversed.toList();
    } on Exception catch (_) {
      return [];
    }
  }

  static int getCantidadPedidos() {
    return _preferences!
        .getKeys()
        .where((element) => element.startsWith('pedido'))
        .length;
  }

  static Future clearAllStored() async {
    await _preferences!.clear();

    // print(getPedidos());
    // deleteOne(0, true);
  }

  static Future deleteOne(String key, bool firstTime) async {
    var newKey = key.substring(2, key.length - 2);

    if (_preferences!.containsKey("pedidos$newKey")) {
      await _preferences!.remove("pedidos$newKey");
    }
  }
}
