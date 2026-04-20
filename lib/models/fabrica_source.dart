/// Modelo que representa una fuente de fábrica/proveedor
/// Almacena los metadatos del archivo importado y el mapeo de columnas
class FabricaSource {
  final String id;
  String nombre; // Nombre del proveedor/fábrica
  String archivoNombre; // Nombre original del archivo
  String tipoArchivo; // 'xlsx' | 'pdf'
  DateTime fechaCarga;
  DateTime? fechaActualizacion;
  int cantidadItems;

  /// Mapeo de columnas del archivo original a campos conocidos
  /// Ejemplo: {'A': 'nombre', 'B': 'precio', 'C': 'codigo'}
  Map<String, String>? columnMapping;

  /// Nombre de la hoja de Excel usada (si aplica)
  String? hojaExcel;

  /// Fila donde empiezan los datos (0-indexed, después del header)
  int filaInicio;

  FabricaSource({
    required this.id,
    required this.nombre,
    required this.archivoNombre,
    required this.tipoArchivo,
    DateTime? fechaCarga,
    this.fechaActualizacion,
    this.cantidadItems = 0,
    this.columnMapping,
    this.hojaExcel,
    this.filaInicio = 1,
  }) : fechaCarga = fechaCarga ?? DateTime.now();

  factory FabricaSource.fromJson(Map<String, dynamic> json) {
    return FabricaSource(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      archivoNombre: json['archivoNombre'] ?? '',
      tipoArchivo: json['tipoArchivo'] ?? 'xlsx',
      fechaCarga: json['fechaCarga'] != null
          ? DateTime.tryParse(json['fechaCarga']) ?? DateTime.now()
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.tryParse(json['fechaActualizacion'])
          : null,
      cantidadItems: json['cantidadItems'] ?? 0,
      columnMapping: json['columnMapping'] != null
          ? Map<String, String>.from(json['columnMapping'])
          : null,
      hojaExcel: json['hojaExcel'],
      filaInicio: json['filaInicio'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'archivoNombre': archivoNombre,
      'tipoArchivo': tipoArchivo,
      'fechaCarga': fechaCarga.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'cantidadItems': cantidadItems,
      'columnMapping': columnMapping,
      'hojaExcel': hojaExcel,
      'filaInicio': filaInicio,
    };
  }

  FabricaSource copyWith({
    String? id,
    String? nombre,
    String? archivoNombre,
    String? tipoArchivo,
    DateTime? fechaCarga,
    DateTime? fechaActualizacion,
    int? cantidadItems,
    Map<String, String>? columnMapping,
    String? hojaExcel,
    int? filaInicio,
  }) {
    return FabricaSource(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      archivoNombre: archivoNombre ?? this.archivoNombre,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      cantidadItems: cantidadItems ?? this.cantidadItems,
      columnMapping: columnMapping ?? this.columnMapping,
      hojaExcel: hojaExcel ?? this.hojaExcel,
      filaInicio: filaInicio ?? this.filaInicio,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FabricaSource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FabricaSource{id: $id, nombre: $nombre, items: $cantidadItems}';
}

/// Campos conocidos que el usuario puede mapear desde las columnas del archivo
class FabricaFieldMapping {
  static const String nombre = 'nombre';
  static const String codigo = 'codigo';
  static const String precio = 'precio';
  static const String descripcion = 'descripcion';
  static const String unidad = 'unidad';
  static const String categoria = 'categoria';

  static const List<String> allFields = [
    nombre,
    codigo,
    precio,
    descripcion,
    unidad,
    categoria,
  ];

  static const Map<String, String> fieldLabels = {
    nombre: 'Nombre',
    codigo: 'Código / SKU',
    precio: 'Precio',
    descripcion: 'Descripción',
    unidad: 'Unidad',
    categoria: 'Categoría',
  };

  /// Palabras clave para auto-detección de columnas
  static const Map<String, List<String>> autoDetectKeywords = {
    nombre: ['nombre', 'name', 'producto', 'articulo', 'artículo', 'descripcion', 'item', 'detalle'],
    codigo: ['codigo', 'código', 'cod', 'sku', 'ref', 'referencia', 'art', 'nro'],
    precio: ['precio', 'price', 'valor', 'costo', 'importe', 'monto', '\$', 'lista', 'p.unit', 'unitario'],
    descripcion: ['descripcion', 'descripción', 'desc', 'detalle', 'observacion', 'obs'],
    unidad: ['unidad', 'unit', 'und', 'u.m', 'medida', 'um'],
    categoria: ['categoria', 'categoría', 'cat', 'rubro', 'familia', 'tipo', 'linea', 'línea', 'grupo'],
  };
}
