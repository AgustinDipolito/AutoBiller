import 'package:dist_v2/services/pedido_service.dart';
import 'package:dist_v2/widgets/carrito_wid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DerView extends StatefulWidget {
  DerView({Key? key}) : super(key: key);

  @override
  _DerViewState createState() => _DerViewState();
}

class _DerViewState extends State<DerView> {
  @override
  Widget build(BuildContext context) {
    final pedidoService = Provider.of<PedidoService>(context);

    return Column(
      children: <Widget>[
        Expanded(flex: 4, child: CarritoWidget()),
        Expanded(
          flex: 1,
          child: Container(
            width: 300,
            height: 100,
            child: Center(
              child: Container(
                child: Text(
                  "Total: \$ ${pedidoService.sumTot()}",
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
