import 'stock.dart' show StockType, Proveedor, GroupType;

/// Modelo extendido de producto para gestión de catálogo
/// Preparado para migración a Firebase
class Producto {
  final String id;
  String nombre;
  int precio;
  String tipo;
  Proveedor? marca;
  String? marcaCustom;
  String? codigoStock;
  StockType? familia;
  String? familiaCustom;
  GroupType? grupo;
  String? grupoCustom;
  String? descripcion;
  String? imagenUrl;
  bool activo = true;
  bool esOferta = false;
  DateTime? fechaCreacion;
  DateTime? fechaModificacion;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.tipo,
    this.marca,
    this.marcaCustom,
    this.codigoStock,
    this.familia,
    this.familiaCustom,
    this.grupo,
    this.grupoCustom,
    this.descripcion,
    this.imagenUrl,
    this.activo = true,
    this.esOferta = false,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaModificacion = fechaModificacion ?? DateTime.now();

  /// Constructor desde JSON (compatible con formato actual de catalogo.json)
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      precio: int.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      tipo: json['tipo'],
      marca: json['marca'] != null
          ? (json['marca'] is int
              ? Proveedor.values[json['marca']]
              : Proveedor.values.firstWhere((e) => e.name == json['marca'],
                  orElse: () => Proveedor.otro))
          : null,
      marcaCustom: json['marcaCustom'],
      codigoStock: json['codigoStock'],
      familia: json['familia'] != null
          ? (json['familia'] is int
              ? StockType.values[json['familia']]
              : StockType.values.firstWhere((e) => e.name == json['familia'],
                  orElse: () => StockType.otro))
          : null,
      familiaCustom: json['familiaCustom'],
      grupo: json['grupo'] != null
          ? (json['grupo'] is int
              ? GroupType.values[json['grupo']]
              : GroupType.values.firstWhere((e) => e.toString() == json['grupo'],
                  orElse: () => GroupType.Otros))
          : null,
      grupoCustom: json['grupoCustom'],
      descripcion: json['descripcion'],
      imagenUrl: json['imagenUrl'],
      activo: json['activo'] == null
          ? true
          : (json['activo'] == 'true' || json['activo'] == true),
      esOferta: json['esOferta'] == null
          ? false
          : (json['esOferta'] == 'true' || json['esOferta'] == true),
      fechaCreacion:
          json['fechaCreacion'] != null ? DateTime.tryParse(json['fechaCreacion']) : null,
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.tryParse(json['fechaModificacion'])
          : null,
    );
  }

  /// Convertir a JSON (compatible con Firebase y archivo local)
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'nombre': nombre,
      'precio': precio.toString(),
      'tipo': tipo.toString(),
      'marca': marca?.name,
      'marcaCustom': marcaCustom,
      'codigoStock': codigoStock,
      'familia': familia?.name,
      'familiaCustom': familiaCustom,
      'grupo': grupo?.toString(),
      'grupoCustom': grupoCustom,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'activo': activo,
      'esOferta': esOferta,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crear copia con modificaciones
  Producto copyWith({
    String? id,
    String? nombre,
    int? precio,
    String? tipo,
    Proveedor? marca,
    String? marcaCustom,
    String? codigoStock,
    StockType? familia,
    String? familiaCustom,
    GroupType? grupo,
    String? grupoCustom,
    String? descripcion,
    String? imagenUrl,
    bool? activo,
    bool? esOferta,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      tipo: tipo ?? this.tipo,
      marca: marca ?? this.marca,
      marcaCustom: marcaCustom ?? this.marcaCustom,
      codigoStock: codigoStock ?? this.codigoStock,
      familia: familia ?? this.familia,
      familiaCustom: familiaCustom ?? this.familiaCustom,
      grupo: grupo ?? this.grupo,
      grupoCustom: grupoCustom ?? this.grupoCustom,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      activo: activo ?? this.activo,
      esOferta: esOferta ?? this.esOferta,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }

  @override
  String toString() {
    return 'Producto{id: $id, nombre: $nombre, precio: $precio}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para historial de cambios
class CambioHistorial {
  final String id;
  final String productoId;
  final String nombreProducto;
  final String campo;
  final String? valorAnterior;
  final String? valorNuevo;
  final DateTime fecha;
  final String? usuario;

  CambioHistorial({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.campo,
    this.valorAnterior,
    this.valorNuevo,
    DateTime? fecha,
    this.usuario,
  }) : fecha = fecha ?? DateTime.now();

  factory CambioHistorial.fromJson(Map<String, dynamic> json) {
    return CambioHistorial(
      id: json['id'] ?? '',
      productoId: json['productoId'] ?? '',
      nombreProducto: json['nombreProducto'] ?? '',
      campo: json['campo'] ?? '',
      valorAnterior: json['valorAnterior'],
      valorNuevo: json['valorNuevo'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      usuario: json['usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productoId': productoId,
      'nombreProducto': nombreProducto,
      'campo': campo,
      'valorAnterior': valorAnterior,
      'valorNuevo': valorNuevo,
      'fecha': fecha.toIso8601String(),
      'usuario': usuario,
    };
  }
}
