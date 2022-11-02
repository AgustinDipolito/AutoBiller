import 'package:dist_v2/services/analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dist_v2/routes/routes.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/lista_service.dart';
import 'package:dist_v2/services/pedido_service.dart';

import 'models/user_preferences.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
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
          create: (_) => ClienteService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ListaService(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material app',
        initialRoute: "principal",
        routes: appRoutes,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFFE6E6E6),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            bodyMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
