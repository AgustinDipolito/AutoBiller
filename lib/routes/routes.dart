import 'package:dist_v2/pages/analysis_page.dart';
import 'package:dist_v2/pages/catalogo_page.dart';
import 'package:dist_v2/pages/login_page.dart';
import 'package:dist_v2/pages/pedido_page.dart';
import 'package:dist_v2/pages/principal_page.dart';
import 'package:dist_v2/pages/stadistic_page.dart';
import 'package:dist_v2/pages/stock_alerts_page.dart';
import 'package:dist_v2/pages/stock_page.dart';
import 'package:dist_v2/pages/todos_page.dart';

import 'package:flutter/material.dart';

final Map<String, Widget Function(BuildContext)> appRoutes = {
  "login": (_) => const LoginPage(),
  "principal": (_) => const PrincipalPage(),
  "todos": (_) => const TodosPage(),
  "pedido": (_) => const PedidoPage(),
  "ventas": (_) => const StadisticPage(),
  "analysis": (_) => const AnalysisPage(),
  "stock": (_) => const StockPage(),
  "stockAlerts": (_) => const StockAlertsPage(),
  "catalogo": (_) => const CatalogoPage(),
};
