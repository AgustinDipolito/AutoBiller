import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:dist_v2/helpers/manejo_archivos.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportUtils {
  /// Exporta datos a un archivo PDF
  static Future<void> exportToPdf({
    required List<String> headers,
    required List<List<dynamic>> data,
    required String fileName,
    String title = 'Reporte',
  }) async {
    // Filtrar columna "Acciones"
    final filteredHeaders = <String>[];
    final columnIndicesToKeep = <int>[];

    for (var i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase() != 'acciones') {
        filteredHeaders.add(headers[i]);
        columnIndicesToKeep.add(i);
      }
    }

    final filteredData = data.map((row) {
      return columnIndicesToKeep.map((index) => row[index]).toList();
    }).toList();

    // Validar que hay datos
    if (filteredHeaders.isEmpty || filteredData.isEmpty) {
      throw Exception('No hay datos para exportar');
    }

    final pdf = pw.Document();

    // Colores del tema FinnApp
    final primaryColor = PdfColor.fromInt(0xFF274336);
    final secondaryColor = PdfColor.fromInt(0xFF287952);
    final lightGrey = PdfColor.fromInt(0xFFF9FAF9);
    final darkGrey = PdfColor.fromInt(0xFF5E6E66);

    // Calcular ancho de columna basado en cantidad de columnas
    // Ancho mínimo de 2.5cm, máximo de 5cm por columna
    const minColumnWidth = PdfPageFormat.cm * 2.5;
    const maxColumnWidth = PdfPageFormat.cm * 5;
    final numColumns = filteredHeaders.length;
    final columnWidth = (numColumns <= 4)
        ? maxColumnWidth
        : (numColumns <= 6)
            ? PdfPageFormat.cm * 3.5
            : minColumnWidth;

    // Altura de fila
    const rowHeight = PdfPageFormat.cm * .8;

    // Calcular formato de página personalizado
    final calculatedPageWidth =
        numColumns * columnWidth + (PdfPageFormat.cm * 2); // Márgenes
    final pageWidth = calculatedPageWidth > PdfPageFormat.a4.landscape.width
        ? calculatedPageWidth
        : PdfPageFormat.a4.landscape.width;
    final pageHeight = PdfPageFormat.a4.height; // Mantener altura estándar

    // Asegurar que el ancho y alto sean válidos (mayor a 0)
    final validPageWidth = pageWidth > 0 ? pageWidth : PdfPageFormat.a4.landscape.width;
    final validPageHeight = pageHeight > 0 ? pageHeight : PdfPageFormat.a4.height;

    final customPageFormat = PdfPageFormat(
      validPageWidth,
      validPageHeight,
      marginAll: PdfPageFormat.cm * 1,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: customPageFormat,
        maxPages: 5000,
        header: (context) => _buildHeader(
          title: title,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          darkGrey: darkGrey,
        ),
        footer: (context) => _buildFooter(
          context: context,
          darkGrey: darkGrey,
          secondaryColor: secondaryColor,
        ),
        build: (context) => [
          _buildTable(
            headers: filteredHeaders,
            data: filteredData,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            lightGrey: lightGrey,
            columnWidth: columnWidth,
            rowHeight: rowHeight,
          ),
        ],
      ),
    );

    final savedFile = await pdf.save();
    await FilesManager.downloadFile(
      '$fileName.pdf',
      Uint8List.fromList(savedFile),
    );
  }

  static pw.Widget _buildHeader({
    required String title,
    required PdfColor primaryColor,
    required PdfColor secondaryColor,
    required PdfColor darkGrey,
  }) {
    return pw.Column(
      children: [
        // Logo y título
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: primaryColor, width: 2),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'FinnApp',
                  style: pw.TextStyle(
                    color: secondaryColor,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              pw.Text(
                DateTime.now().toString().split(' ')[0],
                style: pw.TextStyle(color: darkGrey, fontSize: 11),
              ),
            ],
          ),
        ),
        // Título del reporte
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: primaryColor,
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required PdfColor darkGrey,
    required PdfColor secondaryColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: secondaryColor, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FinnApp - Plataforma de Gestión',
            style: pw.TextStyle(color: darkGrey, fontSize: 9),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(color: darkGrey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<dynamic>> data,
    required PdfColor primaryColor,
    required PdfColor secondaryColor,
    required PdfColor lightGrey,
    required double columnWidth,
    required double rowHeight,
  }) {
    return pw.Table(
      defaultColumnWidth: pw.FixedColumnWidth(columnWidth),
      children: [
        // Fila de encabezados
        pw.TableRow(
          decoration: pw.BoxDecoration(color: secondaryColor),
          children: [
            for (var header in headers)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  header,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
          ],
        ),
        // Filas de datos
        for (var i = 0; i < data.length; i++)
          pw.TableRow(
            decoration: i.isEven ? pw.BoxDecoration(color: lightGrey) : null,
            children: [
              for (var cell in data[i])
                pw.Container(
                  constraints: pw.BoxConstraints(
                    minHeight: rowHeight,
                    maxHeight: rowHeight * 2,
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    cell?.toString() ?? '',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: pw.Font.times(),
                    ),
                    maxLines: 4,
                    overflow: pw.TextOverflow.clip,
                    textAlign: cell.toString().length < 4
                        ? pw.TextAlign.center
                        : pw.TextAlign.left,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Exporta datos a un archivo Excel compatible (.xls XML Spreadsheet 2003)
  static Future<void> exportToExcel({
    required List<String> headers,
    required List<List<dynamic>> data,
    required String fileName,
    String sheetName = 'Datos',
  }) async {
    // Filtrar columna "Acciones"
    final filteredHeaders = <String>[];
    final columnIndicesToKeep = <int>[];

    for (var i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase() != 'acciones') {
        filteredHeaders.add(headers[i]);
        columnIndicesToKeep.add(i);
      }
    }

    final filteredData = data.map((row) {
      return columnIndicesToKeep.map((index) => row[index]).toList();
    }).toList();

    if (filteredHeaders.isEmpty) {
      throw Exception('No hay columnas para exportar');
    }

    final safeSheetName = sheetName.isEmpty ? 'Datos' : sheetName;

    String escapeXml(String value) {
      return value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
    }

    String cellType(dynamic value) {
      return value is num ? 'Number' : 'String';
    }

    String cellValue(dynamic value) {
      if (value == null) return '';
      return value is num ? value.toString() : escapeXml(value.toString());
    }

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(' <Worksheet ss:Name="${escapeXml(safeSheetName)}">')
      ..writeln('  <Table>');

    buffer.writeln('   <Row>');
    for (final header in filteredHeaders) {
      buffer
          .writeln('    <Cell><Data ss:Type="String">${escapeXml(header)}</Data></Cell>');
    }
    buffer.writeln('   </Row>');

    for (final row in filteredData) {
      buffer.writeln('   <Row>');
      for (final value in row) {
        buffer.writeln(
            '    <Cell><Data ss:Type="${cellType(value)}">${cellValue(value)}</Data></Cell>');
      }
      buffer.writeln('   </Row>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    await FilesManager.downloadFile(
      '$fileName.xls',
      Uint8List.fromList(utf8.encode(buffer.toString())),
    );
  }

  /// Exporta datos a un archivo CSV
  static Future<void> exportToCsv({
    required List<String> headers,
    required List<List<dynamic>> data,
    required String fileName,
  }) async {
    // Filtrar columna "Acciones"
    final filteredHeaders = <String>[];
    final columnIndicesToKeep = <int>[];

    for (var i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase() != 'acciones') {
        filteredHeaders.add(headers[i]);
        columnIndicesToKeep.add(i);
      }
    }

    final filteredData = data.map((row) {
      return columnIndicesToKeep.map((index) => row[index]).toList();
    }).toList();

    final List<List<dynamic>> rows = [filteredHeaders, ...filteredData];
    final String csvData = const ListToCsvConverter().convert(rows);
    await FilesManager.downloadFile(
      '$fileName.csv',
      Uint8List.fromList(utf8.encode(csvData)),
    );
  }
}
