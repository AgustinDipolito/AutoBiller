class VipItem {
  final String nombre;
  final int id;
  int cantTotal;
  int recaudado;

  int repeticiones = 1;

  double get recaudacionMediaPedido => (recaudado / repeticiones);
  static String get propTittles =>
      "Nombre, Cantidad Total, Recaudado, Repeticiones, Recaudacion Media Pedido";

  VipItem({
    required this.id,
    required this.nombre,
    this.repeticiones = 1,
    required this.cantTotal,
    required this.recaudado,
  });

  //human legible constructor for csv
  @override
  String toString() {
    return "${nombre.replaceAll(',', '.')}, $cantTotal, $recaudado, $repeticiones, $recaudacionMediaPedido";
  }
}
