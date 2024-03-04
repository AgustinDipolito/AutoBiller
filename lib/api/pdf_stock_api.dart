import 'dart:io';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/services/stock_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

class PdfStockApi {
  static Future<File> generate(List<Stock> stock) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      build: (context) => [
        _buildTittle(),
        Divider(),
        _buildContent(stock),
        Divider(),
        Divider(),
      ],
      footer: (context) => _buildFooter(),
    ));

    return PdfApi.saveDocument(
      name: 'Stock del ${DateTime.now()}.pdf',
      pdf: pdf,
    );
  }

  static Widget _buildContent(List<Stock> stock) {
    final headers = ['CANT', 'NOMBRE', 'ID'];

    stock.sort(((a, b) => a.name.compareTo(b.name)));

    final data = stock.map((item) {
      return [
        item.cant,
        item.name,
        item.id,
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      cellDecoration: (_, __, ___) => const BoxDecoration(
          border: Border(bottom: BorderSide(width: .5, color: PdfColors.grey300))),
      cellHeight: 25,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerRight,
      },
    );
  }

  static Widget _buildTittle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STOCK ACTUAL',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          Text('Validez 45 segundos.'),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget _buildFooter() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          _buildSimpleText(title: 'Dirección', value: "Eva Peron 417, Temperley."),
          SizedBox(height: 1 * PdfPageFormat.mm),
          _buildSimpleText(title: 'Contacto', value: "+54 9 11 66338293"),
        ],
      );

  static _buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value),
      ],
    );
  }
}
