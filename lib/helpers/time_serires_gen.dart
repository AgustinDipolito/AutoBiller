import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dist_v2/models/pedido.dart';
import 'package:flutter/cupertino.dart';

List<charts.Series<TimeSeriesSales, DateTime>> calculateTotals(
    List<Pedido> clientes, String tipo) {
  List<TimeSeriesSales> data = [];
  int x = 0;

  List<Pedido> totaleslUltimaSem = [];
  List<Pedido> totalesUltimoMes = [];
  List<Pedido> totalesUltimoAnio = [];

  List<DateTime> fechas = [];

  while (x < clientes.length) {
    DateTime firstTime = clientes[x].fecha;

    var mismoDia = clientes.where((element) =>
        (element.fecha.day == firstTime.day) && (element.fecha.month == firstTime.month));

    if (!(fechas.contains(firstTime))) {
      fechas.add(firstTime);
    }
    var total = 0;

    for (var element in mismoDia) {
      total += element.total;
    }

    if (firstTime.isAfter(DateTime.now().subtract(const Duration(days: 8)))) {
      totaleslUltimaSem.add(Pedido(
          nombre: '', fecha: firstTime, lista: [], key: const Key(''), total: total));
    }

    if (firstTime.isAfter(DateTime.now().subtract(const Duration(days: 31)))) {
      totalesUltimoMes.add(Pedido(
          nombre: '', fecha: firstTime, lista: [], key: const Key(''), total: total));
    }
    if (firstTime.isAfter(DateTime.now().subtract(const Duration(days: 366)))) {
      totalesUltimoAnio.add(Pedido(
          nombre: '', fecha: firstTime, lista: [], key: const Key(''), total: total));
    }
    // totales.add(total);

    x += mismoDia.length;
  }

  // totales = totales.toSet().toList();
  totaleslUltimaSem = totaleslUltimaSem.toSet().toList();
  totalesUltimoMes = totalesUltimoMes.toSet().toList();
  totalesUltimoAnio = totalesUltimoAnio.toSet().toList();

  switch (tipo) {
    case "semana":
      data = getUltSemana(fechas, totaleslUltimaSem);
      break;
    case "mes":
      data = getUltMes(fechas, totalesUltimoMes);
      break;

    case "año":
      data = getUltAno(fechas, totalesUltimoAnio);
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
      labelAccessorFn: (TimeSeriesSales sales, _) => '\$${sales.sales.toString()}',
    ),
  ];
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime weekday;
  final int sales;

  TimeSeriesSales(this.weekday, this.sales);
}

List<TimeSeriesSales> getUltSemana(List<DateTime> fechas, List<Pedido> totales) {
  List<TimeSeriesSales> data = [];

  for (var element in totales) {
    data.add(TimeSeriesSales(element.fecha, element.total));
  }

  return data;
}

List<TimeSeriesSales> getUltMes(List<DateTime> fechas, List<Pedido> totales) {
  List<TimeSeriesSales> data = [];

  for (var element in totales) {
    data.add(TimeSeriesSales(element.fecha, element.total));
  }

  return data;
}

List<TimeSeriesSales> getUltAno(List<DateTime> fechas, List<Pedido> totales) {
  List<TimeSeriesSales> data = [];
  for (var element in totales) {
    data.add(TimeSeriesSales(element.fecha, element.total));
  }
  return data;
}
