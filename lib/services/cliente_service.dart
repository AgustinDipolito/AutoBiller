import 'dart:convert';

import 'package:dist_v2/models/Itm.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClienteService with ChangeNotifier {
  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => this._clientes.reversed.toList();
  set setClientes(List<Pedido> lista) => this._clientes = lista;

  Pedido guardarPedido(String name, List<Itm> list, int tot) {
    Pedido pedido = Pedido(
      nombre: name,
      fecha: DateTime.now(),
      lista: list,
      key: UniqueKey(),
      total: tot,
      intKey: tot,
    );
    this._clientes.add(pedido);

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

  deletePedido(int i) {
    UserPreferences.deleteOne(this.clientes[i].total);
    this._clientes.removeAt(i);
    notifyListeners();
  }
}
