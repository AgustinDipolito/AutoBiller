import 'package:flutter/material.dart';
import 'package:dist_v2/models/item.dart';

class Pedido {
  final String nombre;
  String? msg;
  final int total;
  final DateTime fecha;
  late final List<Item> lista;
  final Key key;
  double? discountPercentage; // Porcentaje de descuento
  double? balance; // Saldo anterior
  bool firebaseSynced; // Marca si ya fue subido a Firebase

  Pedido({
    required this.nombre,
    required this.fecha,
    required this.lista,
    required this.key,
    required this.total,
    this.msg,
    this.discountPercentage,
    this.balance,
    this.firebaseSynced = false,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
      nombre: json["nombre"],
      fecha: DateTime.parse(json["fecha"]),
      lista: List<Item>.from(json["lista"].map((x) => Item.fromJson(x))),
      key: ValueKey(json["key"]),
      total: int.parse(json["total"]),
      msg: json['msg'],
      discountPercentage: json['discountPercentage'] != null
          ? double.parse(json['discountPercentage'].toString())
          : null,
      balance: json['balance'] != null ? double.parse(json['balance'].toString()) : null,
      firebaseSynced: json['firebaseSynced'] == true);

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "lista": lista.map((x) => x.toJson()).toList(),
      "key": key.toString(),
      "total": total.toString(),
      'msg': msg,
      'discountPercentage': discountPercentage?.toString(),
      'balance': balance?.toString(),
      'firebaseSynced': firebaseSynced,
    };
  }
}
