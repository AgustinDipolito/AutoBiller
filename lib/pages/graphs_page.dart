import 'package:charts_flutter/flutter.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dist_v2/helpers/time_serires_gen.dart';

class GraphsPage extends StatelessWidget {
  const GraphsPage({Key? key, this.item}) : super(key: key);
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
          final List<Series<TimeSeriesSales, DateTime>> dataGraph;
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
          final total = dataGraph.first.data.fold<double>(0, (prev, e) => prev + e.sales);

          String totalWord = index != 0 ? compact.format(total) : long.format(total);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Text('Ult. ${tipos[index]}: $totalWord'),
              Grafico(data: dataGraph),
            ],
          );
        },
      ),
    );
  }
}

class Grafico extends StatelessWidget {
  final List<charts.Series<TimeSeriesSales, DateTime>> data;

  const Grafico({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * .3,
      padding: const EdgeInsets.only(left: 10),
      child: charts.TimeSeriesChart(
        data,
        animate: true,
        defaultInteractions: false,
        defaultRenderer: charts.BarRendererConfig(),
        primaryMeasureAxis: const charts.NumericAxisSpec(
          showAxisLine: true,
          tickProviderSpec: charts.BasicNumericTickProviderSpec(
            desiredTickCount: 5,
            zeroBound: true,
          ),
        ),
        behaviors: [charts.DomainHighlighter(), charts.PanAndZoomBehavior()],
      ),
    );
  }
}
