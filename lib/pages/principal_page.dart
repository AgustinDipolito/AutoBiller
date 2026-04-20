import 'package:dist_v2/pages/todos_page.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/stock_analysis_service.dart';
import 'package:dist_v2/widgets/carrito_wid.dart';
import 'package:dist_v2/widgets/search.dart' as top;
import 'package:dist_v2/widgets/izq_principal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dist_v2/services/lista_service.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListaService>(context, listen: false).readJson();
      Provider.of<ClienteService>(context, listen: false).initWithFirebase();

      // Initialize stock analysis after data is loaded
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Provider.of<StockAnalysisService>(context, listen: false).analyzeStockLevels();
        }
      });
    });
  }

  @override
  Widget build(context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A L U S O L ', style: TextStyle(color: Colors.white)),
              Text('v31.01.26', style: TextStyle(color: Colors.white, fontSize: 8)),
            ],
          ),
          actions: [
            // Switcher de catálogo
            Consumer<ListaService>(
              builder: (context, listaService, _) => IconButton(
                color: kDefaultIconDarkColor,
                onPressed: () async {
                  final newMode = listaService.mode == 'offline' ? 'firebase' : 'offline';
                  await listaService.switchMode(newMode);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newMode == 'firebase'
                              ? '📱 Catálogo Firebase activado'
                              : '📂 Catálogo offline activado',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: Icon(
                  listaService.mode == 'firebase' ? Icons.cloud : Icons.folder,
                ),
                tooltip: listaService.mode == 'firebase'
                    ? 'Cambiar a catálogo offline'
                    : 'Cambiar a catálogo Firebase',
              ),
            ),
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
              onPressed: () => Navigator.pushNamed(context, "catalogo"),
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Gestión de Catálogo',
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: const CarritoWidget()),
                  const top.SearchBar(),
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
