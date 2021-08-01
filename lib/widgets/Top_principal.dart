import 'package:dist_v2/services/lista_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopView extends StatelessWidget {
  const TopView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listaService = Provider.of<ListaService>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.only(left: 20),
          width: MediaQuery.of(context).size.width * .75,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            onChanged: (value) {
              listaService.searchItem(value);
              if (value.isEmpty) listaService.sort();
            },
            decoration: InputDecoration(
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              hintText: "Buscar...",
            ),
          ),
        ),
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
              elevation: 1,
              primary: Color(0xFFE6E6E6),
            ),
            onPressed: () => Navigator.pushNamed(context, "todos"),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Pedidos",
                style: TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 33,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
