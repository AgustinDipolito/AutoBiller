import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/widgets/der_principal.dart';
import 'package:dist_v2/widgets/top_principal.dart';
import 'package:dist_v2/widgets/izq_principal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({Key? key}) : super(key: key);

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
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
          body: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: TopView(),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const <Widget>[
                      IzqView(),
                      Expanded(flex: 2, child: DerView()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
