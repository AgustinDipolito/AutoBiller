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
            width: MediaQuery.of(context).size.width * .65,
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
                  title: RichText(
                    text: TextSpan(
                      text: "${cliente.lista[i].nombre}",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "  ---   ",
                          style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w200),
                        ),
                        TextSpan(
                          text: "${cliente.lista[i].tipo}",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  ),
                  trailing: RichText(
                    text: TextSpan(
                      text: "${cliente.lista[i].precioT}",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w100,
                          fontSize: 15),
                    ),
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
