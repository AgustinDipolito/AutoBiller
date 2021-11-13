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

  Itm.fromJson(Map<String, dynamic> json)
      : precio = int.parse(json["precio"]),
        nombre = json["nombre"],
        tipo = json["tipo"],
        precioT = int.parse(json["precioT"]),
        cantidad = int.parse(json["cantidad"]);

  Map<String, dynamic> toJson() {
    return {
      "precio": precio.toString(),
      "nombre": nombre,
      "tipo": tipo,
      "precioT": precioT.toString(),
      "cantidad": cantidad.toString(),
    };
  }
}
