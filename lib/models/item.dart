class Item {
  String nombre;
  final String tipo;
  final int precio;
  final int id;
  int precioT;
  int cantidad = 0;
  bool faltante = false;

  Item({
    required this.precio,
    required this.nombre,
    required this.id,
    required this.tipo,
    required this.precioT,
    required this.cantidad,
  });

  Item.fromJson(Map<String, dynamic> json)
      : precio = int.parse(json["precio"]),
        nombre = json["nombre"],
        tipo = json["tipo"] ?? '',
        precioT = int.parse(json["precioT"]),
        id = int.parse(json["id"] ?? '0'),
        faltante = json["faltante"] == 'true',
        cantidad = int.parse(json["cantidad"]);

  Map<String, dynamic> toJson() {
    return {
      "precio": precio.toString(),
      "nombre": nombre,
      "tipo": tipo,
      "precioT": precioT.toString(),
      "cantidad": cantidad.toString(),
      "id": id.toString(),
      "faltante": faltante.toString(),
    };
  }
}
