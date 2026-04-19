import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/services/firebase_service.dart';
import 'package:dist_v2/services/stock_analysis_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dist_v2/routes/routes.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';

import 'models/user_preferences.dart';
import 'services/stock_service_with_firebase.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await FirebaseService().initialize();
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PedidoService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClienteService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ListaService(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisService(),
        ),
        ChangeNotifierProvider(
          create: (_) => StockService(),
        ),
        // StockAnalysisService depends on StockService, AnalysisService, and ClienteService
        ChangeNotifierProxyProvider3<StockService, AnalysisService, ClienteService,
            StockAnalysisService>(
          create: (context) => StockAnalysisService(
            Provider.of<StockService>(context, listen: false),
            Provider.of<AnalysisService>(context, listen: false),
            Provider.of<ClienteService>(context, listen: false),
          ),
          update: (context, stockService, analysisService, clienteService, previous) =>
              previous ??
              StockAnalysisService(stockService, analysisService, clienteService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material app',
        initialRoute: kIsWeb ? "login" : "principal",
        routes: appRoutes,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.white,
        ),
      ),
    );
  }
}
