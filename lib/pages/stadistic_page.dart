import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dist_v2/helpers/time_serires_gen.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StadisticPage extends StatelessWidget {
  const StadisticPage({Key? key}) : super(key: key);

  static const List<String> tipos = ['semana', 'mes', 'año'];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.grey.shade600, Colors.grey.shade400]),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Ventas'),
          ),
          backgroundColor: Colors.transparent,
          body: ListView.builder(
            itemCount: 3,
            itemBuilder: (_, int index) {
              var total = 0;
              final compact =
                  NumberFormat.compactCurrency(name: "\$", decimalDigits: 0);
              final long = NumberFormat.currency(name: "\$", decimalDigits: 0);

              createSampleData(context, tipos[index])
                  .first
                  .data
                  .forEach((element) {
                total += element.sales;
              });

              String totalWord =
                  index != 0 ? compact.format(total) : long.format(total);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Grafico(tipo: tipos[index]),
                  Center(
                    child: Text('Total ${tipos[index]}:\n $totalWord'),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class Grafico extends StatelessWidget {
  const Grafico({Key? key, required this.tipo}) : super(key: key);
  final String tipo;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .7,
      height: MediaQuery.of(context).size.height * .7,
      padding: const EdgeInsets.only(left: 10, top: 25),
      child: charts.TimeSeriesChart(
        createSampleData(context, tipo),
        animate: true,
        defaultRenderer: charts.BarRendererConfig(),
        defaultInteractions: false,
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
