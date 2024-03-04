import 'package:flutter/material.dart';
import 'package:dist_v2/models/item.dart';

class Pedido {
  final String nombre;
  String? msg;
  final int total;
  final DateTime fecha;
  late final List<Item> lista;
  final Key key;

  Pedido({
    required this.nombre,
    required this.fecha,
    required this.lista,
    required this.key,
    required this.total,
    this.msg,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
      nombre: json["nombre"],
      fecha: DateTime.parse(json["fecha"]),
      lista: List<Item>.from(json["lista"].map((x) => Item.fromJson(x))),
      key: ValueKey(json["key"]),
      total: int.parse(json["total"]),
      msg: json['msg']);

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "lista": lista,
      "key": key.toString(),
      "total": total.toString(),
      'msg': msg,
    };
  }
}
