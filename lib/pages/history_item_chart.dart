import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/pages/graphs_page.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../api/api.dart';

charts.Series<DateTime, DateTime> _createSeries(Map<DateTime, int> data) {
  return charts.Series<DateTime, DateTime>(
    id: 'Ventas',

    colorFn: (_, __) => charts.MaterialPalette.white, // blueGrey shade
    domainFn: (DateTime date, _) => date,
    measureFn: (DateTime date, _) => data[date],
    data: data.keys.toList(),
  );
}

charts.RangeAnnotationSegment<Object> _createStockAnnotation(num avgSales) {
  return charts.RangeAnnotationSegment(
    avgSales,
    avgSales * 2,
    charts.RangeAnnotationAxisType.measure,
    startLabel: 'Min: $avgSales',
    endLabel: 'Max: ${avgSales * 2}',
    labelAnchor: charts.AnnotationLabelAnchor.end,
    color: charts.MaterialPalette.green.shadeDefault.lighter, // green shade
  );
}

charts.NumericAxisSpec _createMeasureAxis(num maxValue) {
  return charts.NumericAxisSpec(
    viewport: charts.NumericExtents(0, maxValue * 1.2),
    tickProviderSpec: const charts.BasicNumericTickProviderSpec(
      desiredTickCount: 5,
      zeroBound: true,
    ),
    renderSpec: const charts.GridlineRendererSpec(
      labelStyle: charts.TextStyleSpec(
        fontSize: 12,
        color: charts.MaterialPalette.white,
      ),
    ),
  );
}

charts.DateTimeAxisSpec _createDateAxis() {
  return const charts.DateTimeAxisSpec(
    tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
      day: charts.TimeFormatterSpec(
        format: 'dd/MM',
        transitionFormat: 'dd/MM/yyyy',
      ),
    ),
  );
}

class ProductChart extends StatelessWidget {
  final VipItem item;

  const ProductChart({Key? key, required this.item}) : super(key: key);

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
    return SizedBox(
      height: 300,
      child: charts.TimeSeriesChart(
        [_createSeries(movements)],
        animate: true,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        defaultRenderer: charts.LineRendererConfig(
          includeArea: true,
          areaOpacity: 0.2,
          strokeWidthPx: 2.5,
        ),
        behaviors: [
          charts.ChartTitle('Ventas Semanales',
              behaviorPosition: charts.BehaviorPosition.top),
          charts.SeriesLegend(position: charts.BehaviorPosition.bottom),
          charts.RangeAnnotation([
            _createStockAnnotation(stats['avgSales']!),
          ]),
          charts.LinePointHighlighter(
            showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
          ),
        ],
        primaryMeasureAxis: _createMeasureAxis(stats['maxSales']!),
        domainAxis: _createDateAxis(),
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
                      color: color.withOpacity(0.8),
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
