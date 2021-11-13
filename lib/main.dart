import 'package:dist_v2/routes/routes.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_preferences.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  runApp(Myapp());
}

class Myapp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => new PedidoService(),
        ),
        ChangeNotifierProvider(
          create: (_) => new ClienteService(),
        ),
        ChangeNotifierProvider(
          create: (_) => new ListaService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material app',
        initialRoute: "principal",
        routes: appRoutes,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Color(0xFFE6E6E6),
          accentColor: Color(0xFF404040),
          textTheme: TextTheme(
            headline1: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            bodyText2: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
