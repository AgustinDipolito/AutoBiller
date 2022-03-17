import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/widgets/Der_principal.dart';
import 'package:dist_v2/widgets/Top_principal.dart';
import 'package:dist_v2/widgets/Izq_principal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrincipalPage extends StatefulWidget {
  PrincipalPage({Key? key}) : super(key: key);

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  @override
  Widget build(context) {
    final listaService = Provider.of<ListaService>(context);
    listaService.readJson();
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.grey.shade600, Colors.grey.shade400]),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TopView(),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IzqView(),
                    Expanded(flex: 2, child: DerView()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
