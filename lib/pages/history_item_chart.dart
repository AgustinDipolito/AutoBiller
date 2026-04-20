import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/pages/graphs_page.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../api/api.dart';

List<FlSpot> _createSpots(Map<DateTime, int> data) {
  final sortedEntries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  return sortedEntries.asMap().entries.map((entry) {
    return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
  }).toList();
}

class ProductChart extends StatelessWidget {
  final VipItem item;

  const ProductChart({super.key, required this.item});

  Future<void> _exportToPDF(Map<DateTime, int> movements, Map<String, num> stats) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de Ventas - ${item.nombre}'),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Ventas',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                ...movements.entries.map((e) => pw.TableRow(
                      children: [
                        pw.Text(DateFormat('dd/MM/yyyy').format(e.key)),
                        pw.Text(e.value.toString()),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );

    final file = await FileApi.saveDocument(
      name: '${item.nombre}_ventas.pdf',
      pdf: pdf,
    );
    await FileApi.openFile(file);
  }

  @override
  Widget build(BuildContext context) {
    final analysisService = Provider.of<AnalysisService>(context);
    final clienteService = Provider.of<ClienteService>(context);

    final rawMovements = analysisService.getItemTimeSeries(
      item,
      clienteService.clientes,
    );

    final Map<DateTime, int> movements = {};
    for (var entry in rawMovements.entries) {
      // Get the start of the week (Monday)
      final weekStart = entry.key.subtract(
        Duration(days: entry.key.weekday - 1),
      );
      movements.update(
        weekStart,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }

    final stats = _calculateStats(movements);

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text(item.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar reporte',
            onPressed: () => _exportToPDF(movements, stats),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsGrid(stats),
              const SizedBox(height: 24),
              _buildChart(movements, stats),
              _buildDetailsCard(stats),
              const Divider(height: 32),
              SizedBox(
                height: 300,
                child: GraphsPage(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, num> stats) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      // childAspectRatio: 1.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _StatCard(
          title: 'Promedio',
          value: stats['avgSales']!.toString(),
          subtitle: 'unidades/semana',
          icon: Icons.trending_up,
          color: Colors.blueGrey.shade700,
        ),
        _StatCard(
          title: 'Stock Ideal',
          value: (stats['avgSales']! * 2).toString(),
          subtitle: 'unidades',
          icon: Icons.inventory,
          color: Colors.blueGrey.shade600,
        ),
        _StatCard(
          title: 'Eficiencia',
          value: '${stats['efficiency']}%',
          subtitle:
              '${stats['totalWeeks']! - stats['zeroSalesWeeks']!}/${stats['totalWeeks']} semanas',
          icon: Icons.analytics,
          color: Colors.blueGrey.shade500,
        ),
        _StatCard(
          title: 'Tendencia',
          value: '${stats['trend']}%',
          subtitle: stats['trend']! >= 0 ? 'incremento' : 'decremento',
          icon: stats['trend']! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          color:
              stats['trend']! >= 0 ? Colors.blueGrey.shade400 : Colors.blueGrey.shade800,
        ),
      ],
    );
  }

  Map<String, num> _calculateStats(Map<DateTime, int> movements) {
    final nonZeroSales = movements.values.where((e) => e > 0);
    final totalWeeks = movements.length;
    final avgSales = nonZeroSales.isEmpty
        ? 0
        : (nonZeroSales.reduce((a, b) => a + b) / nonZeroSales.length).ceil();
    final minSales =
        nonZeroSales.isEmpty ? 0 : nonZeroSales.reduce((a, b) => a < b ? a : b);
    final maxSales =
        nonZeroSales.isEmpty ? 0 : nonZeroSales.reduce((a, b) => a > b ? a : b);
    final zeroSalesWeeks = movements.values.where((e) => e == 0).length;
    final efficiency = movements.isEmpty
        ? 0
        : ((movements.values.where((e) => e > 0).length / movements.length) * 100)
            .round();
    final trend = nonZeroSales.isEmpty
        ? 0
        : ((nonZeroSales.last - nonZeroSales.first) / nonZeroSales.first * 100).round();

    return {
      'avgSales': avgSales,
      'minSales': minSales,
      'maxSales': maxSales,
      'efficiency': efficiency,
      'totalWeeks': totalWeeks,
      'zeroSalesWeeks': zeroSalesWeeks,
      'trend': trend,
    };
  }

  Widget _buildDetailsCard(Map<String, num> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.maxFinite),
            const Text('Detalles Adicionales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ventas Máximas: ${stats['maxSales']}'),
            Text('Ventas Mínimas: ${stats['minSales']}'),
            Text('Promedio de Ventas: ${stats['avgSales']}'),
            Text('Eficiencia: ${stats['efficiency']}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<DateTime, int> movements, Map<String, num> stats) {
    final spots = _createSpots(movements);
    final maxY = stats['maxSales']!.toDouble() * 1.2;
    final avgSales = stats['avgSales']!.toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxY / 5,
            verticalInterval: spots.length > 1 ? (spots.length - 1) / 5 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
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
                reservedSize: 30,
                interval: spots.length > 5 ? (spots.length / 5).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= movements.length) return Container();

                  final sortedDates = movements.keys.toList()..sort();
                  if (index < sortedDates.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat('dd/MM').format(sortedDates[index]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
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
                interval: maxY / 5,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          minX: 0,
          maxX: spots.isNotEmpty ? spots.length - 1.0 : 0,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueGrey.shade300,
                  Colors.blueGrey.shade500,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.blueGrey.shade500,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueGrey.shade300.withValues(alpha: 0.3),
                    Colors.blueGrey.shade500.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          // Add horizontal line for average sales
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avgSales,
                color: Colors.green.shade300,
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) => 'Promedio: ${avgSales.toInt()}',
                ),
              ),
              HorizontalLine(
                y: avgSales * 2,
                color: Colors.orange.shade300,
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, top: 5),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) => 'Stock ideal: ${(avgSales * 2).toInt()}',
                ),
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (LineBarSpot spot) => Colors.blueGrey.shade800,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final index = flSpot.x.toInt();
                  final sortedDates = movements.keys.toList()..sort();

                  if (index < sortedDates.length) {
                    return LineTooltipItem(
                      '${DateFormat('dd/MM/yyyy').format(sortedDates[index])}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Ventas: ${flSpot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}

// Helper widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Tooltip(
        message: '$title: $value ($subtitle)',
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
