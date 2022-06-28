import 'package:dist_v2/models/itm.dart';
import 'package:dist_v2/models/item.dart';
import 'package:flutter/material.dart';

class PedidoService with ChangeNotifier {
  late List<Itm> carrito = [];

  void addCarrito(Item itmData) {
    carrito.add(Itm(
      cantidad: 1,
      tipo: (itmData.tipo),
      nombre: (itmData.nombre),
      precio: (itmData.precio),
      precioT: (itmData.precio),
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

  List<Itm> giveSaved() {
    List<Itm> lista = [];
    lista.addAll(carrito);
    return lista;
  }

  void clearAll() {
    carrito.clear();
    notifyListeners();
  }
}
