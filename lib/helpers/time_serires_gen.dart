import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/models/user_preferences.dart';

List<charts.Series<TimeSeriesSales, DateTime>> createSampleData(
    BuildContext context, String tipo) {
  List<TimeSeriesSales> data = [];
  int x = 0;

  List<int> totales = [];
  List<DateTime> fechas = [];
  var clientes = Provider.of<ClienteService>(context);
  clientes.setClientes = UserPreferences.getPedidos();

  while (x < clientes.clientes.length) {
    DateTime firstTime = DateTime(clientes.clientes[x].fecha.year,
        clientes.clientes[x].fecha.month, clientes.clientes[x].fecha.day);

    var mismoDia = clientes.clientes.where((element) =>
        (element.fecha.day == firstTime.day) &&
        (element.fecha.month == firstTime.month));

    if (!(fechas.contains(firstTime))) {
      fechas.add(firstTime);
    }

    var total = 0;

    for (var element in mismoDia) {
      total += element.total;
    }
    totales.add(total);

    x++;
  }

  totales = totales.toSet().toList();

  switch (tipo) {
    case "semana":
      data = getUltSemana(fechas, totales);
      break;
    case "mes":
      data = getUltMes(fechas, totales);
      break;

    case "año":
      data = getUltAno(fechas, totales);
      break;
    default:
  }

  return [
    charts.Series<TimeSeriesSales, DateTime>(
      id: 'Sales',
      colorFn: (_, __) => charts.MaterialPalette.white,
      domainFn: (TimeSeriesSales sales, _) => sales.weekday,
      measureFn: (TimeSeriesSales sales, _) => sales.sales,
      data: data,
      labelAccessorFn: (TimeSeriesSales sales, _) =>
          '\$${sales.sales.toString()}',
    ),
  ];
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime weekday;
  final int sales;

  TimeSeriesSales(this.weekday, this.sales);
}

List<TimeSeriesSales> getUltSemana(List<DateTime> fechas, List<int> totales) {
  List<TimeSeriesSales> data = [];
  var ultSemana = fechas
      .where((element) =>
          element.compareTo(DateTime.now().subtract(const Duration(days: 7))) >=
          0)
      .toList();

  for (var i = 0; i < ultSemana.length; i++) {
    data.add(TimeSeriesSales(ultSemana[i], totales[i]));
  }
  return data;
}

List<TimeSeriesSales> getUltMes(List<DateTime> fechas, List<int> totales) {
  List<TimeSeriesSales> data = [];

  var ultMes =
      fechas.where((element) => DateTime.now().month == element.month).toList();

  for (var i = 0; i < ultMes.length; i++) {
    data.add(TimeSeriesSales(ultMes[i], totales[i]));
  }
  return data;
}

List<TimeSeriesSales> getUltAno(List<DateTime> fechas, List<int> totales) {
  List<TimeSeriesSales> data = [];
  var ultAno =
      fechas.where((element) => DateTime.now().year == element.year).toList();

  for (var i = 0; i < ultAno.length; i++) {
    data.add(TimeSeriesSales(ultAno[i], totales[i]));
  }

  return data;
}
