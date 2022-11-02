import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:flutter/material.dart';

class AnalysisService with ChangeNotifier {
  List<VipItem> vipItems = <VipItem>[];
  int i = 0;

  void init(List<Pedido> pedidos) {
// get shared_preferences y sino checar historial si hay procesarlo, en caso negativo, list vacia
    clearAll();
    for (var pedido in pedidos) {
      for (var it in pedido.lista) {
        var vip = VipItem(
          id: it.id,
          cantTotal: it.cantidad,
          recaudado: it.precioT,
          nombre: it.nombre.trim(),
        );
        var pos = vipItems.indexWhere((element) =>
            element.nombre.trim().toUpperCase() ==
            vip.nombre.trim().toUpperCase());

        if (pos < 0) {
          vipItems.add(vip);
        } else {
          addInfo(vip, pos);
        }
      }
    }

    // notifyListeners();
  }

  void addInfo(VipItem vip, int index) {
    if (vipItems.isEmpty) {
      vipItems.add(vip);
      return;
    }
    vipItems[index].cantTotal += vip.cantTotal;
    vipItems[index].recaudado += vip.recaudado;
    vipItems[index].repeticiones++;
  }

  // notifyListeners();

  List<VipItem> getTopRaised({int? limit}) {
    vipItems.sort((a, b) => b.recaudado.compareTo(a.recaudado));
    var tops = vipItems.sublist(0, limit);
    return tops;
  }

  List<VipItem> getTopSelled({int? limit}) {
    vipItems.sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
    var tops = vipItems.sublist(0, limit);
    return tops;
  }

  List<VipItem> sortList(SortBy by) {
    switch (by) {
      case SortBy.nameUp:
        vipItems.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case SortBy.nameDown:
        vipItems.sort((a, b) => b.nombre.compareTo(a.nombre));
        break;
      case SortBy.raisedUp:
        vipItems.sort((a, b) => a.recaudado.compareTo(b.recaudado));
        break;
      case SortBy.raisedDown:
        vipItems.sort((a, b) => b.recaudado.compareTo(a.recaudado));
        break;
      case SortBy.repsUp:
        vipItems.sort((a, b) => a.repeticiones.compareTo(b.repeticiones));
        break;
      case SortBy.repsDown:
        vipItems.sort((a, b) => b.repeticiones.compareTo(a.repeticiones));
        break;
      case SortBy.cantUp:
        vipItems.sort((a, b) => a.cantTotal.compareTo(b.cantTotal));
        break;
      case SortBy.cantDown:
        vipItems.sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
        break;
    }
    notifyListeners();
    return vipItems;
    // notifyListeners();
  }

  void clearAll() {
    vipItems.clear();
  }
}

enum SortBy {
  nameUp,
  nameDown,
  raisedUp,
  raisedDown,
  repsUp,
  repsDown,
  cantUp,
  cantDown,
}
