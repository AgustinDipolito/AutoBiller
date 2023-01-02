import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopView extends StatelessWidget {
  const TopView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context);
    final pedidoService = Provider.of<PedidoService>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.only(left: 20),
            width: MediaQuery.of(context).size.width * .75,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  var x = await listaService.todo;
                  pedidoService.addCarrito(x[0]);
                }
              },
              onChanged: (value) {
                listaService.searchItem(value);
                if (value.isNotEmpty) {
                  listaService.sort();
                }
              },
              decoration: const InputDecoration(
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                hintText: "Buscar...",
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: MaterialButton(
              onPressed: () async {
                Navigator.pushNamed(context, "ventas");
              },
              child: const Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    "Stats",
                    style: TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: MaterialButton(
              onPressed: () async {
                Navigator.pushNamed(context, "stock");
              },
              child: const Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    "Stock",
                    style: TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: MaterialButton(
              onPressed: () async {
                Navigator.pushNamed(context, "todos");
              },
              child: const Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    "Pedidos",
                    style: TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
