class VipItem {
  final String nombre;
  final int id;
  int cantTotal;
  int recaudado;

  int repeticiones = 1;

  double get recaudacionMediaPedido => (recaudado / repeticiones);

  VipItem({
    required this.id,
    required this.nombre,
    this.repeticiones = 0,
    required this.cantTotal,
    required this.recaudado,
  });
}
