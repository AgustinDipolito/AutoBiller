import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/pages/history_item_chart.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late AnalysisService analysisService;
  late ClienteService clientesService;
  final List<VipItem> _selectedItems = [];
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final List<Pedido> pedidos = clientesService.clientes;
      analysisService.init(pedidos);
    });
  }

  @override
  Widget build(BuildContext context) {
    clientesService = Provider.of<ClienteService>(context);
    analysisService = Provider.of<AnalysisService>(context);

    return Scaffold(
      floatingActionButton: _selectedItems.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final clienteService =
                    Provider.of<ClienteService>(context, listen: false);

                clienteService
                    .renameItems(
                  _selectedItems.map((e) => e.nombre.toLowerCase()).toSet().toList(),
                  _selectedItems.first.nombre,
                )
                    .then((cant) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$cant pedidos renombrados exitosamente'),
                      ),
                    );
                    analysisService.init(clienteService.clientes);
                  }
                });
                setState(() {
                  _selectedItems.clear();
                });
              },
              child: const Icon(Icons.edit),
            ),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        actions: [
          _button(
            name: 'EXPORT EXCEL',
            action: () {
              analysisService.export();
            },
          ),
          _button(
            name: 'DATASET',
            action: () => _exportDataset(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ColoredBox(
            color: Colors.blueGrey,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _button(
                    name: 'abc',
                    action: () {
                      analysisService.sortList(SortBy.nameUp);
                    },
                  ),
                  _button(
                    name: 'max cant',
                    action: () {
                      analysisService.sortList(SortBy.cantDown);
                    },
                  ),
                  _button(
                    name: 'min cant',
                    action: () {
                      analysisService.sortList(SortBy.cantUp);
                    },
                  ),
                  _button(
                    name: 'max rep',
                    action: () {
                      analysisService.sortList(SortBy.repsDown);
                    },
                  ),
                  _button(
                    name: 'min rep',
                    action: () {
                      analysisService.sortList(SortBy.repsUp);
                    },
                  ),
                  _button(
                    name: '\$\$\$',
                    action: () {
                      analysisService.sortList(SortBy.raisedDown);
                    },
                  ),
                  _button(
                    name: '\$',
                    action: () {
                      analysisService.sortList(SortBy.raisedUp);
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: analysisService.searchItems,
              decoration: const InputDecoration(
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                hintText: "Buscar...",
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              itemCount: analysisService.filteredItems.length,
              itemBuilder: (_, int index) {
                final item = analysisService.filteredItems[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ListTile(
                      title: Text(item.nombre),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Utils.formatPrice(item.recaudado.toDouble())),
                          Text('Total: ${item.cantTotal}'),
                          Text('Reps: ${item.repeticiones}'),
                        ],
                      ),
                      selected: _selectedItems.contains(item),
                      onLongPress: () {
                        setState(() {
                          if (_selectedItems.contains(item)) {
                            _selectedItems.remove(item);
                          } else {
                            _selectedItems.add(item);
                          }
                        });
                      },
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductChart(
                              item: item,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(
                      color: Colors.blueGrey,
                      endIndent: 16,
                      indent: 16,
                      thickness: 0,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({required Function() action, required String name}) {
    return TextButton(
      onPressed: action,
      child: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _exportDataset(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dataset'),
        content: const Text(
          'Seleccione el formato de dataset para minería de datos:\n\n'
          '• Productos Agregados: Métricas por producto (frecuencia, precios, volumen)\n\n'
          '• Transacciones: Cada fila es un item de un pedido (análisis temporal y patrones)'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'productos'),
            icon: const Icon(Icons.analytics),
            label: const Text('Productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'transacciones'),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Transacciones'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        if (result == 'productos') {
          await analysisService.exportDataset(clientesService.clientes);
        } else {
          await analysisService.exportTransactionDataset(clientesService.clientes);
        }

        if (mounted) {
          Navigator.pop(context); // Cerrar indicador
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'productos'
                    ? 'Dataset de productos exportado exitosamente'
                    : 'Dataset de transacciones exportado exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar indicador
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
