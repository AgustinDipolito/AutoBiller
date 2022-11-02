import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/item_response.dart';
import 'package:flutter/material.dart';

class PedidoService with ChangeNotifier {
  late List<Item> carrito = [];

  void addCarrito(ItemResponse itmData) {
    carrito.add(Item(
      cantidad: 1,
      tipo: (itmData.tipo),
      nombre: (itmData.nombre),
      precio: (itmData.precio),
      precioT: (itmData.precio),
      id: int.parse(itmData.id),
    ));
    notifyListeners();
  }

  void delCant(int i) {
    carrito[i].cantidad--;
    carrito[i].precioT = (carrito[i].precio) * carrito[i].cantidad;
    notifyListeners();
  }

  void deleteCarrito(int i) {
    carrito.removeAt(i);
    notifyListeners();
  }

  void addCant(int i) {
    carrito[i].cantidad++;
    carrito[i].precioT = (carrito[i].precio) * carrito[i].cantidad;
    notifyListeners();
  }

  int sumTot() {
    int tot = 0;
    for (var t in carrito) {
      tot += t.precioT;
    }
    return tot;
  }

  List<Item> giveSaved() {
    List<Item> lista = [];
    lista.addAll(carrito);
    return lista;
  }

  void clearAll() {
    carrito.clear();
    notifyListeners();
  }
}
