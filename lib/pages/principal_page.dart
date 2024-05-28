import 'package:dist_v2/widgets/carrito_wid.dart';
import 'package:dist_v2/widgets/top_principal.dart' as top;
import 'package:dist_v2/widgets/izq_principal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({Key? key}) : super(key: key);

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  @override
  Widget build(context) {
    // Provider.of<ListaService>(context).readJson();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('   A L U S O L ', style: TextStyle(color: Colors.white)),
              Text('v26.5', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          actions: [
            IconButton(
              color: kDefaultIconDarkColor,
              onPressed: () => Navigator.pushNamed(context, "ventas"),
              icon: const Icon(Icons.bar_chart),
            ),
            IconButton(
              color: kDefaultIconDarkColor,
              onPressed: () => Navigator.pushNamed(context, "stock"),
              icon: const Icon(Icons.list),
            ),
            IconButton(
              color: kDefaultIconDarkColor,
              onPressed: () => Navigator.pushNamed(context, "todos"),
              icon: const Icon(Icons.people_sharp),
            ),
          ],
        ),
        body: Container(
          color: Colors.grey,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: CarritoWidget()),
                const top.SearchBar(),
                const Flexible(
                  child: ProductsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
