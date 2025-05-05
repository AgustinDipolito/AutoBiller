import 'package:dist_v2/services/analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dist_v2/routes/routes.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';

import 'models/user_preferences.dart';
import 'services/stock_service.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PedidoService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClienteService()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ListaService()..readJson(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisService(),
        ),
        ChangeNotifierProvider(
          create: (_) => StockService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material app',
        initialRoute: "principal",
        routes: appRoutes,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.white,
        ),
      ),
    );
  }
}
