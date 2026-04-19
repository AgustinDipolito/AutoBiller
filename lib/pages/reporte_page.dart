import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/reporte_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportePage extends StatefulWidget {
  const ReportePage({super.key});

  @override
  State<ReportePage> createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {
  final reporteService = ReporteService();

  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    // Inicializar fechas por defecto
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = now.month == 1
        ? DateTime(now.year - 1, 12, now.day)
        : DateTime(now.year, now.month - 1, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final clienteService = Provider.of<ClienteService>(context);
    final pedidos = clienteService.clientes;

    // Regenerar reporte con las fechas actuales
    final reporte = reporteService.generarReporte(pedidos, _start, _end);

    final quickRanges = [
      {
        'label': 'Última semana',
        'start': DateTime.now().subtract(const Duration(days: 7)),
        'end': DateTime.now()
      },
      {
        'label': 'Este mes',
        'start': DateTime(DateTime.now().year, DateTime.now().month, 1),
        'end': DateTime.now()
      },
      {
        'label': 'Mes anterior',
        'start': DateTime.now().month == 1
            ? DateTime(DateTime.now().year - 1, 12, 1)
            : DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
        'end': DateTime(DateTime.now().year, DateTime.now().month, 0)
      },
    ];
    String selectedQuick = '';
    for (final range in quickRanges) {
      final DateTime rStart = range['start'] as DateTime;
      final DateTime rEnd = range['end'] as DateTime;
      if (_start.year == rStart.year &&
          _start.month == rStart.month &&
          _start.day == rStart.day &&
          _end.year == rEnd.year &&
          _end.month == rEnd.month &&
          _end.day == rEnd.day) {
        selectedQuick = range['label'] as String;
        break;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Range Selector
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seleccionar rango de fechas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...quickRanges.map((range) => ChoiceChip(
                            label: Text(range['label'] as String),
                            selected: selectedQuick == range['label'],
                            onSelected: (_) {
                              setState(() {
                                _start = range['start'] as DateTime;
                                _end = range['end'] as DateTime;
                              });
                            },
                          )),
                      ChoiceChip(
                        label: const Text('Personalizado'),
                        selected: selectedQuick == '',
                        onSelected: (_) async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(start: _start, end: _end),
                          );
                          if (picked != null) {
                            setState(() {
                              _end = picked.end;

                              _start = picked.start;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Rango actual: ${_formatDate(_start)} - ${_formatDate(_end)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          // Header Card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPORTE ÚLTIMO MES',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(reporte.fechaInicio)} - ${_formatDate(reporte.fechaFin)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Primary KPIs Row
          Wrap(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _KpiCard(
                label: 'Ventas Totales',
                value: reporte.ventasTotales.toStringAsFixed(2),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              _KpiCard(
                label: 'Pedidos',
                value: reporte.cantidadPedidos.toString(),
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
              _KpiCard(
                label: 'Ticket Promedio',
                value: reporte.ticketPromedio.toStringAsFixed(2),
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
              _KpiCard(
                label: 'Ventas Exitosas',
                value: reporte.cantidadVentasExitosas.toString(),
                icon: Icons.verified,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Performance Analysis Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Análisis de Rendimiento',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                      'Venta promedio por día: ${reporte.ventasPromedio.toStringAsFixed(2)}'),
                  Text('Días con ventas: ${reporte.diasConVentas}'),
                  Row(
                    children: [
                      const Text('Crecimiento vs período anterior: '),
                      Text(
                        '${(reporte.crecimientoVsPeriodoAnterior * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: reporte.crecimientoVsPeriodoAnterior >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Top Products by Quantity
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top 5 Productos por Cantidad',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...reporte.productosTopVentas.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: _buildMedal(idx),
                      title: Text(item.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${item.cantTotal}'),
                          Text('Total: ${item.recaudado.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Top Products by Revenue
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top 5 Productos por Recaudación',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...reporte.productosTopRecaudado.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: _buildMedal(idx),
                      title: Text(item.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${item.cantTotal}'),
                          Text('Total: ${item.recaudado.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Top Products in Successful Sales
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top 5 Productos en Ventas Exitosas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...reporte.productosTopExitosas.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: _buildMedal(idx),
                      title: Text(item.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${item.cantTotal}'),
                          Text('Total: ${item.recaudado.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Day Analysis Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Análisis por Día',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                      'Mejor día: ${reporte.diaConMasVentas} ( 24${reporte.ventaMayorDia.toStringAsFixed(2)})'),
                  Text(
                      'Peor día: ${reporte.diaConMenosVentas} ( 24${reporte.ventaMenorDia.toStringAsFixed(2)})'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedal(int idx) {
    switch (idx) {
      case 0:
        return const Icon(Icons.emoji_events, color: Colors.amber);
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.grey);
      case 2:
        return const Icon(Icons.emoji_events, color: Colors.brown);
      default:
        return const Icon(Icons.star_border);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
