import 'dart:io';
import 'package:dist_v2/models/producto.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ExcelCatalogoApi {
  /// Genera un archivo Excel con todos los campos del catálogo
  /// Incluye todos los productos (activos e inactivos)
  static Future<File?> generate(List<Producto> productos) async {
    try {
      // Crear un nuevo Excel
      final excel = Excel.createExcel();

      // Obtener la hoja por defecto y renombrarla
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      // Crear hoja "Catálogo"
      const sheetName = 'Catálogo';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      // Definir estilos
      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FF9800'), // Naranja
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'), // Blanco
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final ofertaStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'), // Naranja claro
        fontColorHex: ExcelColor.fromHexString('#E65100'), // Naranja oscuro
        bold: true,
      );

      final inactivoStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'), // Rojo claro
        fontColorHex: ExcelColor.fromHexString('#C62828'), // Rojo oscuro
      );

      // Encabezados
      final headers = [
        'ID',
        'Nombre',
        'Precio',
        'Tipo',
        'Marca',
        'Código Stock',
        'Familia',
        'Descripción',
        'Activo',
        'Es Oferta',
        'Fecha Creación',
        'Fecha Modificación',
      ];

      // Agregar encabezados con estilo
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Ordenar productos por ID
      productos.sort((a, b) => a.id.compareTo(b.id));

      // Agregar datos
      for (var i = 0; i < productos.length; i++) {
        final producto = productos[i];
        final rowIndex = i + 1;

        // Determinar estilo de fila
        CellStyle? rowStyle;
        if (producto.esOferta) {
          rowStyle = ofertaStyle;
        } else if (!producto.activo) {
          rowStyle = inactivoStyle;
        }

        final rowData = [
          producto.id,
          producto.nombre,
          producto.precio.toString(),
          producto.tipo,
          producto.marca ?? '',
          producto.codigoStock ?? '',
          producto.familia ?? '',
          producto.descripcion ?? '',
          producto.activo ? 'Sí' : 'No',
          producto.esOferta ? 'Sí' : 'No',
          producto.fechaCreacion != null
              ? producto.fechaCreacion!.toString().substring(0, 19).replaceAll('T', ' ')
              : '',
          producto.fechaModificacion != null
              ? producto.fechaModificacion!
                  .toString()
                  .substring(0, 19)
                  .replaceAll('T', ' ')
              : '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j].toString());
          if (rowStyle != null) {
            cell.cellStyle = rowStyle;
          }
        }
      }

      // Guardar archivo
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      final fileName = 'Catalogo_${DateTime.now().toString().substring(0, 10)}.xlsx';

      if (kIsWeb) {
        // En Web: descargar automáticamente
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        // Retornar File dummy para compatibilidad
        return File(fileName);
      } else {
        // En dispositivos: guardar en directorio de documentos
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      return null;
    }
  }

  /// Genera estadísticas del catálogo en una segunda hoja
  static Future<File?> generateConEstadisticas(List<Producto> productos) async {
    try {
      // Crear un nuevo Excel
      final excel = Excel.createExcel();

      // Obtener la hoja por defecto
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      // ===== HOJA 1: CATÁLOGO =====
      final sheetCatalogo = excel['Catálogo'];

      // Estilos
      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final ofertaStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
        fontColorHex: ExcelColor.fromHexString('#E65100'),
        bold: true,
      );

      final inactivoStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'),
        fontColorHex: ExcelColor.fromHexString('#C62828'),
      );

      // Encabezados
      final headers = [
        'ID',
        'Nombre',
        'Precio',
        'Tipo',
        'Marca',
        'Código Stock',
        'Familia',
        'Descripción',
        'Activo',
        'Es Oferta',
        'Fecha Creación',
        'Fecha Modificación',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell =
            sheetCatalogo.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Datos
      productos.sort((a, b) => a.id.compareTo(b.id));

      for (var i = 0; i < productos.length; i++) {
        final producto = productos[i];
        final rowIndex = i + 1;

        CellStyle? rowStyle;
        if (producto.esOferta) {
          rowStyle = ofertaStyle;
        } else if (!producto.activo) {
          rowStyle = inactivoStyle;
        }

        final rowData = [
          producto.id,
          producto.nombre,
          producto.precio.toString(),
          producto.tipo,
          producto.marca ?? '',
          producto.codigoStock ?? '',
          producto.familia ?? '',
          producto.descripcion ?? '',
          producto.activo ? 'Sí' : 'No',
          producto.esOferta ? 'Sí' : 'No',
          producto.fechaCreacion?.toString().substring(0, 19).replaceAll('T', ' ') ?? '',
          producto.fechaModificacion?.toString().substring(0, 19).replaceAll('T', ' ') ??
              '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          final cell = sheetCatalogo
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(rowData[j].toString());
          if (rowStyle != null) {
            cell.cellStyle = rowStyle;
          }
        }
      }

      // ===== HOJA 2: ESTADÍSTICAS =====
      final sheetStats = excel['Estadísticas'];

      // Calcular estadísticas
      final totalProductos = productos.length;
      final productosActivos = productos.where((p) => p.activo).length;
      final productosInactivos = productos.where((p) => !p.activo).length;
      final productosEnOferta = productos.where((p) => p.esOferta).length;

      final precioPromedio = productos.isEmpty
          ? 0
          : productos.map((p) => p.precio).reduce((a, b) => a + b) / productos.length;

      final precioMinimo = productos.isEmpty
          ? 0
          : productos.map((p) => p.precio).reduce((a, b) => a < b ? a : b);

      final precioMaximo = productos.isEmpty
          ? 0
          : productos.map((p) => p.precio).reduce((a, b) => a > b ? a : b);

      // Contar por familia
      final Map<String, int> productosPorFamilia = {};
      for (var p in productos) {
        final familia = p.familia?.name ?? 'Sin Familia';
        productosPorFamilia[familia] = (productosPorFamilia[familia] ?? 0) + 1;
      }

      // Título
      var row = 0;
      var cell =
          sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue('ESTADÍSTICAS DEL CATÁLOGO');
      cell.cellStyle = CellStyle(
        fontSize: 16,
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      row += 2;

      // Estadísticas generales
      final stats = [
        ['Total de Productos:', totalProductos.toString()],
        ['Productos Activos:', productosActivos.toString()],
        ['Productos Inactivos:', productosInactivos.toString()],
        ['Productos en Oferta:', productosEnOferta.toString()],
        ['', ''],
        ['Precio Promedio:', '\$${precioPromedio.toStringAsFixed(0)}'],
        ['Precio Mínimo:', '\$${precioMinimo.toString()}'],
        ['Precio Máximo:', '\$${precioMaximo.toString()}'],
      ];

      for (var stat in stats) {
        cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        cell.value = TextCellValue(stat[0]);
        cell.cellStyle = CellStyle(bold: true);

        cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        cell.value = TextCellValue(stat[1]);

        row++;
      }

      row += 2;

      // Productos por familia
      cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue('PRODUCTOS POR FAMILIA');
      cell.cellStyle = headerStyle;

      cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      cell.value = TextCellValue('Cantidad');
      cell.cellStyle = headerStyle;

      row++;

      final familiasOrdenadas = productosPorFamilia.keys.toList()..sort();
      for (var familia in familiasOrdenadas) {
        cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        cell.value = TextCellValue(familia);

        cell = sheetStats.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        cell.value = TextCellValue(productosPorFamilia[familia].toString());

        row++;
      }

      // Guardar archivo
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      final fileName =
          'Catalogo_Completo_${DateTime.now().toString().substring(0, 10)}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return File(fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      return null;
    }
  }
}
