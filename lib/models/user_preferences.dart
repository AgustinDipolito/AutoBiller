import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:collection/collection.dart';

import 'stock.dart';

class UserPreferences {
  static SharedPreferences? _preferences;
  static Future init() async => _preferences = await SharedPreferences.getInstance();

  static List<String> get _keys => _preferences?.getKeys().toList() ?? ['init'];

  static Future setPedido(String lista, String key) async {
    await _preferences!.setString("pedidos$key", lista);
  }

  static Future setStock(String stock, String key) async {
    await _preferences!.setString("stock$key", stock);
  }

  static List<Stock> getStock() {
    if (_preferences == null) {
      return [];
    }

    var key = _keys.firstWhereOrNull((element) => element.startsWith('stock'));
    if (key == null) {
      return [];
    }
    try {
      List<Stock> stock = <Stock>[];

      final json = _preferences!.getString(key) ?? '';

      if (json.isNotEmpty) {
        final maps = jsonDecode(json);
        for (var map in maps) {
          final itemStock = Stock.fromJson(map, fromFirebase: false);

          stock.add(itemStock);
        }
      }

      return stock;
    } catch (e) {
      return [];
    }
  }

  static List<Pedido> getPedidos() {
    if (_preferences == null) {
      return [];
    }
    var keys = _keys.where((element) => element.startsWith('pedido'));
    try {
      List<Pedido> pedidos = [];
      List<String> keysPedidos = [];
      var i = 0;
      for (var key in keys) {
        keysPedidos.add(_preferences!.getString(key)!);

        if (keysPedidos.isNotEmpty) {
          var map = jsonDecode(keysPedidos[i]);
          pedidos.add(Pedido.fromJson(map));
          i++;
        }
      }
      if (pedidos.length > 1) {
        pedidos.sort((a, b) => a.fecha.compareTo(b.fecha));
      }

      return pedidos.reversed.toList();
    } on Exception catch (_) {
      return [];
    }
  }

  static int getCantidadPedidos() {
    if (_preferences == null) {
      return 0;
    }
    return _keys.where((element) => element.startsWith('pedido')).length;
  }

  static Future clearAllStored() async {
    await _preferences!.clear();
  }

  /// Extrae el hash único de una key tipo "[<[<[#0966f]>]>]" o "[<'#0966f'>]"
  static String extractHash(String key) {
    // Buscar el patrón #XXXXX dentro de la key
    final regex = RegExp(r'#([a-fA-F0-9]+)');
    final match = regex.firstMatch(key);
    if (match != null) {
      return match.group(0)!; // Retorna "#0966f"
    }
    return key; // Si no encuentra el patrón, retorna la key original
  }

  static Future deleteOne(String key) async {
    // Intentar eliminar con la key tal cual
    if (_preferences!.containsKey("pedidos$key")) {
      await _preferences!.remove("pedidos$key");
      return;
    }

    // Buscar por hash en todas las keys de pedidos
    final hash = extractHash(key);
    final pedidoKeys = _keys.where((k) => k.startsWith('pedido'));

    for (var pedidoKey in pedidoKeys) {
      if (pedidoKey.contains(hash)) {
        await _preferences!.remove(pedidoKey);
        return;
      }
    }
  }

  /// Elimina pedidos duplicados basándose en el hash único
  static Future<int> removeDuplicates() async {
    if (_preferences == null) return 0;

    final pedidoKeys = _keys.where((k) => k.startsWith('pedido')).toList();
    final seenHashes = <String>{};
    final keysToRemove = <String>[];

    for (var key in pedidoKeys) {
      final hash = extractHash(key);
      if (seenHashes.contains(hash)) {
        // Es un duplicado
        keysToRemove.add(key);
      } else {
        seenHashes.add(hash);
      }
    }

    // Eliminar duplicados
    for (var key in keysToRemove) {
      await _preferences!.remove(key);
    }

    return keysToRemove.length;
  }

  /// Obtiene todas las keys de pedidos (para debug)
  static List<String> getAllPedidoKeys() {
    if (_preferences == null) return [];
    return _keys.where((k) => k.startsWith('pedido')).toList();
  }
}
