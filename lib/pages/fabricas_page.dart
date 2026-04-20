// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fabrica_item.dart';
import '../models/fabrica_source.dart';
import '../services/fabrica_service.dart';
import '../widgets/fabrica_compare_widget.dart';
import '../widgets/finnapp_data_table.dart';
import '../utils.dart';
import 'fabrica_import_dialog.dart';

/// Página principal de gestión de fábricas/proveedores
/// Layout de 3 paneles: Fábricas | Items | Comparación
class FabricasPage extends StatefulWidget {
  const FabricasPage({super.key});

  @override
  State<FabricasPage> createState() => _FabricasPageState();
}

class _FabricasPageState extends State<FabricasPage> {
  final _fabricaService = FabricaService();
  final _formatCurrency =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

  List<FabricaSource> _fabricas = [];
  FabricaSource? _fabricaSeleccionada;
  List<FabricaItem> _itemsFabricaActual = [];
  String? _productoComparar; // Nombre del producto para comparar
  bool _isLoading = true;

  final ValueNotifier<Set<FabricaItem>> _itemsSeleccionados = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _itemsSeleccionados.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final fabricas = await _fabricaService.getFabricas();
      setState(() {
        _fabricas = fabricas;
        _isLoading = false;
      });

      // Recargar items si hay fábrica seleccionada
      if (_fabricaSeleccionada != null) {
        await _cargarItemsFabrica(_fabricaSeleccionada!.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _cargarItemsFabrica(String fabricaId) async {
    final items = await _fabricaService.getItemsByFabrica(fabricaId);
    setState(() => _itemsFabricaActual = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Gestión de Fábricas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _importarArchivo,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Importar Archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fabricas.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.factory_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay fábricas cargadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Importe archivos Excel o PDF de sus proveedores\npara comenzar a comparar precios',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importarArchivo,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar primer archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Panel 1: Lista de fábricas
        SizedBox(
          width: 260,
          child: _buildFabricasPanel(),
        ),

        // Divider
        VerticalDivider(width: 1, color: Colors.grey.shade300),

        // Panel 2: Items de la fábrica seleccionada
        Expanded(
          flex: 3,
          child: _fabricaSeleccionada != null
              ? _buildItemsPanel()
              : _buildSelectFabricaMessage(),
        ),

        // Panel 3: Comparación (solo si hay producto seleccionado)
        if (_productoComparar != null) ...[
          VerticalDivider(width: 1, color: Colors.grey.shade300),
          SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FabricaCompareWidget(
                nombreProducto: _productoComparar!,
                onClose: () => setState(() => _productoComparar = null),
                onAgregarACatalogo: _agregarACatalogo,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== PANEL 1: FÁBRICAS ====================

  Widget _buildFabricasPanel() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.factory, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fábricas (${_fabricas.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: _fabricas.length,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, index) {
                final fabrica = _fabricas[index];
                final isSelected = _fabricaSeleccionada?.id == fabrica.id;

                return Material(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _fabricaSeleccionada = fabrica;
                        _productoComparar = null;
                      });
                      await _cargarItemsFabrica(fabrica.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color:
                                isSelected ? AppTheme.primaryColor : Colors.transparent,
                            width: 3,
                          ),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          // File type icon
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: fabrica.tipoArchivo == 'pdf'
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              fabrica.tipoArchivo == 'pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.table_chart,
                              size: 18,
                              color: fabrica.tipoArchivo == 'pdf'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fabrica.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected ? AppTheme.primaryColor : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${fabrica.cantidadItems} items • ${DateFormat('dd/MM/yy').format(fabrica.fechaCarga)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 18, color: Colors.grey.shade600),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'actualizar',
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh, size: 18),
                                    SizedBox(width: 8),
                                    Text('Actualizar archivo'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'actualizar':
                                  _actualizarFabrica(fabrica);
                                  break;
                                case 'eliminar':
                                  _confirmarEliminarFabrica(fabrica);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PANEL 2: ITEMS ====================

  Widget _buildSelectFabricaMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Seleccione una fábrica para ver sus productos',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsPanel() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${_fabricaSeleccionada!.nombre} — ${_itemsFabricaActual.length} productos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _fabricaSeleccionada!.archivoNombre,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Data table
          Expanded(
            child: FinnappDataTable<FabricaItem>(
              items: _itemsFabricaActual,
              columns: [
                DataTableColumnConfig<FabricaItem>(
                  id: 'acciones',
                  label: 'Acciones',
                  getValue: (item) => '',
                  width: 100,
                  builder: (item, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.compare_arrows, size: 18),
                        color: AppTheme.primaryColor,
                        tooltip: 'Comparar precios',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _productoComparar = item.nombre);
                        },
                      ),
                      const SizedBox(width: 4),
                      if (!item.agregadoACatalogo)
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          color: Colors.green,
                          tooltip: 'Agregar al catálogo',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _mostrarDialogAgregar(item),
                        )
                      else
                        const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    ],
                  ),
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'nombre',
                  label: 'Nombre',
                  getValue: (item) => item.nombre,
                  sortable: true,
                  width: 250,
                  builder: (item, value) => Text(
                    value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'codigo',
                  label: 'Código',
                  getValue: (item) => item.codigo ?? '-',
                  sortable: true,
                  width: 120,
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'precio',
                  label: 'Precio',
                  getValue: (item) => item.precio ?? 0,
                  sortable: true,
                  width: 120,
                  builder: (item, value) => Text(
                    item.precio != null ? _formatCurrency.format(item.precio) : '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'categoria',
                  label: 'Categoría',
                  getValue: (item) => item.categoria ?? '-',
                  sortable: true,
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'unidad',
                  label: 'Unidad',
                  getValue: (item) => item.unidad ?? '-',
                  sortable: true,
                  width: 80,
                ),
                DataTableColumnConfig<FabricaItem>(
                  id: 'estado',
                  label: 'Estado',
                  getValue: (item) => item.agregadoACatalogo ? 'Agregado' : 'Pendiente',
                  sortable: true,
                  width: 100,
                  builder: (item, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.agregadoACatalogo
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.agregadoACatalogo
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      item.agregadoACatalogo ? '✓ Agregado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            item.agregadoACatalogo ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
              searchFunction: (item, query) {
                final q = query.toLowerCase();
                return item.nombre.toLowerCase().contains(q) ||
                    (item.codigo?.toLowerCase().contains(q) ?? false) ||
                    (item.categoria?.toLowerCase().contains(q) ?? false);
              },
              selectable: true,
              multiSelect: true,
              onSelectionChanged: (selected) {
                _itemsSeleccionados.value = selected;
              },
              showSearch: true,
              searchHint: 'Buscar en ${_fabricaSeleccionada!.nombre}...',
              showItemCount: true,
              emptyMessage: 'No hay productos en esta fábrica',
              headerActions: [
                ValueListenableBuilder<Set<FabricaItem>>(
                  valueListenable: _itemsSeleccionados,
                  builder: (context, selected, _) {
                    if (selected.isEmpty) return const SizedBox.shrink();
                    final pendientes =
                        selected.where((i) => !i.agregadoACatalogo).toList();
                    if (pendientes.isEmpty) return const SizedBox.shrink();
                    return ElevatedButton.icon(
                      onPressed: () => _agregarMultiplesACatalogo(pendientes),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text('Agregar ${pendientes.length} al catálogo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _importarArchivo() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FabricaImportDialog(),
    );

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  void _actualizarFabrica(FabricaSource fabrica) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FabricaImportDialog(fabricaExistente: fabrica),
    );

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  void _confirmarEliminarFabrica(FabricaSource fabrica) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar la fábrica "${fabrica.nombre}" '
          'y todos sus ${fabrica.cantidadItems} productos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await _fabricaService.eliminarFabrica(fabrica.id);
      if (exito) {
        if (_fabricaSeleccionada?.id == fabrica.id) {
          setState(() {
            _fabricaSeleccionada = null;
            _itemsFabricaActual = [];
            _productoComparar = null;
          });
        }
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fábrica eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _mostrarDialogAgregar(FabricaItem item) async {
    final markupController = TextEditingController(text: '30');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar al catálogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (item.precio != null)
              Text('Precio fábrica: ${_formatCurrency.format(item.precio)}'),
            const SizedBox(height: 16),
            TextField(
              controller: markupController,
              decoration: const InputDecoration(
                labelText: 'Porcentaje de markup (%)',
                hintText: 'Ej: 30',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            if (item.precio != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      final markup = double.tryParse(markupController.text) ?? 0;
                      final precioFinal = (item.precio! * (1 + markup / 100)).round();
                      markupController.addListener(() {
                        setDialogState(() {});
                      });
                      return Text(
                        'Precio final: ${_formatCurrency.format(precioFinal)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final markup = double.tryParse(markupController.text) ?? 0;
      await _agregarACatalogo(item, markup);
    }
    markupController.dispose();
  }

  Future<void> _agregarACatalogo(FabricaItem item, double markup) async {
    final resultado = await _fabricaService.copiarACatalogo(
      item,
      porcentajeMarkup: markup,
    );

    if (resultado != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✓ "${resultado.nombre}" agregado al catálogo a ${_formatCurrency.format(resultado.precio)}'),
          backgroundColor: Colors.green,
        ),
      );
      // Refrescar items
      if (_fabricaSeleccionada != null) {
        await _cargarItemsFabrica(_fabricaSeleccionada!.id);
      }
    }
  }

  Future<void> _agregarMultiplesACatalogo(List<FabricaItem> items) async {
    final markupController = TextEditingController(text: '30');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${items.length} productos al catálogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Se agregarán ${items.length} productos pendientes al catálogo.'),
            const SizedBox(height: 16),
            TextField(
              controller: markupController,
              decoration: const InputDecoration(
                labelText: 'Porcentaje de markup (%)',
                hintText: 'Ej: 30',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Agregar todos', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final markup = double.tryParse(markupController.text) ?? 0;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Agregando productos al catálogo...'),
            ],
          ),
        ),
      );

      final agregados = await _fabricaService.copiarMultiplesACatalogo(
        items,
        porcentajeMarkup: markup,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$agregados productos agregados al catálogo'),
            backgroundColor: Colors.green,
          ),
        );
        if (_fabricaSeleccionada != null) {
          await _cargarItemsFabrica(_fabricaSeleccionada!.id);
        }
      }
    }
    markupController.dispose();
  }
}
