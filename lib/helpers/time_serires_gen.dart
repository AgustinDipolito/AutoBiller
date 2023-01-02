import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:flutter/cupertino.dart';

List<charts.Series<TimeSeriesSales, DateTime>> createSampleData(
    ClienteService clientes, String tipo) {
  List<TimeSeriesSales> data = [];
  int x = 0;

  List<Pedido> totaleslUltimaSem = [];
  List<Pedido> totalesUltimoMes = [];
  List<Pedido> totalesUltimoAnio = [];

  List<DateTime> fechas = [];
  clientes.setClientes = UserPreferences.getPedidos();

  while (x < clientes.clientes.length) {
    DateTime firstTime = clientes.clientes[x].fecha;

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

    if (firstTime.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
      totaleslUltimaSem.add(Pedido(
          nombre: '',
          fecha: firstTime,
          lista: [],
          key: const Key(''),
          total: total));
    }

    if (firstTime.month == DateTime.now().month) {
      totalesUltimoMes.add(Pedido(
          nombre: '',
          fecha: firstTime,
          lista: [],
          key: const Key(''),
          total: total));
    }
    if (firstTime.year == DateTime.now().year) {
      totalesUltimoAnio.add(Pedido(
          nombre: '',
          fecha: firstTime,
          lista: [],
          key: const Key(''),
          total: total));
    }
    // totales.add(total);

    x++;
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

List<TimeSeriesSales> getUltSemana(
    List<DateTime> fechas, List<Pedido> totales) {
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

  return data;
}
