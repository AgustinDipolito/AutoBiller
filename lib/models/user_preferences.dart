import 'dart:convert';

import 'package:dist_v2/models/pedido.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _preferences;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setPedido(String lista) async {
    var x = getCantidad()!;
    await _preferences!.setString("pedidos$x", lista);
    setCant(x + 1);
  }

  static List<Pedido> getPedidos() {
    try {
      var x = getCantidad()!;
      List<Pedido> pedidos = [];
      String list = "";
      for (int i = 0; i < x; i++) {
        list = _preferences!.getString("pedidos$i") ?? "";

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

  static int? getCantidad() {
    return _preferences!.getInt("cant") ?? 0;
  }

  static Future setCant(int x) async {
    await _preferences!.setInt("cant", x);
  }

  static Future clearAllStored() async {
    await _preferences!.clear();
  }

  static Future deleteOne(String key) async {
    await _preferences!.remove(key);
  }
}
