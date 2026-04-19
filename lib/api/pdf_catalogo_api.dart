import 'dart:io';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/models/producto.dart';
import 'package:dist_v2/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class PdfCatalogoApi {
  /// Genera un PDF del catálogo de productos agrupado por grupo
  /// Solo incluye productos activos
  /// Muestra: nombre, tipo y precio
  static Future<File> generate(List<Producto> productos) async {
    final pdf = Document();

    // Filtrar solo productos activos
    final productosActivos = productos.where((p) => p.activo).toList();

    // Filtrar ofertas
    final ofertas = productosActivos.where((p) => p.esOferta).toList();
    ofertas.sort((a, b) => a.nombre.compareTo(b.nombre));

    // Agrupar por grupo
    final Map<String, List<Producto>> productosPorGrupo = {};
    for (var producto in productosActivos) {
      final grupo = producto.grupo?.toString() ?? 'Sin Grupo';
      if (!productosPorGrupo.containsKey(grupo)) {
        productosPorGrupo[grupo] = [];
      }
      productosPorGrupo[grupo]!.add(producto);
    }

    // Ordenar grupos alfabéticamente
    final gruposOrdenados = productosPorGrupo.keys.toList()..sort();

    // Primera página: Portada + Ofertas
    pdf.addPage(
      MultiPage(
        margin: const EdgeInsets.all(1 * PdfPageFormat.cm),
        build: (context) => [
          buildPortadaCompacta(),
          if (ofertas.isNotEmpty) ...[
            SizedBox(height: 1.5 * PdfPageFormat.cm),
            buildSeccionOfertas(ofertas),
          ],
        ],
        footer: (context) => buildFooter(),
      ),
    );

    // Páginas con el catálogo de productos agrupados por grupo
    pdf.addPage(
      MultiPage(
        margin: const EdgeInsets.all(1 * PdfPageFormat.cm),
        header: (context) => buildPageHeader(),
        build: (context) => [
          for (var grupo in gruposOrdenados) ...[
            buildGroupHeader(grupo),
            buildProductosTable(productosPorGrupo[grupo]!),
            SizedBox(height: 0.5 * PdfPageFormat.cm),
          ]
        ],
        footer: (context) => buildFooter(),
      ),
    );

    return FileApi.saveDocument(
      name: 'Catalogo_${DateTime.now().toString().substring(0, 10)}.pdf',
      pdf: pdf,
    );
  }

  /// Construye la portada compacta con información del negocio
  static Widget buildPortadaCompacta() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: PdfColors.orange800, width: 3),
        borderRadius: BorderRadius.circular(10),
        color: PdfColors.orange50,
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            'DISTRIBUIDORA ALUSOL',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          SizedBox(height: 0.3 * PdfPageFormat.cm),
          Text(
            'Catálogo de Productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: PdfColors.orange800,
            ),
          ),
          SizedBox(height: 0.5 * PdfPageFormat.cm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Dirección:', 'Eva Peron 417, Temperley'),
                  SizedBox(height: 0.2 * PdfPageFormat.cm),
                  _buildInfoRow('Teléfono:', '+54 9 11 66338293'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Envios a todo el pais', ''),
                  SizedBox(height: 0.2 * PdfPageFormat.cm),
                  _buildInfoRow(
                    'Fecha:',
                    DateTime.now()
                        .toString()
                        .substring(0, 10)
                        .split('-')
                        .reversed
                        .join('/'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la sección de ofertas
  static Widget buildSeccionOfertas(List<Producto> ofertas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          decoration: const BoxDecoration(
            color: PdfColors.orange700,
          ),
          child: Text(
            'OFERTAS ESPECIALES VIGENTES',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        SizedBox(height: 0.1 * PdfPageFormat.cm),
        buildProductosTable(ofertas, esOferta: true),
      ],
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(width: 1 * PdfPageFormat.cm),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  /// Construye el encabezado de cada página (Genérico)
  static Widget buildPageHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: PdfColors.orange700, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CATÁLOGO DE PRODUCTOS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          Text(
            'DISTRIBUIDORA ALUSOL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el encabezado de sección de grupo
  static Widget buildGroupHeader(String grupo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      decoration: BoxDecoration(
        color: PdfColors.orange100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        grupo.toUpperCase(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: PdfColors.orange900,
        ),
      ),
    );
  }

  /// Construye la tabla de productos con imágenes
  static Widget buildProductosTable(List<Producto> productos, {bool esOferta = false}) {
    return Column(
      children: [
        // Header row
        Container(
          color: esOferta ? PdfColors.deepOrange700 : PdfColors.orange700,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  'Imagen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Presentación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    'Precio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Product rows
        for (var i = 0; i < productos.length; i++)
          Container(
            decoration: BoxDecoration(
              color: i.isOdd ? (esOferta ? PdfColors.orange50 : PdfColors.grey100) : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image cell - Note: Network images in PDFs require pre-download
                // For now, showing placeholder. Future enhancement: download images before PDF generation
                SizedBox(
                  width: 50,
                  height: 45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: productos[i].imagenUrl != null
                          ? PdfColors.blue50
                          : PdfColors.grey200,
                      border: Border.all(color: PdfColors.grey400, width: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        productos[i].imagenUrl != null ? '📷' : '-',
                        style: TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Name cell
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      productos[i].nombre,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                // Presentation cell
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      productos[i].tipo,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                // Price cell
                SizedBox(
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      Utils.formatPrice(productos[i].precio.toDouble()),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Construye el pie de página
  static Widget buildFooter() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(top: 1 * PdfPageFormat.cm),
      child: Text(
        'Accesorios de carpinteria +54 9 11 66338293',
        style: const TextStyle(
          fontSize: 10,
          color: PdfColors.orange800,
        ),
      ),
    );
  }
}
