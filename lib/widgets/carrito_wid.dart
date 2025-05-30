import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:dist_v2/utils.dart';
import 'package:dist_v2/widgets/edit_cart_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarritoWidget extends StatefulWidget {
  const CarritoWidget({Key? key, this.cliente}) : super(key: key);
  final Pedido? cliente;

  @override
  State<CarritoWidget> createState() => _CarritoWidgetState();
}

class _CarritoWidgetState extends State<CarritoWidget> with WidgetsBindingObserver {
  final ValueNotifier<bool> editMode = ValueNotifier(false);
  final _carritoController = ScrollController();

  @override
  void dispose() {
    editMode.dispose();

    _carritoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedidoService = Provider.of<PedidoService>(context)
      ..setScrollController(_carritoController);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: MediaQuery.of(context).size.height * .48,
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
              : ValueListenableBuilder<bool>(
                  valueListenable: editMode,
                  builder: (context, isEditMode, _) => ListView.builder(
                    itemCount:
                        widget.cliente?.lista.length ?? pedidoService.carrito.length,
                    shrinkWrap: true,
                    controller: _carritoController,
                    itemBuilder: (_, i) {
                      var pedido = widget.cliente?.lista[i] ?? pedidoService.carrito[i];
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
                          dense: pedido.nombre.length > 20,
                          onTap: () => pedidoService.addCant(i),
                          onLongPress: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return EditCartItemDialog(
                                item: pedido,
                                onSave: (quantity, description) {
                                  pedidoService.updateCartItem(
                                    i,
                                    newCant: quantity,
                                    newDesc: description,
                                  );
                                },
                              );
                            },
                          ),
                          trailing: isEditMode
                              ? reorderButton(context, pedidoService, i)
                              : null,
                          leading: Text(
                            isEditMode ? i.toString() : '${pedido.cantidad}',
                          ),
                          title: Text(
                            pedido.nombre,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          child: Text(
            '${pedidoService.carrito.length} accesorios en el carro.',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                Utils.formatPrice(pedidoService.sumTot.toDouble()),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              IconButton(
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
                },
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              IconButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  elevation: 4,
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: () {
                  editMode.value = !editMode.value;
                },
                icon: const Icon(
                  Icons.swap_calls,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  elevation: 4,
                  foregroundColor: Colors.blueGrey,
                  backgroundColor: Colors.white,
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
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  "\u{1F6D2} Guardar",
                  style: TextStyle(
                    color: Colors.blueGrey,
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

  IconButton reorderButton(BuildContext context, PedidoService pedidoService, int i) {
    return IconButton(
      icon: const Icon(Icons.move_down),
      onPressed: () {
        final posController = TextEditingController();

        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("Mover a"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: posController,
                    decoration: const InputDecoration(hintText: 'Nueva pos'),
                  ),
                ],
              ),
              actions: <Widget>[
                MaterialButton(
                    child: const Text(
                      "Añadir",
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: () {
                      final newPos = int.parse(posController.text);
                      if (newPos <= pedidoService.carrito.length) {
                        pedidoService.reorderItem(
                          oldPosition: i,
                          newPosition: newPos,
                        );
                        Navigator.of(context).pop();
                      }
                    })
              ],
            );
          },
        );
      },
    );
  }

  void savePedido(BuildContext context, String name, [DateTime? date]) async {
    final pedidoService = Provider.of<PedidoService>(context, listen: false);
    final clienteService = Provider.of<ClienteService>(context, listen: false);

    clienteService.guardarPedido(
      name,
      pedidoService.giveSaved(),
      pedidoService.sumTot,
      date,
    );
    pedidoService.clearAll();
  }
}
