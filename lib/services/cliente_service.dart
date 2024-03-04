import 'dart:convert';

import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClienteService with ChangeNotifier {
  late List<Pedido> _clientes = [];
  List<Pedido> get clientes => _clientes;
  set setClientes(List<Pedido> lista) => _clientes = lista;

  Future<Pedido> guardarPedido(String name, List<Item> list, int tot,
      [DateTime? date]) async {
    Pedido pedido = Pedido(
      nombre: name,
      fecha: date ?? DateTime.now(),
      lista: list,
      key: UniqueKey(),
      total: tot,
    );
    _clientes = [..._clientes, pedido];

    notifyListeners();
    String pedidoString = json.encode(pedido);

    await UserPreferences.setPedido(pedidoString, "${pedido.key}");

    return pedido;
  }

  editMessage(String msg, Pedido pedido) async {
    pedido.msg = msg;

    String pedidoString = json.encode(pedido);
    await UserPreferences.setPedido(pedidoString, "${pedido.key}");
  }

  Future<List<Pedido>> loadClientes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? listString = prefs.getString("pedidosKey") ?? "";

    if (listString.isEmpty) return [];

    _clientes = jsonDecode(listString);
    notifyListeners();
    return _clientes;
  }

  deletePedido(int i, String key) async {
    await UserPreferences.deleteOne(key, true);
    clientes.removeAt(i);
    notifyListeners();
  }

  /// [0] para items, [1] para clientes
  List<List<Object>> searchOnPedidos(String word) {
    final allItems =
        clientes.fold<List<Item>>([], (prev, element) => [...prev, ...element.lista]);

    List<Item> itemsCoincidencia = allItems
        .where((element) => element.nombre.toLowerCase().contains(word.toLowerCase()))
        .toList();
    if (itemsCoincidencia.length > 3) itemsCoincidencia = itemsCoincidencia.sublist(0, 3);

    final clientesCoincidencia = clientes
        .where((cliente) =>
            cliente.nombre.toLowerCase().contains(word.toLowerCase()) ||
            cliente.lista.any(
                (element) => element.nombre.toLowerCase().contains(word.toLowerCase())))
        .toList();

    return [itemsCoincidencia, clientesCoincidencia];
  }
}
