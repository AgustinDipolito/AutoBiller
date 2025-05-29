import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/item_response.dart';
import 'package:flutter/material.dart';

class PedidoService with ChangeNotifier {
  late List<Item> carrito = [];
  ScrollController? _scrollController;

  void addCarrito(ItemResponse itmData) {
    carrito.add(
      Item(
        cantidad: 1,
        tipo: (itmData.tipo),
        nombre: (itmData.nombre),
        precio: (itmData.precio),
        precioT: (itmData.precio),
        id: int.parse(itmData.id),
      ),
    );
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 200), () => moveControllerToEnd());
  }

  void setScrollController(ScrollController scrollController) {
    _scrollController ??= scrollController;
  }

  void moveControllerToEnd() {
    if (carrito.length > 6 && _scrollController != null) {
      // animate to end
      _scrollController?.animateTo(_scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void delCant(int i) {
    carrito[i].cantidad--;
    carrito[i].precioT = (carrito[i].precio) * carrito[i].cantidad;
    notifyListeners();
  }

  void reorderItem({required int oldPosition, required int newPosition}) {
    final item = carrito[oldPosition];

    carrito.removeAt(oldPosition);
    carrito.insert(newPosition, item);
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

  void updateCartItem(int index, {int? newCant, String? newDesc}) {
    if (index < 0 || index >= carrito.length) return;

    if (newCant != null) {
      carrito[index].cantidad = newCant;
      carrito[index].precioT = (carrito[index].precio) * newCant;
    }

    if (newDesc != null) {
      carrito[index].tipo = newDesc;
    }

    notifyListeners();
  }

  int get sumTot => carrito.fold(0, (sum, item) => sum + item.precioT);

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
