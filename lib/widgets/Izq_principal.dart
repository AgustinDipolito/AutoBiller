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
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
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
        Container(
          width: MediaQuery.of(context).size.width * .45,
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    elevation: 0,
                    primary: Color(0xFFE6E6E6),
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
                            title: Text("Guardar pedido"),
                            content: TextField(
                                autofocus: true,
                                controller: namecontroller,
                                decoration:
                                    InputDecoration(hintText: 'Nombre cliente'),
                                onSubmitted: (string) {
                                  savePedido(context, string);
                                  Navigator.pop(context);
                                }),
                            actions: <Widget>[
                              MaterialButton(
                                onPressed: () {
                                  savePedido(context, namecontroller.text);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Guardar",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              )
                            ],
                          );
                        });
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Guardar",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 33,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    elevation: 0,
                    primary: Color(0xFFE6E6E6),
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
                          title: Text("Nuevo accesorio"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                autofocus: true,
                                controller: namecontroller,
                                decoration: InputDecoration(hintText: 'Nombre'),
                              ),
                              TextField(
                                autofocus: true,
                                controller: colorcontroller,
                                decoration:
                                    InputDecoration(hintText: 'Color/Tipo'),
                              ),
                              TextField(
                                autofocus: true,
                                controller: pricecontroller,
                                decoration: InputDecoration(hintText: 'Precio'),
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            MaterialButton(
                              child: Text(
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
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Añadir manual",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 29,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    elevation: 0,
                    primary: Color(0xFFE6E6E6),
                  ),
                  onPressed: () {
                    final pedidoService = Provider.of<PedidoService>(
                      context,
                      listen: false,
                    );
                    pedidoService.clearAll();
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Vaciar",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 33,
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
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          item.nombre,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(item.tipo.toLowerCase()),
        Text("\$ " + "${item.precio}"),
      ],
    ),
    onTap: () {
      final pedidoService = Provider.of<PedidoService>(context, listen: false);
      pedidoService.addCarrito(item);
    },
  );
}
