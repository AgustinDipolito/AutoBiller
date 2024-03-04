import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarritoWidget extends StatelessWidget {
  const CarritoWidget({Key? key, this.cliente}) : super(key: key);
  final Pedido? cliente;
  @override
  Widget build(BuildContext context) {
    final pedidoService = Provider.of<PedidoService>(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width * .8,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: pedidoService.carrito.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.add_shopping_cart,
                      size: 40,
                      color: Color(0xFF808080),
                    ),
                  )
                : ListView.builder(
                    itemCount: cliente?.lista.length ?? pedidoService.carrito.length,
                    itemBuilder: (_, i) {
                      var pedido = cliente?.lista[i] ?? pedidoService.carrito[i];
                      return Dismissible(
                        key: ValueKey(pedido),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
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
                        child: ListTile(
                          onTap: () => pedidoService.addCant(i),
                          leading: Text("${pedido.cantidad}"),
                          title: Text(
                            pedido.nombre,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onLongPress: () => pedidoService.delCant(i),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 4,
          ),
          height: MediaQuery.of(context).size.height * .3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "\$ ${pedidoService.sumTot()}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  elevation: 4,
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: () {
                  final pedidoService = Provider.of<PedidoService>(
                    context,
                    listen: false,
                  );
                  pedidoService.clearAll();
                  // setState(() {});
                },
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Vaciar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  elevation: 4,
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      final namecontroller = TextEditingController();
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: const Text("Guardar pedido"),
                        content: TextField(
                            autofocus: true,
                            controller: namecontroller,
                            decoration: const InputDecoration(hintText: 'Nombre cliente'),
                            onSubmitted: (string) {
                              if (namecontroller.text.isNotEmpty) {
                                savePedido(context, string);

                                Navigator.pop(context);
                              }
                            }),
                        actions: <Widget>[
                          IconButton(
                            onPressed: () {
                              showDatePicker(
                                context: context,
                                initialEntryMode: DatePickerEntryMode.calendarOnly,
                                firstDate: DateTime(2021, 12),
                                initialDate: DateTime.now(),
                                lastDate: DateTime.now(),
                              ).then((value) {
                                if (namecontroller.text.isNotEmpty && value != null) {
                                  savePedido(context, namecontroller.text, value);
                                  Navigator.pop(context);
                                }
                              });
                            },
                            icon: const Icon(Icons.calendar_today),
                          ),
                          MaterialButton(
                            onPressed: () {
                              if (namecontroller.text.isNotEmpty) {
                                savePedido(context, namecontroller.text);
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Guardar",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  "Guardar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void savePedido(BuildContext context, String name, [DateTime? date]) async {
    final pedidoService = Provider.of<PedidoService>(context, listen: false);
    final clienteService = Provider.of<ClienteService>(context, listen: false);

    clienteService.guardarPedido(
      name,
      pedidoService.giveSaved(),
      pedidoService.sumTot(),
      date,
    );
    pedidoService.clearAll();
  }
}
