import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dist_v2/models/pedido.dart';

class UserPreferences {
  static SharedPreferences? _preferences;
  static int x = 0;
  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setPedido(String lista, int key) async {
    (_preferences!.containsKey("pedidos$key"))
        ? await _preferences!.setString("pedidos${key + 1}", lista)
        : await _preferences!.setString("pedidos$key", lista);
    x++;
  }

  static List<Pedido> getPedidos() {
    var keys = _preferences!.getKeys();
    print("${_preferences!.getKeys()}");
    try {
      List<Pedido> pedidos = [];
      String list = "";
      for (var key in keys) {
        list = _preferences!.getString(key) ?? "";

        //Map<String, dynamic>
        var map = jsonDecode(list);
        pedidos.add(Pedido.fromJson(map[0]));
      }

      return pedidos;
    } on Exception catch (e) {
      print("${e.runtimeType}");
      return [];
    }
  }

  static int getCantidad() {
    return _preferences!.getKeys().length;
  }

  static Future clearAllStored() async {
    await _preferences!.clear();
  }

  static Future deleteOne(int key) async {
    await _preferences!.remove("pedidos$key");
  }
}
