import 'dart:io';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/models/invoice.dart';
import 'package:dist_v2/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class PdfInvoiceApi {
  static Future<File> generate(Invoice invoice) async {
    final pdf = Document();

    pdf.addPage(
      MultiPage(
        margin: const EdgeInsets.all(.5 * PdfPageFormat.cm),
        build: (context) => [
          buildHeader(invoice),
          SizedBox(height: PdfPageFormat.cm),
          buildInvoice(invoice),
          Divider(),
          buildTotal(invoice),
        ],
        footer: (context) => buildFooter(invoice),
      ),
    );

    return FileApi.saveDocument(
      name: 'FACTURA ${invoice.customer.name} - ${invoice.info.number}.pdf',
      pdf: pdf,
    );
  }

  static Widget buildHeader(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * PdfPageFormat.cm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: buildSupplierAddress(invoice),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    height: 75,
                    width: 75,
                    data: invoice.info.number,
                  ),
                  SizedBox(height: 0.5 * PdfPageFormat.cm),
                  buildInvoiceInfo(invoice.info),
                ],
              ),
            ],
          ),
        ],
      );

  static Widget buildInvoiceInfo(InvoiceInfo info) {
    final titles = <String>[
      'Fecha facturación:',
      'Validez:',
      'Cant. items:',
    ];
    final data = <String>[
      info.date.toString().substring(0, 10).split('-').reversed.join('/'),
      '3 dias',
      info.number,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(titles.length, (index) {
        final title = titles[index];
        final value = data[index];

        return buildText(title: title, value: value, width: 200);
      }),
    );
  }

  static Widget buildSupplierAddress(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(invoice.supplier.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text("Accesorios de carpinteria de aluminio."),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          Text(
            invoice.customer.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          Text(invoice.info.description),
        ],
      );

  static Widget buildInvoice(Invoice invoice) {
    final headers = ['Cant.', 'Descripción', 'Valor unitario', 'Total'];
    final data = invoice.items.map((item) {
      final total = item.unitPrice * item.quantity;

      return [
        item.quantity.toString(),
        item.description,
        Utils.formatPrice(item.unitPrice),
        Utils.formatPrice(total),
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignments: {
        0: Alignment.center,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.centerRight,
      },
    );
  }

  static Widget buildTotal(Invoice invoice) {
    final netTotal = invoice.items
        .map((item) => item.unitPrice * item.quantity)
        .reduce((item1, item2) => item1 + item2);

    // Calcular descuento
    final discountAmount = invoice.discountPercentage != null
        ? netTotal * (invoice.discountPercentage! / 100)
        : 0.0;

    // Aplicar descuento
    final afterDiscount = netTotal - discountAmount;

    // Aplicar saldo (positivo = se suma, negativo = se resta)
    final total = afterDiscount + (invoice.balance ?? 0.0);

    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildText(
                  title: total == netTotal ? 'Total:' : 'Monto:',
                  titleStyle: total != netTotal
                      ? TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )
                      : TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .7,
                        ),
                  value: Utils.formatPrice(netTotal),
                  unite: true,
                ),
                if (invoice.discountPercentage != null &&
                    invoice.discountPercentage! > 0) ...[
                  SizedBox(height: 1 * PdfPageFormat.mm),
                  buildText(
                    title: '- Promo ${invoice.discountPercentage!.toStringAsFixed(0)}%:',
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    value: Utils.formatPrice(discountAmount),
                    unite: true,
                  ),
                ],
                if (invoice.balance != null && invoice.balance! != 0) ...[
                  SizedBox(height: 1 * PdfPageFormat.mm),
                  buildText(
                    title: '${invoice.balance! > 0 ? '+' : '-'} Saldo Ant:',
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    value: Utils.formatPrice(invoice.balance!.abs()),
                    unite: true,
                  ),
                ],
                // SizedBox(height: 2 * PdfPageFormat.mm),
                // Container(height: 1, color: PdfColors.grey400),
                // SizedBox(height: 0.5 * PdfPageFormat.mm),
                // Container(height: 1, color: PdfColors.grey400),
                // SizedBox(height: 1 * PdfPageFormat.mm),
                if ((invoice.balance != null && invoice.balance! != 0) ||
                    (invoice.discountPercentage != null &&
                        invoice.discountPercentage! > 0)) ...[
                  SizedBox(height: 1 * PdfPageFormat.mm),
                  Container(height: 0.5, color: PdfColors.grey400),
                  SizedBox(height: 1 * PdfPageFormat.mm),
                  buildText(
                    title: 'TOTAL:',
                    titleStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .7,
                    ),
                    value: Utils.formatPrice(total),
                    unite: true,
                  ),
                  SizedBox(height: 1 * PdfPageFormat.mm),
                  Container(height: 0.5, color: PdfColors.grey400),
                  SizedBox(height: 0.5 * PdfPageFormat.mm),
                  Container(height: 0.8, color: PdfColors.grey400),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(title: 'Dirección', value: invoice.supplier.address),
          SizedBox(height: 1 * PdfPageFormat.mm),
          buildSimpleText(title: 'Contacto', value: invoice.supplier.paymentInfo),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value, style: style),
      ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }
}
