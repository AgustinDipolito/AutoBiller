class ItemResponse {
  String nombre;
  String tipo;
  String id;
  int precio;

  ItemResponse(this.nombre, this.tipo, this.precio, this.id);

  ItemResponse.fromJson(json)
      : nombre = json["nombre"] as String,
        tipo = json["tipo"] ?? '',
        id = json["ID"] ?? json['id'] as String,
        precio = int.parse(json["precio"]);

  Map<String, dynamic> toJson() => {
        "nombre": nombre,
        "tipo": tipo,
        "precio": precio,
        "id": id,
      };
}
