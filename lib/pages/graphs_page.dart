import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dist_v2/helpers/time_serires_gen.dart';

class GraphsPage extends StatelessWidget {
  const GraphsPage({Key? key}) : super(key: key);
  static const List<String> tipos = ['semana', 'mes', 'año'];

  @override
  Widget build(BuildContext context) {
    final clientes = Provider.of<ClienteService>(context);
    final compact = NumberFormat.compactCurrency(name: "\$", decimalDigits: 0);
    final long = NumberFormat.currency(name: "\$", decimalDigits: 0);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, int index) {
          var sampleData = createSampleData(clientes, tipos[index]);
          var total = 0;

          for (var element in sampleData.first.data) {
            total += element.sales;
          }

          String totalWord =
              index != 0 ? compact.format(total) : long.format(total);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Grafico(
                tipo: tipos[index],
                data: sampleData,
              ),
              Text('Total ${tipos[index]}:\n $totalWord'),
            ],
          );
        },
      ),
    );
  }
}

class Grafico extends StatelessWidget {
  final List<charts.Series<TimeSeriesSales, DateTime>> data;

  const Grafico({Key? key, required this.tipo, required this.data})
      : super(key: key);
  final String tipo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .7,
      height: MediaQuery.of(context).size.height * .7,
      padding: const EdgeInsets.only(left: 10, top: 25),
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
