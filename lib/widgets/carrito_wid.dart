import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarritoWidget extends StatelessWidget {
  const CarritoWidget({Key? key, this.cliente}) : super(key: key);
  final Pedido? cliente;
  @override
  Widget build(BuildContext context) {
    final pedidoService = Provider.of<PedidoService>(context);

    return Container(
      width: MediaQuery.of(context).size.width * .45,
      height: MediaQuery.of(context).size.height * .7,
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        itemCount: cliente?.lista.length ?? pedidoService.carrito.length,
        itemBuilder: (_, i) {
          var pedido = cliente?.lista[i] ??
              pedidoService.carrito[i]; //pedidoService.carrito[i];
          return Dismissible(
            key: ValueKey(pedido),
            direction: DismissDirection.startToEnd,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Eliminar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
            ),
            onDismissed: (direction) => pedidoService.deleteCarrito(i),
            child: Column(
              children: [
                ListTile(
                  onTap: () => pedidoService.addCant(i),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("${pedido.cantidad}"),
                      Text(
                        pedido.nombre,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(pedido.tipo.toLowerCase()),
                      Text("\$ ${pedido.precioT}"),
                    ],
                  ),
                  onLongPress: () => pedidoService.delCant(i),
                ),
                Container(
                  height: 1,
                  width: 525,
                  color: Color(0xFFE6E6E6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}