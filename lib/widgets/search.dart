import 'package:dist_v2/models/item_response.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context);
    final pedidoService = Provider.of<PedidoService>(context);
    final clienteService = Provider.of<ClienteService>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
              child: TextField(
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    final first = listaService.allView.first;
                    pedidoService.addCarrito(first);
                  }
                },
                onChanged: (value) {
                  listaService.searchItem(value, clienteService.clientes);
                },
                decoration: const InputDecoration(
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none,
                  hintText: "Buscar...",
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 4,
              backgroundColor: Colors.blueGrey,
            ),
            onPressed: () {
              final pedidoService = Provider.of<PedidoService>(context, listen: false);
              final namecontroller = TextEditingController();
              final colorcontroller = TextEditingController();
              final pricecontroller = TextEditingController();
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text("Nuevo accesorio"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          autofocus: true,
                          controller: namecontroller,
                          decoration: const InputDecoration(hintText: 'Nombre'),
                        ),
                        TextField(
                          autofocus: true,
                          controller: colorcontroller,
                          decoration: const InputDecoration(hintText: 'Color/Tipo'),
                        ),
                        TextField(
                          autofocus: true,
                          controller: pricecontroller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Precio'),
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
            child: const Text(
              "+ manual",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddManual(
      TextEditingController namecontroller,
      TextEditingController colorcontroller,
      TextEditingController pricecontroller,
      PedidoService pedidoService,
      BuildContext context) {
    var data = ItemResponse(namecontroller.text, colorcontroller.text,
        int.parse(pricecontroller.text), "0000");

    pedidoService.addCarrito(data);
    Navigator.pop(context);
  }
}
