import 'package:dist_v2/models/Itm.dart';
import 'package:dist_v2/models/item.dart';
import 'package:flutter/material.dart';

class PedidoService with ChangeNotifier {
  late List<Itm> _carrito = [];
  List<Itm> get carrito => this._carrito;

  void addCarrito(Item itmData) {
    this._carrito.add(Itm(
          cantidad: 1,
          tipo: (itmData.tipo),
          nombre: (itmData.nombre),
          precio: (itmData.precio),
          precioT: (itmData.precio),
        ));
    notifyListeners();
  }

  void delCant(int i) {
    this._carrito[i].cantidad--;
    this._carrito[i].precioT =
        (this._carrito[i].precio) * this._carrito[i].cantidad;
    notifyListeners();
  }

  void deleteCarrito(int i) {
    this._carrito.removeAt(i);
    notifyListeners();
  }

  void addCant(int i) {
    this._carrito[i].cantidad++;
    this._carrito[i].precioT =
        (this._carrito[i].precio) * this._carrito[i].cantidad;
    notifyListeners();
  }

  int sumTot() {
    int tot = 0;
    for (var t in this._carrito) tot += t.precioT;
    return tot;
  }

  List<Itm> giveSaved() {
    List<Itm> lista = [];
    lista.addAll(this._carrito);
    return lista;
  }

  void clearAll() {
    this._carrito.clear();
    notifyListeners();
  }
}
