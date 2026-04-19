import '../models/vip_item.dart';

class ReporteVentas {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double ventasTotales;
  final double ventasPromedio;
  final int cantidadPedidos;
  final double ticketPromedio;
  final List<VipItem> productosTopVentas; // por cantidad
  final List<VipItem> productosTopRecaudado; // por recaudado
  final List<VipItem> productosTopExitosas; // top en ventas exitosas
  final int cantidadVentasExitosas;
  final Map<String, double> ventasPorDia;
  final double crecimientoVsPeriodoAnterior;
  final int diasConVentas;
  final double ventaMayorDia;
  final double ventaMenorDia;
  final String diaConMasVentas;
  final String diaConMenosVentas;

  ReporteVentas({
    required this.fechaInicio,
    required this.fechaFin,
    required this.ventasTotales,
    required this.ventasPromedio,
    required this.cantidadPedidos,
    required this.ticketPromedio,
    required this.productosTopVentas,
    required this.productosTopRecaudado,
    required this.productosTopExitosas,
    required this.cantidadVentasExitosas,
    required this.ventasPorDia,
    required this.crecimientoVsPeriodoAnterior,
    required this.diasConVentas,
    required this.ventaMayorDia,
    required this.ventaMenorDia,
    required this.diaConMasVentas,
    required this.diaConMenosVentas,
  });
}
