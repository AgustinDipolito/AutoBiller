import 'package:dist_v2/models/Itm.dart';
import 'package:flutter/material.dart';

class Pedido {
  final String nombre;
  String? listaString = "";
  final int total;
  final DateTime fecha;
  late final List<Itm> lista;
  final Key key;

  Pedido({
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
      );

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "lista": lista,
      "key": key.toString(),
      "total": total.toString(),
    };
  }
}
