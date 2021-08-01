import 'package:dist_v2/pages/pedido_page.dart';
import 'package:dist_v2/pages/principal_page.dart';
import 'package:dist_v2/pages/todos_page.dart';

import 'package:flutter/material.dart';

final Map<String, Widget Function(BuildContext)> appRoutes = {
  "principal": (_) => PrincipalPage(),
  "todos": (_) => TodosPage(),
  "pedido": (_) => PedidoPage(),
};
