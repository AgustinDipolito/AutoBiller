class Itm {
  final String nombre, tipo;
  final int precio;
  int precioT, cantidad = 0;
  bool status = false;
  late String color;

  Itm({
    required this.precio,
    required this.nombre,
    required this.tipo,
    required this.precioT,
    required this.cantidad,
  });
}
