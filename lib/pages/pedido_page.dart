import 'package:dist_v2/models/pedido.dart';
import 'package:flutter/material.dart';

class PedidoPage extends StatefulWidget {
  PedidoPage({Key? key}) : super(key: key);

  @override
  _PedidoPageState createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  @override
  Widget build(BuildContext context) {
    final cliente = ModalRoute.of(context)!.settings.arguments as Pedido;
    return Scaffold(
      backgroundColor: Color(0xFF808080),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * .40,
            height: MediaQuery.of(context).size.height * .90,
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              itemCount: cliente.lista.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Text("${cliente.lista[i].cantidad}"),
                  title: Text(
                    "${cliente.lista[i].nombre}  ---   ${cliente.lista[i].tipo}",
                  ),
                  trailing: Text(
                    "${cliente.lista[i].precioT}",
                    style: TextStyle(fontWeight: FontWeight.w100, fontSize: 15),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text("${cliente.nombre}\n\$${cliente.total}"),
                Container(
                  width: MediaQuery.of(context).size.width * .15,
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
                      Navigator.pop(context);
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Volver",
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
          )
        ],
      ),
    );
  }
}
