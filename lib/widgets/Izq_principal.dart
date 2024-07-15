import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dist_v2/models/item_response.dart';

import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';

class ProductsList extends StatelessWidget {
  const ProductsList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context);

    return Container(
      margin: const EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.sizeOf(context).height * 0.25,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.builder(
        itemCount: listaService.allView.length,
        shrinkWrap: true,
        itemBuilder: (context, i) {
          return (listaService.allView.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : (i >= listaService.allView.length - 4)
                  ? itemDeHistorial(listaService.allView[i], i, context)
                  : itemDelista(listaService.allView[i], i, context);
        },
      ),
    );
  }
}

Widget itemDeHistorial(ItemResponse item, int i, BuildContext context) {
  return ListTile(
    title: Text(
      item.nombre,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      overflow: TextOverflow.fade,
    ),
    subtitle: Text(
      item.tipo.toLowerCase(),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    ),
    trailing: Text(
      "\$ ${item.precio}",
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    onTap: () {
      final pedidoService = Provider.of<PedidoService>(context, listen: false);
      pedidoService.addCarrito(item);
    },
  );
}

Widget itemDelista(ItemResponse item, int i, BuildContext context) {
  return ListTile(
    title: Text(
      item.nombre,
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.fade,
    ),
    subtitle: Text(
      item.tipo.toLowerCase(),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    ),
    trailing: Text(
      "\$ ${item.precio}",
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    onTap: () {
      final pedidoService = Provider.of<PedidoService>(context, listen: false);
      pedidoService.addCarrito(item);
    },
  );
}
