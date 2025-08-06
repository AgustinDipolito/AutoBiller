import 'package:dist_v2/pages/todos_page.dart';
import 'package:dist_v2/widgets/carrito_wid.dart';
import 'package:dist_v2/widgets/search.dart' as top;
import 'package:dist_v2/widgets/izq_principal.dart';
import 'package:flutter/material.dart';

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
              Text('v14.6', style: TextStyle(color: Colors.white, fontSize: 14)),
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
        body: GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            // Check if the swipe is from left to right (positive velocity)
            if (details.primaryVelocity! < 0) {
              // Navigate to 'todos' page
              Navigator.push(context, _createRoute());
            }
          },
          child: Container(
            color: Colors.grey,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: const SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: CarritoWidget()),
                  top.SearchBar(),
                  ProductsList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => const TodosPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // from right to left
      const end = Offset.zero;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOut));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
