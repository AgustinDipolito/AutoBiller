import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/helpers/savePedido.dart';

import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';

class IzqView extends StatefulWidget {
  IzqView({Key? key}) : super(key: key);
  @override
  _IzqViewState createState() => _IzqViewState();
}

class _IzqViewState extends State<IzqView> {
  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Container(
            width: MediaQuery.of(context).size.width * .45,
            height: MediaQuery.of(context).size.height * .7,
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FutureBuilder(
              future: listaService.todo,
              builder: (context, AsyncSnapshot<List<Item>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData)
                  return ListView.builder(
                      itemCount: snapshot.data?.length ?? 0,
                      itemBuilder: (context, i) => snapshot.data == null
                          ? const Center(child: CircularProgressIndicator())
                          : lista(snapshot.data![i], i, context));
                else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
        Container(
          width: 380,
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    elevation: 0,
                    primary: const Color(0xFFE6E6E6),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        final namecontroller = new TextEditingController();
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text("Guardar pedido"),
                          content: TextField(
                              autofocus: true,
                              controller: namecontroller,
                              decoration:
                                  InputDecoration(hintText: 'Nombre cliente'),
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
                                  initialEntryMode:
                                      DatePickerEntryMode.calendarOnly,
                                  firstDate: DateTime(2021, 12),
                                  initialDate: DateTime.now(),
                                  lastDate: DateTime.now(),
                                ).then((value) {
                                  if (namecontroller.text.isNotEmpty &&
                                      value != null) {
                                    savePedido(
                                        context, namecontroller.text, value);
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
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Guardar",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    elevation: 0,
                    primary: const Color(0xFFE6E6E6),
                  ),
                  onPressed: () {
                    final pedidoService =
                        Provider.of<PedidoService>(context, listen: false);
                    final namecontroller = new TextEditingController();
                    final colorcontroller = new TextEditingController();
                    final pricecontroller = new TextEditingController();
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text("Nuevo accesorio"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                autofocus: true,
                                controller: namecontroller,
                                decoration:
                                    const InputDecoration(hintText: 'Nombre'),
                              ),
                              TextField(
                                autofocus: true,
                                controller: colorcontroller,
                                decoration: const InputDecoration(
                                    hintText: 'Color/Tipo'),
                              ),
                              TextField(
                                autofocus: true,
                                controller: pricecontroller,
                                decoration:
                                    const InputDecoration(hintText: 'Precio'),
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            MaterialButton(
                              child: const Text(
                                "Añadir",
                                style: TextStyle(color: Colors.blue),
                              ),
                              onPressed: () => _onAddManual(
                                namecontroller,
                                colorcontroller,
                                pricecontroller,
                                pedidoService,
                                context,
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: const Align(
                    alignment: Alignment.center,
                    child: const Text(
                      "Añadir manual",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    elevation: 0,
                    primary: const Color(0xFFE6E6E6),
                  ),
                  onPressed: () {
                    final pedidoService = Provider.of<PedidoService>(
                      context,
                      listen: false,
                    );
                    pedidoService.clearAll();
                    setState(() {});
                  },
                  child: const Align(
                    alignment: Alignment.center,
                    child: const Text(
                      "Vaciar",
                      style: TextStyle(
                        color: const Color(0xFF202020),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onAddManual(
      TextEditingController namecontroller,
      TextEditingController colorcontroller,
      TextEditingController pricecontroller,
      PedidoService pedidoService,
      BuildContext context) {
    var data = new Item(namecontroller.text, colorcontroller.text,
        int.parse(pricecontroller.text), "0000");

    pedidoService.addCarrito(data);
    Navigator.pop(context);
  }
}

Widget lista(Item item, int i, BuildContext context) {
  return ListTile(
    leading: Text(
      item.nombre,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    title: Text(
      item.tipo.toLowerCase(),
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      "\$ " + "${item.precio}",
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    onTap: () {
      final pedidoService = Provider.of<PedidoService>(context, listen: false);
      pedidoService.addCarrito(item);
    },
  );
}
