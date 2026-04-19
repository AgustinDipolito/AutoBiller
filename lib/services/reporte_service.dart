import 'package:dist_v2/helpers/fuzzy_matcher.dart';

import '../models/reporte_ventas.dart';
import '../models/pedido.dart';
import '../models/vip_item.dart';

class ReporteService {
  /// Generates a sales report for the last month.
  ReporteVentas generarReporteUltimoMes(List<Pedido> pedidos) {
    final now = DateTime.now();
    // Normalizar a medianoche para evitar problemas con horas
    final fechaFin = DateTime(now.year, now.month, now.day);
    // Calcular mes anterior manejando el cambio de año correctamente
    final fechaInicio = now.month == 1
        ? DateTime(now.year - 1, 12, now.day)
        : DateTime(now.year, now.month - 1, now.day);
    return generarReporte(pedidos, fechaInicio, fechaFin);
  }

  /// Generates a sales report for a custom period.
  ReporteVentas generarReporte(
      List<Pedido> pedidos, DateTime fechaInicio, DateTime fechaFin) {
    // Normalizar fechas a medianoche para comparación correcta
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);

    // Filter pedidos in range - comparar solo la fecha sin hora
    final pedidosPeriodo = pedidos.where((p) {
      final fechaPedido = DateTime(p.fecha.year, p.fecha.month, p.fecha.day);
      return fechaPedido.isBefore(fin) && fechaPedido.isAfter(inicio);
    }).toList();
    final cantidadPedidos = pedidosPeriodo.length;
    final ventasTotales = pedidosPeriodo.fold<double>(0, (sum, p) => sum + p.total);
    final ticketPromedio = cantidadPedidos > 0 ? ventasTotales / cantidadPedidos : 0;

    // Day-by-day analysis
    final Map<String, double> ventasPorDia = {};
    for (var p in pedidosPeriodo) {
      final key =
          '${p.fecha.year}-${p.fecha.month.toString().padLeft(2, '0')}-${p.fecha.day.toString().padLeft(2, '0')}';
      ventasPorDia[key] = (ventasPorDia[key] ?? 0) + p.total;
    }
    final diasConVentas = ventasPorDia.length;
    final ventasPromedio = diasConVentas > 0 ? ventasTotales / diasConVentas : 0;

    // Best/worst day
    String diaConMasVentas = '';
    String diaConMenosVentas = '';
    double ventaMayorDia = 0;
    double ventaMenorDia = 0;
    if (ventasPorDia.isNotEmpty) {
      final sorted = ventasPorDia.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      diaConMasVentas = sorted.first.key;
      ventaMayorDia = sorted.first.value;
      diaConMenosVentas = sorted.last.key;
      ventaMenorDia = sorted.last.value;
    }

    // Top products by quantity and revenue
    final Map<String, VipItem> productosMapExitosas = {};
    int cantidadVentasExitosas = 0;
    for (var p in pedidosPeriodo) {
      final esExitosa = (FuzzyMatcher.similarity(p.msg ?? '', 'armado') > 9) ||
          (FuzzyMatcher.similarity(p.nombre, 'eze semanal') > 9);
      if (esExitosa) cantidadVentasExitosas++;
      for (var item in p.lista) {
        final id = item.nombre + item.tipo;

        // Exitosas
        if (esExitosa) {
          if (!productosMapExitosas.containsKey(id)) {
            productosMapExitosas[id] = VipItem(
              nombre: item.nombre,
              id: cantidadVentasExitosas,
              cantTotal: item.cantidad,
              recaudado: item.precioT,
            );
          } else {
            productosMapExitosas[id]!.cantTotal += item.cantidad;
            productosMapExitosas[id]!.recaudado += item.precioT;
          }
        }
      }
    }
    final productosTopVentas = productosMapExitosas.values.toList()
      ..sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
    final productosTopRecaudado = productosMapExitosas.values.toList()
      ..sort((a, b) => b.recaudado.compareTo(a.recaudado));
    final productosTopExitosas = productosMapExitosas.values.toList()
      ..sort((a, b) => b.cantTotal.compareTo(a.cantTotal));
    final top5 = productosTopVentas.take(5).toList();
    final top5Recaudado = productosTopRecaudado.take(5).toList();
    final top5Exitosas = productosTopExitosas.take(5).toList();

    // Period comparison
    final duracion = fin.difference(inicio);
    final prevStart = inicio.subtract(duracion).subtract(const Duration(days: 1));
    final prevEnd = inicio.subtract(const Duration(days: 1));

    final pedidosPrev = pedidos.where((p) {
      final fechaPedido = DateTime(p.fecha.year, p.fecha.month, p.fecha.day);
      return !fechaPedido.isBefore(prevStart) && !fechaPedido.isAfter(prevEnd);
    }).toList();
    final ventasPrev = pedidosPrev.fold<double>(0, (sum, p) => sum + p.total);
    final crecimientoVsPeriodoAnterior =
        ventasPrev > 0 ? (ventasTotales - ventasPrev) / ventasPrev : 0;

    return ReporteVentas(
      fechaInicio: inicio,
      fechaFin: fin,
      ventasTotales: ventasTotales.toDouble(),
      ventasPromedio: ventasPromedio.toDouble(),
      cantidadPedidos: cantidadPedidos,
      ticketPromedio: ticketPromedio.toDouble(),
      productosTopVentas: top5,
      productosTopRecaudado: top5Recaudado,
      productosTopExitosas: top5Exitosas,
      cantidadVentasExitosas: cantidadVentasExitosas,
      ventasPorDia: ventasPorDia,
      crecimientoVsPeriodoAnterior: crecimientoVsPeriodoAnterior.toDouble(),
      diasConVentas: diasConVentas,
      ventaMayorDia: ventaMayorDia.toDouble(),
      ventaMenorDia: ventaMenorDia.toDouble(),
      diaConMasVentas: diaConMasVentas,
      diaConMenosVentas: diaConMenosVentas,
    );
  }
}
