/// Modelo para un item parseado de un archivo de fábrica
/// Almacena los datos mapeados y los datos originales sin procesar
class FabricaItem {
  final String id;
  final String fabricaSourceId; // FK a FabricaSource

  // Campos mapeados
  String nombre;
  String? codigo;
  double? precio;
  String? descripcion;
  String? unidad;
  String? categoria;

  /// Datos originales del archivo (todas las columnas como clave-valor)
  Map<String, String> rawData;

  /// Si ya fue agregado al catálogo del usuario
  bool agregadoACatalogo;

  /// ID del producto en el catálogo del usuario (si fue agregado)
  String? catalogoProductoId;

  /// Relaciones manuales con items de otras fábricas (por ID)
  List<String> relacionesIds;

  FabricaItem({
    required this.id,
    required this.fabricaSourceId,
    required this.nombre,
    this.codigo,
    this.precio,
    this.descripcion,
    this.unidad,
    this.categoria,
    Map<String, String>? rawData,
    this.agregadoACatalogo = false,
    this.catalogoProductoId,
    List<String>? relacionesIds,
  })  : rawData = rawData ?? {},
        relacionesIds = relacionesIds ?? [];

  factory FabricaItem.fromJson(Map<String, dynamic> json) {
    return FabricaItem(
      id: json['id'] ?? '',
      fabricaSourceId: json['fabricaSourceId'] ?? '',
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'],
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString())
          : null,
      descripcion: json['descripcion'],
      unidad: json['unidad'],
      categoria: json['categoria'],
      rawData: json['rawData'] != null
          ? Map<String, String>.from(json['rawData'])
          : {},
      agregadoACatalogo: json['agregadoACatalogo'] ?? false,
      catalogoProductoId: json['catalogoProductoId'],
      relacionesIds: json['relacionesIds'] != null
          ? List<String>.from(json['relacionesIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fabricaSourceId': fabricaSourceId,
      'nombre': nombre,
      'codigo': codigo,
      'precio': precio,
      'descripcion': descripcion,
      'unidad': unidad,
      'categoria': categoria,
      'rawData': rawData,
      'agregadoACatalogo': agregadoACatalogo,
      'catalogoProductoId': catalogoProductoId,
      'relacionesIds': relacionesIds,
    };
  }

  FabricaItem copyWith({
    String? id,
    String? fabricaSourceId,
    String? nombre,
    String? codigo,
    double? precio,
    String? descripcion,
    String? unidad,
    String? categoria,
    Map<String, String>? rawData,
    bool? agregadoACatalogo,
    String? catalogoProductoId,
    List<String>? relacionesIds,
  }) {
    return FabricaItem(
      id: id ?? this.id,
      fabricaSourceId: fabricaSourceId ?? this.fabricaSourceId,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
      unidad: unidad ?? this.unidad,
      categoria: categoria ?? this.categoria,
      rawData: rawData ?? this.rawData,
      agregadoACatalogo: agregadoACatalogo ?? this.agregadoACatalogo,
      catalogoProductoId: catalogoProductoId ?? this.catalogoProductoId,
      relacionesIds: relacionesIds ?? this.relacionesIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FabricaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FabricaItem{id: $id, nombre: $nombre, precio: $precio, fabrica: $fabricaSourceId}';
}
