import 'package:dist_v2/models/Itm.dart';
import 'package:flutter/material.dart';
//import 'package:hive/hive.dart';

class Pedido {
  final String nombre;
  final int total;
  final DateTime fecha;
  final List<Itm> lista;
  final Key key;

  const Pedido({
    required this.nombre,
    required this.fecha,
    required this.lista,
    required this.key,
    required this.total,
  });
}
