import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dist_v2/models/pedido.dart';

class UserPreferences {
  static SharedPreferences? _preferences;
  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setPedido(String lista, String key) async {
    await _preferences!.setString("pedidos$key", lista);
  }

  static List<Pedido> getPedidos() {
    var keys = _preferences!.getKeys();
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

  static int getCantidad() {
    return _preferences!.getKeys().length;
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
