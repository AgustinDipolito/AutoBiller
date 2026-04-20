// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/producto.dart';
import '../services/catalogo_service_with_firebase.dart';
import '../services/stock_service_with_firebase.dart';
import '../services/cliente_service.dart';
import '../services/image_storage_service.dart';
import '../widgets/finnapp_data_table.dart';
import '../widgets/status_chip.dart';
import '../api/api.dart';
import '../api/pdf_catalogo_api.dart';
import '../api/excel_catalogo_api.dart';
// Importar los enums
import '../models/stock.dart' show StockType, Proveedor, GroupType;

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({Key? key}) : super(key: key);

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final _catalogoService = CatalogoService();
  final ValueNotifier<List<Producto>> _productosNotifier = ValueNotifier([]);
  final ValueNotifier<Set<Producto>> _productosSeleccionadosNotifier = ValueNotifier({});
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final _formatCurrency =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    _isLoadingNotifier.value = true;
    try {
      final productos = await _catalogoService.getProductos();
      _productosNotifier.value = productos;
      _isLoadingNotifier.value = false;
    } catch (e) {
      _isLoadingNotifier.value = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _productosNotifier.dispose();
    _productosSeleccionadosNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Catálogo', style: TextStyle(color: Colors.white)),
        actions: [
          // Botón de recuperación desde Firebase (solo Android)
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            IconButton(
              icon: const Icon(Icons.cloud_download, color: Colors.white),
              tooltip: 'Recuperar datos desde Firebase',
              onPressed: _recuperarDatosFirebase,
            ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Ver historial',
            onPressed: _mostrarHistorial,
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.factory, color: Colors.white),
              tooltip: 'Gestionar Fábricas',
              onPressed: () {
                Navigator.pushNamed(context, 'fabricas').then((_) {
                  _cargarProductos(); // Refresh in case items were added
                });
              },
            ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'Importar',
              onPressed: _importar,
            ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Exportar',
            onPressed: _exportar,
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<List<Producto>>(
            valueListenable: _productosNotifier,
            builder: (context, productos, _) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FinnappDataTable<Producto>(
                  items: productos,
                  columns: [
                    DataTableColumnConfig<Producto>(
                      id: 'acciones',
                      label: 'Acciones',
                      getValue: (p) => '',
                      width: kIsWeb ? null : 124,
                      builder: (p, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.blue,
                            tooltip: 'Editar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _editarProducto(p),
                          ),
                          /*
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            tooltip: 'Eliminar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmarEliminar(p),
                          ),
                          */
                        ],
                      ),
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'id',
                      label: 'ID',
                      getValue: (p) => p.id,
                      sortable: true,
                      customSort: (a, b) => int.parse(a).compareTo(int.parse(b)),
                      width: 60,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'imagen',
                      label: 'Imagen',
                      getValue: (p) => p.imagenUrl ?? '',
                      width: 70,
                      builder: (p, value) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: p.imagenUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: p.imagenUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.broken_image,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                size: 24,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'nombre',
                      label: 'Nombre',
                      getValue: (p) => p.nombre,
                      sortable: true,
                      width: 200,
                      builder: (p, value) => Text(
                        value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'precio',
                      label: 'Precio',
                      getValue: (p) => p.precio,
                      sortable: true,
                      width: 100,
                      builder: (p, value) => Text(
                        _formatCurrency.format(value),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'tipo',
                      label: 'Tipo',
                      getValue: (p) => p.tipo,
                      sortable: true,
                      width: 100,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'grupo',
                      label: 'Grupo',
                      getValue: (p) => p.grupo?.toString() ?? p.grupoCustom ?? '-',
                      sortable: true,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'familia',
                      label: 'Familia',
                      getValue: (p) => p.familia?.name ?? p.familiaCustom ?? '-',
                      sortable: true,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'marca',
                      label: 'Marca',
                      getValue: (p) => p.marca?.name ?? p.marcaCustom ?? '-',
                      sortable: true,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'codigoStock',
                      label: 'Cód. Stock',
                      getValue: (p) => p.codigoStock ?? '-',
                      sortable: true,
                      width: 120,
                    ),
                    DataTableColumnConfig<Producto>(
                      id: 'activo',
                      label: 'Estado',
                      getValue: (p) => p.activo,
                      width: 100,
                      sortable: true,
                      builder: (p, value) => ActiveStatusChip(
                        isActive: p.activo,
                        onTap: () async {
                          final productoActualizado = p.copyWith(activo: !p.activo);
                          await _catalogoService.actualizarProducto(productoActualizado);
                          await _cargarProductos();
                        },
                      ),
                    ),
                    DataTableColumnConfig<Producto>(
                        id: 'oferta',
                        label: 'Oferta',
                        getValue: (p) => p.esOferta,
                        sortable: true,
                        width: 100,
                        builder: (p, value) => StatusChip(
                              value: p.esOferta,
                              trueLabel: 'En Oferta',
                              falseColor: Colors.red,
                              falseLabel: 'No',
                              onTap: () async {
                                final productoActualizado =
                                    p.copyWith(esOferta: !p.esOferta);
                                await _catalogoService
                                    .actualizarProducto(productoActualizado);
                                await _cargarProductos();
                              },
                            )),
                  ],
                  searchFunction: (producto, query) {
                    return producto.nombre.toLowerCase().contains(query.toLowerCase());
                  },
                  selectable: true,
                  multiSelect: true,
                  onSelectionChanged: (selected) {
                    _productosSeleccionadosNotifier.value = selected;
                  },
                  showSearch: true,
                  searchHint: 'Buscar por nombre...',
                  showItemCount: true,
                  emptyMessage: 'No hay productos en el catálogo',
                  headerActions: [
                    ElevatedButton.icon(
                      onPressed: _nuevoProducto,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo Producto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  selectablesActions: [
                    ElevatedButton.icon(
                      onPressed: () => _editarMasivo(context),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Editar Precios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _asignarGrupoMasivo,
                      icon: const Icon(Icons.group_work, size: 18),
                      label: const Text('Grupo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _asignarFamiliaMasivo,
                      icon: const Icon(Icons.category, size: 18),
                      label: const Text('Familia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _asignarMarcaMasivo,
                      icon: const Icon(Icons.business, size: 18),
                      label: const Text('Marca'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _nuevoProducto() async {
    final resultado = await showDialog<Producto>(
      context: context,
      builder: (context) => const ProductoFormDialog(),
    );

    if (resultado != null) {
      final exito = await _catalogoService.crearProducto(resultado);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto creado exitosamente')),
          );
          _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear producto')),
          );
        }
      }
    }
  }

  void _editarProducto(Producto producto) async {
    final resultado = await showDialog<Producto>(
      context: context,
      builder: (context) => ProductoFormDialog(producto: producto),
    );

    if (resultado != null) {
      final exito = await _catalogoService.actualizarProducto(resultado);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado exitosamente')),
          );
          await _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar producto')),
          );
        }
      }
    }
  }

  /*
  void _confirmarEliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await _catalogoService.eliminarProducto(producto.id);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto eliminado')),
          );
          _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar producto')),
          );
        }
      }
    }
  }
  */

  void _editarMasivo(BuildContext context) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const EdicionMasivaDialog(),
    );

    if (resultado != null && mounted) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final accion = resultado['accion'] as String;
      final valor = resultado['valor'] as double?;
      final familia = resultado['familia'] as StockType?;
      final marca = resultado['marca'] as Proveedor?;
      final tipo = resultado['tipo'] as GroupType?;
      final activo = resultado['activo'] as bool?;

      int actualizados = 0;

      try {
        switch (accion) {
          case 'porcentaje':
            actualizados = await _catalogoService.actualizarPreciosMasivo(
              porcentaje: valor!,
              familia: familia,
              marca: marca,
              tipo: tipo,
            );
            break;
          case 'sumar':
            actualizados = await _catalogoService.sumarAPreciosMasivo(
              monto: valor!.toInt(),
              familia: familia,
              marca: marca,
              tipo: tipo,
            );
            break;
          case 'asignar':
            actualizados = await _catalogoService.asignarPrecioMasivo(
              precio: valor!.toInt(),
              familia: familia,
              marca: marca,
              tipo: tipo,
            );
            break;
          case 'activar':
            actualizados = await _catalogoService.cambiarEstadoMasivo(
              activo: activo!,
              familia: familia,
              marca: marca,
              tipo: tipo,
            );
            break;
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar indicador
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en actualización masiva: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actualizados productos actualizados'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar productos desde el servicio (ya actualizados en memoria)
        _cargarProductos();
      }
    }
  }

  void _mostrarHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistorialPage(),
      ),
    );
  }

  void _asignarFamiliaMasivo() async {
    if (_productosSeleccionadosNotifier.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un producto')),
      );
      return;
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SeleccionFamiliaDialog(),
    );

    if (resultado != null) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final ids = _productosSeleccionadosNotifier.value.map((p) => p.id).toList();
      final actualizados = await _catalogoService.asignarFamiliaMasivo(
        nuevaFamilia: resultado['familia'],
        nuevaFamiliaCustom: resultado['custom'],
        productosIds: ids,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actualizados productos actualizados'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarProductos();
      }
    }
  }

  void _asignarMarcaMasivo() async {
    if (_productosSeleccionadosNotifier.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un producto')),
      );
      return;
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SeleccionMarcaDialog(),
    );

    if (resultado != null) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final ids = _productosSeleccionadosNotifier.value.map((p) => p.id).toList();
      final actualizados = await _catalogoService.asignarMarcaMasivo(
        nuevaMarca: resultado['marca'],
        nuevaMarcaCustom: resultado['custom'],
        productosIds: ids,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actualizados productos actualizados'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarProductos();
      }
    }
  }

  void _asignarGrupoMasivo() async {
    if (_productosSeleccionadosNotifier.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un producto')),
      );
      return;
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SeleccionGrupoDialog(),
    );

    if (resultado != null) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final ids = _productosSeleccionadosNotifier.value.map((p) => p.id).toList();
      final actualizados = await _catalogoService.asignarGrupoMasivo(
        nuevoGrupo: resultado['grupo'],
        nuevoGrupoCustom: resultado['custom'],
        productosIds: ids,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actualizados productos actualizados'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarProductos();
      }
    }
  }

  /// Recuperar datos desde Firebase (Stock y Clientes)
  Future<void> _recuperarDatosFirebase() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Firebase'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Desea recuperar los datos desde Firebase?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Esto descargará:'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Stock de productos'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.green),
                SizedBox(width: 8),
                Text('Pedidos de clientes'),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Los datos locales serán reemplazados por los de Firebase.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cloud_download),
            label: const Text('Recuperar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recuperando datos desde Firebase...'),
          ],
        ),
      ),
    );

    try {
      final stockService = StockService();
      final clienteService = ClienteService();

      // Inicializar servicios
      stockService.init();
      clienteService.init();

      // Activar Firebase sync para poder descargar
      await stockService.setFirebaseSync(
        true,
      );
      await clienteService.setFirebaseSync(
        true,
      );

      // Descargar datos desde Firebase
      final stockRecuperado = await stockService.loadFromFirebase();
      final clientesRecuperado = await clienteService.loadFromFirebase();

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        final mensajes = <String>[];
        if (stockRecuperado) {
          mensajes.add('✅ Stock recuperado (${stockService.stock.length} items)');
        } else {
          mensajes.add('❌ Error al recuperar stock');
        }
        if (clientesRecuperado) {
          mensajes
              .add('✅ Clientes recuperados (${clienteService.clientes.length} pedidos)');
        } else {
          mensajes.add('❌ Error al recuperar clientes');
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  stockRecuperado && clientesRecuperado
                      ? Icons.check_circle
                      : Icons.warning,
                  color: stockRecuperado && clientesRecuperado
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text('Resultado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mensajes
                  .map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(m),
                      ))
                  .toList(),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recuperar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importar() async {
    try {
      // Seleccionar archivo Excel
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // Usuario canceló
      }

      final file = result.files.first;

      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo leer el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Importación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Archivo: ${file.name}'),
              const SizedBox(height: 16),
              const Text(
                '¿Desea importar los productos desde este archivo Excel?\n\n'
                '• Los productos nuevos serán creados\n'
                '• Los productos existentes (mismo ID) serán actualizados\n'
                '• Se registrará en el historial de cambios',
                style: TextStyle(fontSize: 13),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importando productos...'),
            ],
          ),
        ),
      );

      // Importar desde Excel
      final resultado = await _catalogoService.importarDesdeExcel(file.bytes!);

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        final importados = resultado['importados'] as int;
        final actualizados = resultado['actualizados'] as int;
        final errores = resultado['errores'] as List<String>;

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Importación Completada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Productos nuevos: $importados',
                    style:
                        const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🔄 Productos actualizados: $actualizados',
                    style:
                        const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  if (errores.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ Errores y advertencias:',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: errores
                              .map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '• $e',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        // Recargar productos
        if (importados > 0 || actualizados > 0) {
          _cargarProductos();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar indicador si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportar() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Catálogo'),
        content: const Text('Seleccione el formato de exportación:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportarExcel();
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportarPDF();
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPDF() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final pdfFile = await PdfCatalogoApi.generate(_productosNotifier.value);

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        await FileApi.openFile(pdfFile);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catálogo PDF exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportarExcel() async {
    // Mostrar diálogo de opciones de Excel
    final incluirEstadisticas = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar a Excel'),
        content: const Text(
          '¿Desea incluir una hoja de estadísticas?\n\n'
          '• Básico: Solo lista de productos con todos los campos\n'
          '• Con estadísticas: Lista + resumen y análisis',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Solo Lista'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Con Estadísticas'),
          ),
        ],
      ),
    );

    if (incluirEstadisticas == null) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final excelFile = incluirEstadisticas
          ? await ExcelCatalogoApi.generateConEstadisticas(_productosNotifier.value)
          : await ExcelCatalogoApi.generate(_productosNotifier.value);

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        if (excelFile != null) {
          await FileApi.openFile(excelFile);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catálogo Excel exportado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo generar el archivo Excel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================== DIALOGS ====================

/// Dialog para crear/editar producto
class ProductoFormDialog extends StatefulWidget {
  final Producto? producto;

  const ProductoFormDialog({Key? key, this.producto}) : super(key: key);

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _catalogoService = CatalogoService();
  final _imageStorageService = ImageStorageService();

  late TextEditingController _idController;
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;
  late TextEditingController _tipoController;
  late TextEditingController _marcaCustomController;
  late TextEditingController _familiaCustomController;
  late TextEditingController _grupoCustomController;

  Proveedor? _marcaSeleccionada;
  String? _codigoStockSeleccionado;
  StockType? _familiaSeleccionada;
  GroupType? _grupoSeleccionado;

  bool _isNuevo = true;
  bool _esOferta = false;
  List<String> _codigosStockDisponibles = [];

  // Image handling
  Uint8List? _selectedImageBytes;
  String _selectedImageExtension = '.jpg';
  String? _currentImageUrl;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _isNuevo = widget.producto == null;

    _idController = TextEditingController(text: widget.producto?.id ?? '');
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioController =
        TextEditingController(text: widget.producto?.precio.toString() ?? '');
    _tipoController = TextEditingController(text: widget.producto?.tipo ?? '');
    _marcaSeleccionada = widget.producto?.marca;
    _codigoStockSeleccionado = widget.producto?.codigoStock;
    _familiaSeleccionada = widget.producto?.familia;
    _grupoSeleccionado = widget.producto?.grupo;
    _descripcionController =
        TextEditingController(text: widget.producto?.descripcion ?? '');
    _esOferta = widget.producto?.esOferta ?? false;

    _marcaCustomController =
        TextEditingController(text: widget.producto?.marcaCustom ?? '');
    _familiaCustomController =
        TextEditingController(text: widget.producto?.familiaCustom ?? '');
    _grupoCustomController =
        TextEditingController(text: widget.producto?.grupoCustom ?? '');

    _currentImageUrl = widget.producto?.imagenUrl;

    if (_isNuevo) {
      _obtenerNextId();
    }
    _cargarCodigosStock();
  }

  Future<void> _cargarCodigosStock() async {
    // Obtener códigos de stock desde StockService
    final stockService = StockService();
    setState(() {
      _codigosStockDisponibles = stockService.stock.map((s) => s.name).toList()..sort();
    });
  }

  Future<void> _obtenerNextId() async {
    final nextId = await _catalogoService.getNextId();
    _idController.text = nextId;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _marcaCustomController.dispose();
    _familiaCustomController.dispose();
    _grupoCustomController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNuevo ? 'Nuevo Producto' : 'Editar Producto'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'ID *'),
                  enabled: _isNuevo,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El ID es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(labelText: 'Precio *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El precio es obligatorio';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipoController,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GroupType>(
                  initialValue: _grupoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: [
                    const DropdownMenuItem<GroupType>(
                      value: null,
                      child: Text('Sin grupo'),
                    ),
                    ...GroupType.values.map((grupo) => DropdownMenuItem<GroupType>(
                          value: grupo,
                          child: Text(grupo.toString()),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _grupoSeleccionado = value;
                    });
                  },
                ),
                if (_grupoSeleccionado == GroupType.Otros)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _grupoCustomController,
                      decoration: const InputDecoration(labelText: 'Especifique Grupo'),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StockType>(
                  initialValue: _familiaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Familia'),
                  items: [
                    const DropdownMenuItem<StockType>(
                      value: null,
                      child: Text('Sin familia'),
                    ),
                    ...StockType.values.map((familia) => DropdownMenuItem<StockType>(
                          value: familia,
                          child: Text(_capitalize(familia.name)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _familiaSeleccionada = value;
                    });
                  },
                ),
                if (_familiaSeleccionada == StockType.otro)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _familiaCustomController,
                      decoration: const InputDecoration(labelText: 'Especifique Familia'),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Proveedor>(
                  initialValue: _marcaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Marca'),
                  items: [
                    const DropdownMenuItem<Proveedor>(
                      value: null,
                      child: Text('Sin marca'),
                    ),
                    ...Proveedor.values.map((marca) => DropdownMenuItem<Proveedor>(
                          value: marca,
                          child: Text(_capitalize(marca.name)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _marcaSeleccionada = value;
                    });
                  },
                ),
                if (_marcaSeleccionada == Proveedor.otro)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _marcaCustomController,
                      decoration: const InputDecoration(labelText: 'Especifique Marca'),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _codigoStockSeleccionado,
                  decoration: const InputDecoration(labelText: 'Código de Stock'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin código'),
                    ),
                    ..._codigosStockDisponibles.map((codigo) => DropdownMenuItem<String>(
                          value: codigo,
                          child: Text(codigo),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _codigoStockSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Image picker section
                const Text('Imagen del producto',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Image preview
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _currentImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: _currentImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(
                                _selectedImageBytes != null || _currentImageUrl != null
                                    ? 'Cambiar imagen'
                                    : 'Seleccionar imagen'),
                          ),
                          if (_selectedImageBytes != null || _currentImageUrl != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _currentImageUrl = null;
                                  _imageChanged = true;
                                });
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Eliminar'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          const Text(
                            'Máx. 1MB - JPG, PNG',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Es Oferta'),
                  subtitle: const Text('Aparecerá en la sección de ofertas del PDF'),
                  value: _esOferta,
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      _esOferta = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (image != null) {
        final selected = image.files.single;
        if (selected.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo leer la imagen seleccionada')),
            );
          }
          return;
        }

        final extension = selected.extension?.toLowerCase();

        setState(() {
          _selectedImageBytes = selected.bytes;
          _selectedImageExtension =
              extension != null && extension.isNotEmpty ? '.$extension' : '.jpg';
          _imageChanged = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      String? imagenUrl = _currentImageUrl;

      // Upload image if changed
      if (_imageChanged) {
        if (_selectedImageBytes != null) {
          // Upload new image
          imagenUrl = await _imageStorageService.uploadProductImageBytes(
            _idController.text,
            _selectedImageBytes!,
            extension: _selectedImageExtension,
          );

          if (imagenUrl == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Error al subir imagen. Se guardará el producto sin imagen.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Image was removed
          if (_currentImageUrl != null) {
            await _imageStorageService.deleteProductImage(_idController.text);
          }
          imagenUrl = null;
        }
      }

      final producto = Producto(
        id: _idController.text,
        nombre: _nombreController.text,
        precio: int.parse(_precioController.text),
        tipo: _tipoController.text,
        marca: _marcaSeleccionada,
        marcaCustom:
            _marcaSeleccionada == Proveedor.otro ? _marcaCustomController.text : null,
        codigoStock: _codigoStockSeleccionado,
        familia: _familiaSeleccionada,
        familiaCustom:
            _familiaSeleccionada == StockType.otro ? _familiaCustomController.text : null,
        grupo: _grupoSeleccionado,
        grupoCustom:
            _grupoSeleccionado == GroupType.Otros ? _grupoCustomController.text : null,
        descripcion:
            _descripcionController.text.isEmpty ? null : _descripcionController.text,
        imagenUrl: imagenUrl,
        esOferta: _esOferta,
      );

      if (mounted) {
        Navigator.pop(context, producto);
      }
    }
  }
}

/// Dialog para edición masiva de precios
class EdicionMasivaDialog extends StatefulWidget {
  const EdicionMasivaDialog({Key? key}) : super(key: key);

  @override
  State<EdicionMasivaDialog> createState() => _EdicionMasivaDialogState();
}

class _EdicionMasivaDialogState extends State<EdicionMasivaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  String _accionSeleccionada = 'porcentaje';
  bool _estadoActivo = true;
  StockType? _familiaSeleccionada;
  Proveedor? _marcaSeleccionada;
  GroupType? _tipoSeleccionado;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edición Masiva'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccione la acción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _accionSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Acción *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'porcentaje',
                      child: Text('Aumentar/Disminuir por %'),
                    ),
                    DropdownMenuItem(
                      value: 'sumar',
                      child: Text('Sumar/Restar monto fijo'),
                    ),
                    DropdownMenuItem(
                      value: 'asignar',
                      child: Text('Asignar precio fijo'),
                    ),
                    DropdownMenuItem(
                      value: 'activar',
                      child: Text('Activar/Desactivar productos'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _accionSeleccionada = value!;
                      _valorController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Campo de valor según la acción
                if (_accionSeleccionada != 'activar') ...[
                  TextFormField(
                    controller: _valorController,
                    decoration: InputDecoration(
                      labelText: _getLabelForAccion(),
                      hintText: _getHintForAccion(),
                      suffixText: _accionSeleccionada == 'porcentaje' ? '%' : '\$',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      signed: _accionSeleccionada != 'asignar',
                      decimal: _accionSeleccionada == 'porcentaje',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio';
                      }
                      if (_accionSeleccionada == 'porcentaje') {
                        if (double.tryParse(value) == null) {
                          return 'Ingrese un número válido';
                        }
                      } else {
                        if (int.tryParse(value) == null) {
                          return 'Ingrese un número entero válido';
                        }
                        if (_accionSeleccionada == 'asignar' && int.parse(value) < 0) {
                          return 'El precio no puede ser negativo';
                        }
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Text('Estado:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Activar'),
                          selected: _estadoActivo,
                          selectedColor: Colors.green,
                          onSelected: (selected) {
                            setState(() => _estadoActivo = true);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Desactivar'),
                          selected: !_estadoActivo,
                          selectedColor: Colors.red,
                          onSelected: (selected) {
                            setState(() => _estadoActivo = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Filtros (opcionales):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<StockType>(
                  initialValue: _familiaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Familia',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<StockType>(value: null, child: Text('Todas')),
                    ...StockType.values.map((f) => DropdownMenuItem<StockType>(
                          value: f,
                          child: Text(_capitalize(f.name)),
                        )),
                  ],
                  onChanged: (value) => setState(() => _familiaSeleccionada = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Proveedor>(
                  initialValue: _marcaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<Proveedor>(value: null, child: Text('Todas')),
                    ...Proveedor.values.map((m) => DropdownMenuItem<Proveedor>(
                          value: m,
                          child: Text(_capitalize(m.name)),
                        )),
                  ],
                  onChanged: (value) => setState(() => _marcaSeleccionada = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GroupType>(
                  initialValue: _tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<GroupType>(value: null, child: Text('Todos')),
                    ...GroupType.values.map((t) => DropdownMenuItem<GroupType>(
                          value: t,
                          child: Text(t.toString()),
                        )),
                  ],
                  onChanged: (value) => setState(() => _tipoSeleccionado = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aplicar,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  String _getLabelForAccion() {
    switch (_accionSeleccionada) {
      case 'porcentaje':
        return 'Porcentaje *';
      case 'sumar':
        return 'Monto a sumar/restar *';
      case 'asignar':
        return 'Precio fijo *';
      default:
        return '';
    }
  }

  String _getHintForAccion() {
    switch (_accionSeleccionada) {
      case 'porcentaje':
        return 'Ej: 10 (aumenta 10%), -15 (disminuye 15%)';
      case 'sumar':
        return 'Ej: 500 (suma \$500), -200 (resta \$200)';
      case 'asignar':
        return 'Ej: 5000 (todos los productos a \$5000)';
      default:
        return '';
    }
  }

  void _aplicar() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> resultado = {
        'accion': _accionSeleccionada,
        'familia': _familiaSeleccionada,
        'marca': _marcaSeleccionada,
        'tipo': _tipoSeleccionado,
      };

      if (_accionSeleccionada == 'activar') {
        resultado['activo'] = _estadoActivo;
      } else {
        resultado['valor'] = _accionSeleccionada == 'porcentaje'
            ? double.parse(_valorController.text)
            : double.parse(_valorController.text);
      }

      Navigator.pop(context, resultado);
    }
  }
}

/// Página de historial de cambios
class HistorialPage extends StatefulWidget {
  const HistorialPage({Key? key}) : super(key: key);

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final _catalogoService = CatalogoService();
  List<CambioHistorial> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    try {
      final historial = await _catalogoService.getHistorial();
      setState(() {
        _historial = historial.reversed.toList(); // Más recientes primero
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Historial de Cambios', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? const Center(child: Text('No hay cambios registrados'))
              : ListView.builder(
                  itemCount: _historial.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final cambio = _historial[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorByCampo(cambio.campo),
                          child: Icon(_getIconByCampo(cambio.campo),
                              color: Colors.white, size: 20),
                        ),
                        title: Text(
                          '${cambio.nombreProducto} - ${cambio.campo}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cambio.valorAnterior != null)
                              Text('Anterior: ${cambio.valorAnterior}'),
                            if (cambio.valorNuevo != null)
                              Text('Nuevo: ${cambio.valorNuevo}'),
                            Text(
                              dateFormat.format(cambio.fecha),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: _puedeRestablecer(cambio)
                            ? IconButton(
                                icon: const Icon(Icons.restore, color: Colors.blue),
                                tooltip: 'Restablecer valor anterior',
                                onPressed: () => _confirmarRestablecer(cambio),
                              )
                            : null,
                        dense: true,
                      ),
                    );
                  },
                ),
    );
  }

  Color _getColorByCampo(String campo) {
    switch (campo.toLowerCase()) {
      case 'precio':
        return Colors.green;
      case 'creación':
        return Colors.blue;
      case 'eliminación':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getIconByCampo(String campo) {
    switch (campo.toLowerCase()) {
      case 'precio':
        return Icons.attach_money;
      case 'creación':
        return Icons.add_circle;
      case 'eliminación':
        return Icons.delete;
      default:
        return Icons.edit;
    }
  }

  bool _puedeRestablecer(CambioHistorial cambio) {
    // Solo se puede restablecer si no es creación/eliminación y tiene valor anterior
    return cambio.campo.toLowerCase() != 'creación' &&
        cambio.campo.toLowerCase() != 'eliminación' &&
        cambio.valorAnterior != null;
  }

  Future<void> _confirmarRestablecer(CambioHistorial cambio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer valor'),
        content: Text(
          '¿Desea restablecer "${cambio.campo}" de "${cambio.nombreProducto}" al valor anterior?\n\n'
          'Valor actual: ${cambio.valorNuevo}\n'
          'Valor anterior: ${cambio.valorAnterior}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _restablecer(cambio);
    }
  }

  Future<void> _restablecer(CambioHistorial cambio) async {
    try {
      // Obtener el producto actual
      final producto = await _catalogoService.getProductoById(cambio.productoId);

      if (producto == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto no encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Crear producto actualizado según el campo
      Producto productoActualizado;
      final campo = cambio.campo.toLowerCase();

      switch (campo) {
        case 'precio':
          final precioAnterior = int.tryParse(cambio.valorAnterior ?? '0') ?? 0;
          productoActualizado = producto.copyWith(precio: precioAnterior);
          break;

        case 'nombre':
          productoActualizado = producto.copyWith(nombre: cambio.valorAnterior);
          break;

        case 'tipo':
          productoActualizado = producto.copyWith(tipo: cambio.valorAnterior);
          break;

        case 'marca':
          final marca =
              cambio.valorAnterior == null || cambio.valorAnterior == 'Sin marca'
                  ? null
                  : Proveedor.values.firstWhere(
                      (m) => m.name == cambio.valorAnterior,
                      orElse: () => producto.marca ?? Proveedor.values.first,
                    );
          productoActualizado = producto.copyWith(marca: marca);
          break;

        case 'familia':
          final familia =
              cambio.valorAnterior == null || cambio.valorAnterior == 'Sin familia'
                  ? null
                  : StockType.values.firstWhere(
                      (f) => f.name == cambio.valorAnterior,
                      orElse: () => producto.familia ?? StockType.values.first,
                    );
          productoActualizado = producto.copyWith(familia: familia);
          break;

        case 'grupo':
          final grupo =
              cambio.valorAnterior == null || cambio.valorAnterior == 'Sin grupo'
                  ? null
                  : GroupType.values.firstWhere(
                      (g) => g.toString() == cambio.valorAnterior,
                      orElse: () => producto.grupo ?? GroupType.values.first,
                    );
          productoActualizado = producto.copyWith(grupo: grupo);
          break;

        case 'estado':
          final activo = cambio.valorAnterior == 'Activo';
          productoActualizado = producto.copyWith(activo: activo);
          break;

        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se puede restablecer el campo: ${cambio.campo}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
      }

      // Actualizar el producto
      final exito = await _catalogoService.actualizarProducto(productoActualizado);

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cambio.campo} restablecido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarHistorial(); // Recargar historial para ver el nuevo cambio
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al restablecer el valor'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================== DIALOGS PARA ASIGNACIÓN MASIVA ====================

/// Dialog para seleccionar familia
class SeleccionFamiliaDialog extends StatefulWidget {
  const SeleccionFamiliaDialog({Key? key}) : super(key: key);

  @override
  State<SeleccionFamiliaDialog> createState() => _SeleccionFamiliaDialogState();
}

class _SeleccionFamiliaDialogState extends State<SeleccionFamiliaDialog> {
  StockType? _familiaSeleccionada;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Familia'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione la familia a asignar a los productos seleccionados:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StockType>(
              initialValue: _familiaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Familia',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<StockType>(
                  value: null,
                  child: Text('Sin familia'),
                ),
                ...StockType.values.map((familia) => DropdownMenuItem<StockType>(
                      value: familia,
                      child: Text(_capitalize(familia.name)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _familiaSeleccionada = value;
                });
              },
            ),
            if (_familiaSeleccionada == StockType.otro)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _customController,
                  decoration: const InputDecoration(labelText: 'Especifique Familia'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'familia': _familiaSeleccionada,
            'custom':
                _familiaSeleccionada == StockType.otro ? _customController.text : null,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}

/// Dialog para seleccionar marca
class SeleccionMarcaDialog extends StatefulWidget {
  const SeleccionMarcaDialog({Key? key}) : super(key: key);

  @override
  State<SeleccionMarcaDialog> createState() => _SeleccionMarcaDialogState();
}

class _SeleccionMarcaDialogState extends State<SeleccionMarcaDialog> {
  Proveedor? _marcaSeleccionada;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Marca'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione la marca a asignar a los productos seleccionados:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Proveedor>(
              initialValue: _marcaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Proveedor>(
                  value: null,
                  child: Text('Sin marca'),
                ),
                ...Proveedor.values.map((marca) => DropdownMenuItem<Proveedor>(
                      value: marca,
                      child: Text(_capitalize(marca.name)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _marcaSeleccionada = value;
                });
              },
            ),
            if (_marcaSeleccionada == Proveedor.otro)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _customController,
                  decoration: const InputDecoration(labelText: 'Especifique Marca'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'marca': _marcaSeleccionada,
            'custom':
                _marcaSeleccionada == Proveedor.otro ? _customController.text : null,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}

/// Dialog para seleccionar grupo
class SeleccionGrupoDialog extends StatefulWidget {
  const SeleccionGrupoDialog({Key? key}) : super(key: key);

  @override
  State<SeleccionGrupoDialog> createState() => _SeleccionGrupoDialogState();
}

class _SeleccionGrupoDialogState extends State<SeleccionGrupoDialog> {
  GroupType? _grupoSeleccionado;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Grupo'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione el grupo a asignar a los productos seleccionados:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GroupType>(
              initialValue: _grupoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Grupo',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<GroupType>(
                  value: null,
                  child: Text('Sin grupo'),
                ),
                ...GroupType.values.map((grupo) => DropdownMenuItem<GroupType>(
                      value: grupo,
                      child: Text(_capitalize(grupo.toString())),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _grupoSeleccionado = value;
                });
              },
            ),
            if (_grupoSeleccionado == GroupType.Otros)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _customController,
                  decoration: const InputDecoration(labelText: 'Especifique Grupo'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'grupo': _grupoSeleccionado,
            'custom':
                _grupoSeleccionado == GroupType.Otros ? _customController.text : null,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
