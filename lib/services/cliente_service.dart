import 'dart:convert';

import 'package:dist_v2/models/Itm.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClienteService with ChangeNotifier {
  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => this._clientes.reversed.toList();
  set setClientes(List<Pedido> lista) => this._clientes = lista;

  void guardarPedido(String name, List<Itm> list, int tot) {
    this._clientes.add(Pedido(
          nombre: name,
          fecha: DateTime.now(),
          lista: list,
          key: UniqueKey(),
          total: tot,
        ));

    notifyListeners();
  }

  Future<List<Pedido>> loadClientes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? listString = prefs.getString("pedidosKey") ?? "";

    if (listString.isNotEmpty) return jsonDecode(listString) as List<Pedido>;

    return [];
  }

  deletePedido(int i) {
    this._clientes.removeAt(i);
    this.loadClientes();
    notifyListeners();
  }
}
