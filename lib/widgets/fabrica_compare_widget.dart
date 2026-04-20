import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fabrica_item.dart';
import '../models/producto.dart';
import '../services/fabrica_service.dart';
import '../utils.dart';

/// Widget que muestra comparación de precios de un producto a través de múltiples fábricas
class FabricaCompareWidget extends StatefulWidget {
  final String nombreProducto;
  final VoidCallback? onClose;
  final Function(FabricaItem item, double markup, double descuento)? onAgregarACatalogo;

  const FabricaCompareWidget({
    super.key,
    required this.nombreProducto,
    this.onClose,
    this.onAgregarACatalogo,
  });

  @override
  State<FabricaCompareWidget> createState() => _FabricaCompareWidgetState();
}

class _FabricaCompareWidgetState extends State<FabricaCompareWidget> {
  final _fabricaService = FabricaService();
  final _formatCurrency =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
  final _markupController = TextEditingController(text: '30');
  final Map<String, TextEditingController> _discountControllers = {};
  final _searchController = TextEditingController();

  List<FabricaItem> _similares = [];
  List<Producto> _productosEnCatalogo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.nombreProducto;
    _cargarComparacion();
  }

  @override
  void didUpdateWidget(covariant FabricaCompareWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreProducto != widget.nombreProducto) {
      _searchController.text = widget.nombreProducto;
      _cargarComparacion();
    }
  }

  Future<void> _cargarComparacion() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _similares = [];
        _productosEnCatalogo = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resultado = await _fabricaService.compararPrecios(query);
      if (mounted) {
        setState(() {
          _similares = resultado['similares'] as List<FabricaItem>;
          _productosEnCatalogo = resultado['productosEnCatalogo'] as List<Producto>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar comparación: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _markupController.dispose();
    for (var controller in _discountControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comparación de Precios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '"${widget.nombreProducto}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_similares.isEmpty && _productosEnCatalogo.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No se encontraron productos similares',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _cargarComparacion();
                },
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (_) => _cargarComparacion(),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Precio actual en catálogo
          if (_productosEnCatalogo.isNotEmpty) ...[
            for (final prod in _productosEnCatalogo) _buildCatalogoPriceCard(prod),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
          ],

          // Título
          Text(
            'Precios de Fábricas (${_similares.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Markup/Discount input
          _buildConfigInput(),
          const SizedBox(height: 12),

          // Lista de precios por fábrica
          ..._similares.map((item) => _buildFactoryPriceCard(item)),
        ],
      ),
    ),
  ),
],
    );
  }

  Widget _buildCatalogoPriceCard(Producto? prod) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Precios actuales en tu catálogo',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  prod?.nombre ?? 'Sin nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency.format(prod?.precio),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text(
            'Markup Global:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _markupController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'se aplica sobre el precio neto',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFactoryPriceCard(FabricaItem item) {
    final fabricaNombre = _fabricaService.getNombreFabrica(item.fabricaSourceId);
    final markup = double.tryParse(_markupController.text) ?? 0;
    
    // Obtener o crear controlador para el descuento individual
    if (!_discountControllers.containsKey(item.id)) {
      _discountControllers[item.id] = TextEditingController(text: '0');
    }
    final discountController = _discountControllers[item.id]!;
    final discount = double.tryParse(discountController.text) ?? 0;

    double? precioFinal;
    if (item.precio != null) {
      final precioConDescuento = item.precio! * (1 - discount / 100);
      precioFinal = precioConDescuento * (1 + markup / 100);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: item.agregadoACatalogo ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Factory name + badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    fabricaNombre,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (item.agregadoACatalogo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓ En catálogo',
                      style: TextStyle(
                          fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Product name
            Text(
              item.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (item.codigo != null) ...[
              const SizedBox(height: 2),
              Text(
                'Cód: ${item.codigo}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 8),

            // Price row
            Row(
              children: [
                // Individual discount input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Desc (%)',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Factory Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fábrica',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      item.precio != null ? _formatCurrency.format(item.precio) : '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),

                if (precioFinal != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 16),
                  // Price with markup
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'P. Final (Neto + Markup)',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        _formatCurrency.format(precioFinal.round()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],

                const Spacer(),

                // Add button
                if (!item.agregadoACatalogo && widget.onAgregarACatalogo != null)
                  ElevatedButton.icon(
                    onPressed: () => widget.onAgregarACatalogo!(item, markup, discount),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
