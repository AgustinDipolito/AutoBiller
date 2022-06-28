import 'dart:convert';

import 'package:dist_v2/models/itm.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClienteService with ChangeNotifier {
  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => _clientes;
  set setClientes(List<Pedido> lista) => _clientes = lista;

  Pedido guardarPedido(String name, List<Itm> list, int tot, [DateTime? date]) {
    Pedido pedido = Pedido(
      nombre: name,
      fecha: date ?? DateTime.now(),
      lista: list,
      key: UniqueKey(),
      total: tot,
    );
    _clientes = [..._clientes, pedido];

    notifyListeners();
    return pedido;
  }

  Future<List<Pedido>> loadClientes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? listString = prefs.getString("pedidosKey") ?? "";

    if (listString.isNotEmpty) return jsonDecode(listString) as List<Pedido>;
    notifyListeners();
    return [];
  }

  deletePedido(int i, String key) async {
    await UserPreferences.deleteOne(key, true);
    clientes.removeAt(i);
    notifyListeners();
  }
}
