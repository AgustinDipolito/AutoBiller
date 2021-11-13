import 'dart:convert';

import 'package:dist_v2/models/user_preferences.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void savePedido(BuildContext context, String name) async {
  final pedidoService = Provider.of<PedidoService>(context, listen: false);
  final clienteService = Provider.of<ClienteService>(context, listen: false);
  try {
    clienteService.guardarPedido(
      name,
      pedidoService.giveSaved(),
      pedidoService.sumTot(),
    );
    pedidoService.clearAll();

    String pedidos = json.encode(clienteService.clientes);
    await UserPreferences.setPedido(pedidos);
  } catch (e) {
    print("EEEEEEError:  $e");
  }
}
