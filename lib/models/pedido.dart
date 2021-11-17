import 'package:dist_v2/models/Itm.dart';
import 'package:flutter/material.dart';

class Pedido {
  final String nombre;
  final int total;
  final DateTime fecha;
  late final List<Itm> lista;
  String? listaString = "";
  final Key key;
  final int intKey;

  Pedido({
    required this.intKey,
    required this.nombre,
    required this.fecha,
    required this.lista,
    required this.key,
    required this.total,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        nombre: json["nombre"],
        fecha: DateTime.parse(json["fecha"]),
        lista: List<Itm>.from(json["lista"].map((x) => Itm.fromJson(x))),
        key: ValueKey(json["key"]),
        total: int.parse(json["total"]),
        intKey: int.parse(json["intKey"]),
      );

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "lista": lista,
      "key": key.toString(),
      "total": total.toString(),
      "intKey": intKey.toString(),
    };
  }
}
