class Stock {
  final int id;
  int cant;
  String name;
  DateTime fechaMod;
  int ultimoMov;
  StockType type;
  Proveedor proveedor;

  Stock({
    required this.fechaMod,
    required this.ultimoMov,
    required this.cant,
    required this.name,
    required this.id,
    this.type = StockType.otro,
    this.proveedor = Proveedor.otro,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        cant: int.parse(json['cant']),
        name: json['name'],
        id: int.parse(json['id']),
        type: StockType.values[int.parse(json['type'] ?? '10')],
        proveedor: Proveedor.values[int.parse(json['proveedor'] ?? '8')],
        fechaMod: json['date'] != null ? DateTime.parse(json['date']) : DateTime(2023),
        ultimoMov: 0, // json['ultimaCant'] != null ? int.parse(json['ultimaCant']) : 0,
      );

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "cant": cant.toString(),
      "id": id.toString(),
      "date": fechaMod.toString(),
      "ultimaCant": ultimoMov.toString(),
      "type": type.index.toString(),
      "proveedor": proveedor.index.toString(),
    };
  }
}

enum StockType {
  burlete,
  cierre,
  manija,
  cerradura,
  bisagra,
  escuadra,
  rodamiento,
  plastico,
  tela,
  accesorio,
  otro
}

enum Proveedor {
  axal,
  flexico,
  bronzen,
  azzurra,
  dom,
  templast,
  dylplast,
  plastic,
  otro,
}
