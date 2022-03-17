// import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopView extends StatelessWidget {
  const TopView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context);
    // final clienteService = Provider.of<ClienteService>(context);
    final pedidoService = Provider.of<PedidoService>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.only(left: 20),
            width: MediaQuery.of(context).size.width * .75,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onSubmitted: (_) async {
                var x = await listaService.todo;
                pedidoService.addCarrito(x[0]);
              },
              onChanged: (value) {
                listaService.searchItem(value);
                if (value.isNotEmpty) listaService.sort();
              },
              decoration: InputDecoration(
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
            decoration: BoxDecoration(
              color: Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                elevation: 1,
                primary: Color(0xFFE6E6E6),
              ),
              onPressed: () async {
                Navigator.pushNamed(context, "ventas");
              },
              child: Center(
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
        Spacer(flex: 1),
        Expanded(
          flex: 3,
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                elevation: 1,
                primary: Color(0xFFE6E6E6),
              ),
              onPressed: () async {
                Navigator.pushNamed(context, "todos");
              },
              child: Center(
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
