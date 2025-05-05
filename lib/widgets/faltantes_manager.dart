import 'package:dist_v2/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaltantesManager extends StatelessWidget {
  const FaltantesManager({
    Key? key,
    required this.clienteService,
  }) : super(key: key);

  final ClienteService clienteService;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.warning_amber_rounded, color: kDefaultIconDarkColor),
      tooltip: 'Ver faltantes',
      onPressed: () {
        final pedidosConFaltantes = clienteService.clientes
            .where((pedido) => pedido.lista.any((item) => item.faltante))
            .toList();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Faltantes en todos los pedidos'),
            content: SizedBox(
              width: 300,
              child: pedidosConFaltantes.isEmpty
                  ? const Text('No hay items marcados como faltantes.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: pedidosConFaltantes.length,
                      itemBuilder: (context, i) {
                        final pedido = pedidosConFaltantes[i];
                        final faltantes =
                            pedido.lista.where((item) => item.faltante).toList();
                        return ExpansionTile(
                          title: Text(
                            pedido.nombre,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: faltantes
                              .map((item) => ListTile(
                                    title: Text(item.nombre),
                                    subtitle: Text(item.tipo),
                                    trailing: Text('x${item.cantidad}'),
                                  ))
                              .toList(),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  // Gather all faltantes from all pedidos
                  final allFaltantes = <Map<String, dynamic>>[];
                  for (final pedido in pedidosConFaltantes) {
                    for (final item in pedido.lista.where((item) => item.faltante)) {
                      allFaltantes.add({
                        'nombre': item.nombre,
                        'tipo': item.tipo,
                        'cantidad': item.cantidad,
                      });
                    }
                  }
                  // Group and sum by nombre+tipo
                  final Map<String, Map<String, dynamic>> grouped = {};
                  for (final item in allFaltantes) {
                    final key = '${item['nombre']}|${item['tipo']}';
                    if (!grouped.containsKey(key)) {
                      grouped[key] = {
                        'nombre': item['nombre'],
                        'tipo': item['tipo'],
                        'cantidad': item['cantidad'],
                      };
                    } else {
                      grouped[key]!['cantidad'] += item['cantidad'] as int;
                    }
                  }
                  // Sort by nombre
                  final sorted = grouped.values.toList()
                    ..sort((a, b) =>
                        a['nombre'].toString().compareTo(b['nombre'].toString()));
                  // Generate markdown
                  final buffer = StringBuffer();
                  buffer.writeln('*Faltantes*');
                  for (final item in sorted) {
                    buffer.writeln('- x${item['cantidad']} ${item['nombre']}');
                  }

                  final markdown = buffer.toString();
                  // Copy to clipboard
                  await Clipboard.setData(ClipboardData(text: markdown));
                  // Close dialog
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiados al portapapeles!')),
                  );
                },
                child: const Text('Exportar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
