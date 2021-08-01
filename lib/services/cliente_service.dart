import 'package:dist_v2/models/Itm.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:flutter/material.dart';

class ClienteService with ChangeNotifier {
  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => this._clientes;

  void guardarPedido(
    String name,
    List<Itm> list,
    int tot,
  ) {
    this._clientes.insert(
        0,
        Pedido(
          nombre: name,
          fecha: DateTime.now(),
          lista: list,
          key: UniqueKey(),
          total: tot,
        ));

    notifyListeners();
  }

  void deletePedido(int i) {
    this._clientes.removeAt(i);
    notifyListeners();
  }
}
