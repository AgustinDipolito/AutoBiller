import 'package:fl_chart/fl_chart.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/helpers/time_serires_gen.dart';

class GraphsPage extends StatelessWidget {
  const GraphsPage({super.key, this.item});
  final VipItem? item;
  static const List<String> tipos = ['semana', 'mes', 'año'];

  @override
  Widget build(BuildContext context) {
    final clienteService = Provider.of<ClienteService>(context);
    final compact = NumberFormat.compactCurrency(name: "\$", decimalDigits: 0);
    final long = NumberFormat.currency(name: "\$", decimalDigits: 0);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        itemCount: tipos.length,
        itemBuilder: (_, int index) {
          final pedidos = clienteService.clientes;
          final List<TimeSeriesSales> dataGraph;
          if (item != null) {
            final data =
                Provider.of<AnalysisService>(context).getItemTimeSeries(item!, pedidos);

            final pedidosSoloItem = data.entries
                .map((e) => Pedido(
                    nombre: '',
                    fecha: e.key,
                    lista: [],
                    key: Key(e.key.toString()),
                    total: e.value))
                .toList();

            dataGraph = calculateTotals(pedidosSoloItem, tipos[index]);
          } else {
            dataGraph = calculateTotals(pedidos, tipos[index]);
          }
          final total = dataGraph.fold<double>(0, (prev, e) => prev + e.sales);

          String totalWord = index != 0 ? compact.format(total) : long.format(total);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey.shade800,
                  Colors.blueGrey.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última ${tipos[index]}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalWord,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dataGraph.length} períodos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Grafico(data: dataGraph, tipo: tipos[index]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Grafico extends StatelessWidget {
  final List<TimeSeriesSales> data;
  final String tipo;

  const Grafico({super.key, required this.data, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isNotEmpty
        ? data.map((e) => e.sales).reduce((a, b) => a > b ? a : b).toDouble() * 1.2
        : 100.0;

    // Ajustar ancho de barras según cantidad de datos
    double barWidth;
    if (data.length > 30) {
      barWidth = 2; // Año (muchos datos)
    } else if (data.length > 10) {
      barWidth = 14; // Mes
    } else {
      barWidth = 20; // Semana
    }

    final barGroups = data.asMap().entries.map((entry) {
      final value = entry.value.sales.toDouble();
      final normalizedValue = maxY > 0 ? value / maxY : 0;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.orange.shade700,
                Colors.orange.shade400,
                normalizedValue > 0.7 ? Colors.yellow.shade300 : Colors.orange.shade300,
              ],
            ),
            width: barWidth,
            borderRadius: BorderRadius.vertical(top: Radius.circular(barWidth / 4)),
          ),
        ],
      );
    }).toList();

    // Formato de fecha según tipo de período
    String formatDate(DateTime date) {
      if (tipo == 'año') {
        return DateFormat('MMM').format(date);
      } else if (tipo == 'mes') {
        return DateFormat('dd/MM').format(date);
      } else {
        return DateFormat('EEE dd').format(date);
      }
    }

    // Mostrar menos labels en el eje X cuando hay muchos datos
    int getLabelInterval() {
      if (data.length > 30) return 10; // Mostrar cada 6 para año (bimestral)
      if (data.length > 5) return 5; // Mostrar cada 3 para mes
      return 1; // Mostrar todos para semana
    }

    final labelInterval = getLabelInterval();

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * .35,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
      child: BarChart(
        BarChartData(
          alignment:
              data.length > 20 ? BarChartAlignment.start : BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < data.length) {
                  final item = data[groupIndex];
                  final formattedSales = NumberFormat.currency(
                    symbol: '\$',
                    locale: ' es_ES',
                    decimalDigits: 0,
                  ).format(item.sales);

                  return BarTooltipItem(
                    '${formatDate(item.weekday)}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: formattedSales,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length && index % labelInterval == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        formatDate(data[index].weekday),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return Container();

                  String label;
                  if (value >= 1000000) {
                    label = '\$${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value >= 1000) {
                    label = '\$${(value / 1000).toStringAsFixed(0)}k';
                  } else {
                    label = '\$${value.toInt()}';
                  }

                  return Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                dashArray: [5, 5],
              );
            },
          ),
        ),
      ),
    );
  }
}
