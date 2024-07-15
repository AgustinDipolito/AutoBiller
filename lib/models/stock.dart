class Stock {
  final int id;
  int cant;
  String name;
  DateTime fechaMod;
  int ultimoMov;

  Stock(
      {required this.fechaMod,
      required this.ultimoMov,
      required this.cant,
      required this.name,
      required this.id});

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        cant: int.parse(json['cant']),
        name: json['name'],
        id: int.parse(json['id']),
        fechaMod: json['date'] != null ? DateTime.parse(json['date']) : DateTime(2023),
        ultimoMov: json['ultimaCant'] != null ? int.parse(json['ultimaCant']) : 0,
      );

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "cant": cant.toString(),
      "id": id.toString(),
      "date": fechaMod.toString(),
      "ultimaCant": ultimoMov.toString(),
    };
  }
}
