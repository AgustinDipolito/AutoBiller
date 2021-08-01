class Item {
  String nombre, tipo, id;
  int precio;

  Item(this.nombre, this.tipo, this.precio, this.id);

  Item.fromJson(json)
      : nombre = json["nombre"] as String,
        tipo = json["tipo"] as String,
        id = json["id"] as String,
        precio = int.parse(json["precio"]);

  Map<String, dynamic> toJson() => {
        "nombre": nombre,
        "tipo": tipo,
        "precio": precio,
        "id": id,
      };
}
