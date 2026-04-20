import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dist_v2/helpers/export_utils.dart';
import 'package:dist_v2/utils.dart';
import 'package:flutter/material.dart';
// import 'package:plataforma_finnapp/data/appData.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget de tabla avanzada para listar objetos con funcionalidades de:
/// - Selección de registros (múltiple)
/// - Acciones personalizadas por celda
/// - Ordenamiento por columnas
/// - Agrupamiento multi-nivel (interactivo desde UI)
/// - Paginación
/// - Búsqueda/filtrado
///
/// Ejemplo de uso:
/// ```dart
/// FinnappDataTable<User>(
///   items: users,
///   columns: [
///     DataTableColumnConfig(
///       id: 'nombre',
///       label: 'Nombre',
///       getValue: (user) => user.nombre,
///       sortable: true,
///     ),
///     DataTableColumnConfig(
///       id: 'email',
///       label: 'Email',
///       getValue: (user) => user.email,
///       sortable: true,
///     ),
///     DataTableColumnConfig(
///       id: 'rol',
///       label: 'Rol',
///       getValue: (user) => user.rol,
///       sortable: true,
///     ),
///   ],
///   onSelectionChanged: (selected) => debugPrint('Selected: $selected'),
///   // El agrupamiento es interactivo: el usuario hace clic en el menú de la columna
///   // y selecciona "Agrupar por [Columna]". Soporta múltiples niveles.
/// )
/// ```
class FinnappDataTable<T> extends StatefulWidget {
  /// Lista de items a mostrar en la tabla
  final List<T> items;

  /// Configuración de columnas
  final List<DataTableColumnConfig<T>> columns;

  /// Callback cuando cambia la selección
  final Function(Set<T>)? onSelectionChanged;

  /// Habilitar selección de filas
  final bool selectable;

  /// Habilitar selección múltiple
  final bool multiSelect;

  /// Items seleccionados inicialmente
  final Set<T>? initialSelection;

  /// Función para obtener el ID único de cada item
  final String Function(T)? getItemId;

  /// Mostrar barra de búsqueda
  final bool showSearch;

  /// Hint text para la búsqueda
  final String searchHint;

  /// Función de búsqueda personalizada
  final bool Function(T item, String query)? searchFunction;

  /// Habilitar paginación
  final bool paginated;

  /// Número de items por página
  final int itemsPerPage;

  /// Mostrar contador de items
  final bool showItemCount;

  /// Altura de fila
  final double rowHeight;

  /// Color de fila seleccionada
  final Color? selectedRowColor;

  /// Color de fila al hover
  final Color? hoverRowColor;

  /// Widget cuando no hay datos
  final Widget? emptyWidget;

  /// Mensaje cuando no hay datos
  final String emptyMessage;

  /// Altura máxima de la tabla
  final double? maxHeight;

  /// Acciones globales (botones en header)
  final List<Widget>? headerActions;
  final List<Widget> selectablesActions;

  /// Nombre del archivo para exportar (sin extensión)
  final String exportFileName;

  /// Clave única para persistir configuración del usuario (columnas, filtros, orden)
  final String? configKey;

  /// Callback cuando cambian los items filtrados (búsqueda, filtros, etc.)
  final Function(List<T>)? onFilteredItemsChanged;

  const FinnappDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.onSelectionChanged,
    this.selectable = true,
    this.multiSelect = true,
    this.initialSelection,
    this.getItemId,
    this.showSearch = true,
    this.searchHint = 'Buscar...',
    this.searchFunction,
    this.paginated = false,
    this.itemsPerPage = 10,
    this.showItemCount = true,
    this.rowHeight = 56.0,
    this.selectedRowColor,
    this.hoverRowColor,
    this.emptyWidget,
    this.selectablesActions = const [],
    this.emptyMessage = 'No hay datos para mostrar',
    this.maxHeight,
    this.headerActions,
    this.exportFileName = 'export',
    this.configKey,
    this.onFilteredItemsChanged,
  });

  @override
  State<FinnappDataTable<T>> createState() => _FinnappDataTableState<T>();
}

class _FinnappDataTableState<T> extends State<FinnappDataTable<T>> {
  late final ValueNotifier<Set<T>> _selectedItems;

  late final ValueNotifier<String?> _sortColumnId;
  late final ValueNotifier<bool> _sortAscending;
  late final ValueNotifier<int> _currentPage;
  late final ScrollController _scrollController;
  late final ScrollController _horizontalScrollController;

  // Lista de columnas por las que se está agrupando (en orden)
  late final ValueNotifier<List<String>> _groupedByColumns;

  // Columnas ocultas (por ID)
  late final ValueNotifier<Set<String>> _hiddenColumns;

  // Orden de columnas (lista de IDs)
  late final ValueNotifier<List<String>> _columnOrder;

  // Filtros activos por columna (columnId -> Set de valores seleccionados)
  late final ValueNotifier<Map<String, Set<dynamic>>> _activeFilters;

  // Anchos personalizados por columna (columnId -> width)
  late final ValueNotifier<Map<String, double>> _columnWidths;

  // Timer para debounce de búsqueda
  Timer? _searchDebounce;

  // Controller para el campo de búsqueda
  late final TextEditingController _searchController;

  // Ancho por defecto para las celdas
  double defaultCellWidth = 160;

  // Cache para grupos flattened (mejora performance)
  List<_SliverItem<T>>? _cachedFlattenedItems;

  // Estado de expansión de grupos (key = path del grupo como string)
  late final ValueNotifier<Map<String, bool>> _groupExpanded;
  @override
  void initState() {
    super.initState();
    _selectedItems = ValueNotifier(Set.from(widget.initialSelection ?? {}));

    _sortColumnId = ValueNotifier(null);
    _sortAscending = ValueNotifier(true);
    _currentPage = ValueNotifier(0);
    _groupedByColumns = ValueNotifier([]);
    _groupExpanded = ValueNotifier({});
    _hiddenColumns = ValueNotifier({});
    _columnOrder = ValueNotifier(widget.columns.map((c) => c.id).toList());
    _activeFilters = ValueNotifier({});
    _columnWidths = ValueNotifier({});
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _searchController = TextEditingController();

    // Cargar configuración guardada
    _loadConfiguration();

    // Listeners para invalidar cache cuando cambian datos relevantes

    _sortColumnId.addListener(_invalidateCache);
    _sortAscending.addListener(_invalidateCache);
    _groupedByColumns.addListener(_invalidateCache);
    _groupExpanded.addListener(_invalidateCache);
    _hiddenColumns.addListener(_invalidateCache);
    _columnOrder.addListener(_invalidateCache);
    _activeFilters.addListener(_invalidateCache);
    _currentPage.addListener(_invalidateCache);
    _columnWidths.addListener(_invalidateCache);

    // Listener para sincronizar el controller con el ValueNotifier
    _searchController.addListener(_invalidateCache);

    // Listeners para guardar configuración
    _hiddenColumns.addListener(_saveConfiguration);
    _columnOrder.addListener(_saveConfiguration);
    _activeFilters.addListener(_saveConfiguration);
    _columnWidths.addListener(_saveConfiguration);
  }

  @override
  void didUpdateWidget(covariant FinnappDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _columnOrder.value = widget.columns.map((c) => c.id).toList();
      _invalidateCache();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _selectedItems.dispose();
    _sortColumnId.dispose();
    _sortAscending.dispose();
    _currentPage.dispose();
    _groupedByColumns.dispose();
    _groupExpanded.dispose();
    _hiddenColumns.dispose();
    _columnOrder.dispose();
    _activeFilters.dispose();
    _columnWidths.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Invalidar cache cuando cambian los datos relevantes
  void _invalidateCache() {
    _cachedFlattenedItems = null;

    // Notificar items filtrados después del próximo frame para asegurar que _filteredItems está actualizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFilteredItemsChanged?.call(_filteredItems);
      }
    });
  }

  // Cargar configuración desde SharedPreferences
  Future<void> _loadConfiguration() async {
    if (widget.configKey == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('datatable_config_${widget.configKey}');

      if (configJson != null) {
        final config = json.decode(configJson) as Map<String, dynamic>;
        final currentColumnIds = widget.columns.map((c) => c.id).toSet();

        // Cargar columnas ocultas (solo las que existen en columnas actuales)
        if (config['hiddenColumns'] != null) {
          final hiddenList = List<String>.from(config['hiddenColumns'] as List);
          final validHidden =
              hiddenList.where((id) => currentColumnIds.contains(id)).toSet();
          // Validar que al menos 1 columna esté visible
          if (validHidden.length < widget.columns.length) {
            _hiddenColumns.value = validHidden;
          }
        }

        // Cargar orden de columnas (reconstruir con columnas actuales)
        if (config['columnOrder'] != null) {
          final orderList = List<String>.from(config['columnOrder'] as List);
          // Mantener el orden guardado de las columnas que existen
          final validOrder =
              orderList.where((id) => currentColumnIds.contains(id)).toList();
          // Agregar columnas nuevas que no estaban en el orden guardado
          final newColumns = currentColumnIds.difference(validOrder.toSet());
          validOrder.addAll(newColumns);
          _columnOrder.value = validOrder;
        }

        // Cargar filtros activos (solo para columnas que existen)
        if (config['activeFilters'] != null) {
          final filtersMap = config['activeFilters'] as Map<String, dynamic>;
          final filters = <String, Set<dynamic>>{};
          filtersMap.forEach((key, value) {
            if (currentColumnIds.contains(key)) {
              filters[key] = Set.from(value as List);
            }
          });
          _activeFilters.value = filters;
        }

        // Cargar anchos personalizados
        if (config['columnWidths'] != null) {
          final widthsMap = config['columnWidths'] as Map<String, dynamic>;
          final widths = <String, double>{};
          widthsMap.forEach((key, value) {
            widths[key] = (value as num).toDouble();
          });
          _columnWidths.value = widths;
        }
      }
    } catch (e) {
      debugPrint('Error loading table configuration: $e');
    }
  }

  // Guardar configuración en SharedPreferences
  Future<void> _saveConfiguration() async {
    if (widget.configKey == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final config = {
        'hiddenColumns': _hiddenColumns.value.toList(),
        'columnOrder': _columnOrder.value,
        'activeFilters': _activeFilters.value.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
        'columnWidths': _columnWidths.value,
      };

      await prefs.setString(
        'datatable_config_${widget.configKey}',
        json.encode(config),
      );
    } catch (e) {
      debugPrint('Error saving table configuration: $e');
    }
  }

  // 🔧 Calcular ancho total de las columnas
  double get _totalColumnsWidth {
    double total = 0;
    for (var column in _visibleColumns) {
      total += _getColumnWidth(column); // Usar ancho personalizado o default
    }
    if (widget.selectable) {
      total += 48; // Ancho del checkbox
    }
    return total;
  }

  // Obtener ancho de una columna (personalizado, definido o default)
  double _getColumnWidth(DataTableColumnConfig<T> column) {
    return _columnWidths.value[column.id] ?? column.width ?? defaultCellWidth;
  }

  // Actualizar ancho de columna
  void _updateColumnWidth(String columnId, double width) {
    final updated = Map<String, double>.from(_columnWidths.value);
    updated[columnId] = width.clamp(80.0, 500.0); // Min 80px, Max 500px
    _columnWidths.value = updated;
  }

  // Obtener columnas visibles en el orden correcto
  List<DataTableColumnConfig<T>> get _visibleColumns {
    final ordered = <DataTableColumnConfig<T>>[];
    final addedIds = <String>{};
    final currentColumnIds = widget.columns.map((c) => c.id).toSet();

    // Primero agregar columnas según el orden guardado (si existen en columnas actuales)
    for (var columnId in _columnOrder.value) {
      if (currentColumnIds.contains(columnId) &&
          !_hiddenColumns.value.contains(columnId)) {
        final column = widget.columns.firstWhere((c) => c.id == columnId);
        ordered.add(column);
        addedIds.add(columnId);
      }
    }

    // Luego agregar columnas nuevas en el orden definido en widget.columns

    return ordered;
  }

  List<T> get _filteredItems {
    var filtered = List<T>.from(widget.items);

    // Aplicar filtros de columna (AND entre columnas, OR dentro de columna)
    if (_activeFilters.value.isNotEmpty) {
      filtered = filtered.where((item) {
        // Para cada columna con filtros activos
        for (var entry in _activeFilters.value.entries) {
          final columnId = entry.key;
          final selectedValues = entry.value;

          if (selectedValues.isEmpty) continue;

          final column = widget.columns.firstWhereOrNull((col) => col.id == columnId);
          if (column == null) continue;

          final itemValue = column.getValue(item);
          final itemValueStr = itemValue?.toString() ?? '';

          // Si el valor del item no está en los valores seleccionados, filtrar
          if (!selectedValues.any((v) => v.toString() == itemValueStr)) {
            return false; // AND entre columnas
          }
        }
        return true;
      }).toList();
    }

    // Aplicar búsqueda
    if (_searchController.text.isNotEmpty) {
      if (widget.searchFunction != null) {
        filtered = filtered
            .where((item) => widget.searchFunction!(item, _searchController.text))
            .toList();
      } else {
        // Búsqueda por defecto en todas las columnas
        filtered = filtered.where((item) {
          return widget.columns.any((column) {
            final value = column.getValue(item);
            return value
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
          });
        }).toList();
      }
    }

    // Aplicar ordenamiento
    if (_sortColumnId.value != null) {
      final sortColumn = widget.columns.firstWhere(
        (col) => col.id == _sortColumnId.value,
      );
      filtered.sort((a, b) {
        final aValue = sortColumn.getValue(a);
        final bValue = sortColumn.getValue(b);

        int comparison;
        if (sortColumn.customSort != null) {
          comparison = sortColumn.customSort!(aValue, bValue);
        } else if (aValue is Comparable && bValue is Comparable) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }

        return _sortAscending.value ? comparison : -comparison;
      });
    }

    return filtered;
  }

  void _applySorting({required String? columnId, required bool ascending}) {
    _sortColumnId.value = columnId;
    _sortAscending.value = ascending;

    if (widget.paginated) {
      _currentPage.value = 0;
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  // Estructura para representar grupos jerárquicos
  List<_GroupNode<T>> get _groupedItems {
    if (_groupedByColumns.value.isEmpty) {
      return [_GroupNode(path: [], items: _filteredItems)];
    }

    return _buildGroupHierarchy(_filteredItems, 0, []);
  }

  List<_GroupNode<T>> _buildGroupHierarchy(
      List<T> items, int columnIndex, List<String> parentPath) {
    if (columnIndex >= _groupedByColumns.value.length) {
      return [_GroupNode(path: parentPath, items: items)];
    }

    final columnId = _groupedByColumns.value[columnIndex];
    final column = widget.columns.firstWhere((col) => col.id == columnId);

    final Map<String, List<T>> grouped = {};
    for (var item in items) {
      final value = column.getValue(item);
      final key = column.groupFormatter != null
          ? column.groupFormatter!(value)
          : (value?.toString() ?? '(Vacío)');
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final List<_GroupNode<T>> nodes = [];
    for (var entry in grouped.entries) {
      final currentPath = [...parentPath, entry.key];
      final subGroups = _buildGroupHierarchy(entry.value, columnIndex + 1, currentPath);
      nodes.add(_GroupNode(
        path: currentPath,
        items: entry.value,
        children: subGroups.length > 1 ? subGroups : null,
        columnLabel: column.label,
      ));
    }

    return nodes;
  }

  List<T> get _paginatedItems {
    if (_groupedByColumns.value.isNotEmpty) {
      // Si hay agrupamiento activo, no paginar
      return _filteredItems;
    }
    if (!widget.paginated) return _filteredItems;

    final startIndex = _currentPage.value * widget.itemsPerPage;
    final endIndex = startIndex + widget.itemsPerPage;

    if (startIndex >= _filteredItems.length) return [];

    return _filteredItems.sublist(
      startIndex,
      endIndex > _filteredItems.length ? _filteredItems.length : endIndex,
    );
  }

  int get _totalPages {
    if (!widget.paginated) return 1;
    return (_filteredItems.length / widget.itemsPerPage).ceil();
  }

  void _toggleSelection(T item) {
    final currentSelection = Set<T>.from(_selectedItems.value);

    if (widget.multiSelect) {
      if (currentSelection.contains(item)) {
        currentSelection.remove(item);
      } else {
        currentSelection.add(item);
      }
    } else {
      if (currentSelection.contains(item)) {
        currentSelection.clear();
      } else {
        currentSelection.clear();
        currentSelection.add(item);
      }
    }

    _selectedItems.value = currentSelection;
    widget.onSelectionChanged?.call(_selectedItems.value);
  }

  Future<void> _exportSelected(String format) async {
    final itemsToExport =
        _selectedItems.value.isNotEmpty ? _selectedItems.value.toList() : _filteredItems;
    final headers = _visibleColumns.map((c) => c.label).toList();
    final data = itemsToExport.map((item) {
      return _visibleColumns.map((c) => c.getValue(item)).toList();
    }).toList();

    final fileName = widget.exportFileName;

    try {
      switch (format) {
        case 'pdf':
          await ExportUtils.exportToPdf(
            headers: headers,
            data: data,
            fileName: fileName,
            title: fileName,
          );
          break;
        case 'excel':
          await ExportUtils.exportToExcel(
            headers: headers,
            data: data,
            fileName: fileName,
          );
          break;
        case 'csv':
          await ExportUtils.exportToCsv(
            headers: headers,
            data: data,
            fileName: fileName,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo exportado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _columnWidths,
        builder: (context, colWidths, child) {
          return ValueListenableBuilder<List<String>>(
            valueListenable: _groupedByColumns,
            builder: (context, groupedColumns, _) {
              final hasGrouping = groupedColumns.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con búsqueda y acciones (fuera del scroll)
                  if (widget.showSearch || widget.headerActions != null) _buildHeader(),

                  // Chips de agrupamiento activo (fuera del scroll)
                  if (_groupedByColumns.value.isNotEmpty) _buildGroupingChips(),

                  // Chips de filtros activos (fuera del scroll)
                  if (_activeFilters.value.values.any((v) => v.isNotEmpty))
                    _buildActiveFiltersChips(),

                  // Contador de items (fuera del scroll)
                  if (widget.showItemCount) _buildItemCounter(),

                  // Tabla con CustomScrollView (optimizado con Slivers)
                  Flexible(
                    child: Container(
                      constraints: widget.maxHeight != null
                          ? BoxConstraints(maxHeight: widget.maxHeight!)
                          : null,
                      decoration: BoxDecoration(
                        color: AppTheme.cardsColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.darkGreyColor.withValues(alpha: 0.2)),
                      ),
                      child: _filteredItems.isEmpty
                          ? _buildEmptyState()
                          : _buildSliverTable(hasGrouping),
                    ),
                  ),

                  // Paginación (fuera del scroll)
                  if (widget.paginated &&
                      _groupedByColumns.value.isEmpty &&
                      _totalPages > 1)
                    _buildPagination(),
                ],
              );
            },
          );
        });
  }

  /// Construcción de tabla optimizada con Slivers
  Widget _buildSliverTable(bool hasGrouping) {
    // 🔧 Envolver todo en un SingleChildScrollView horizontal
    return RawScrollbar(
      controller: _horizontalScrollController,
      thumbColor: widget.selectedRowColor ?? AppTheme.primaryColor.withValues(alpha: 0.7),
      thumbVisibility: true,
      radius: const Radius.circular(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: _totalColumnsWidth + 20, // Ancho fijo de la tabla completa
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Header de columnas (sticky con SliverPersistentHeader)
              _buildStickyTableHeader(),

              // Contenido de la tabla
              if (hasGrouping) ..._buildGroupedSlivers() else _buildSimpleSlivers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        children: [
          // Búsqueda
          if (widget.showSearch)
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.text = '';
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
                onChanged: (value) {
                  // Debounce: cancela el timer anterior y crea uno nuevo
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                    if (!mounted) return;
                    _currentPage.value = 0; // Reset a primera página
                    setState(() {});
                  });
                },
              ),
            ),

          // Botón de filtros
          const SizedBox(width: AppTheme.spacingSmall),
          ValueListenableBuilder<Map<String, Set<dynamic>>>(
            valueListenable: _activeFilters,
            builder: (context, filters, _) {
              final hasActiveFilters = filters.values.any((v) => v.isNotEmpty);
              return IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  label: Text(
                      '${filters.values.fold<int>(0, (sum, set) => sum + set.length)}'),
                  child: Icon(
                    hasActiveFilters ? Icons.filter_list : Icons.filter_list_outlined,
                    color: hasActiveFilters ? AppTheme.primaryColor : null,
                  ),
                ),
                tooltip: 'Filtros',
                onPressed: _showFiltersDialog,
              );
            },
          ),

          // Botón de configuración de columnas
          IconButton(
            icon: Badge(
                isLabelVisible: _hiddenColumns.value.isNotEmpty,
                label: Text('${_hiddenColumns.value.length}'),
                child: const Icon(Icons.view_column)),
            tooltip: 'Configurar columnas',
            onPressed: _showColumnConfigDialog,
          ),

          // Acciones
          if (widget.headerActions != null) ...[
            const SizedBox(width: AppTheme.spacingMedium),
            ...widget.headerActions!,
          ],
        ],
      ),
    );
  }

  Widget _buildGroupingChips() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _groupedByColumns,
      builder: (context, groupedColumns, _) {
        if (groupedColumns.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_work,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agrupado por:',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...groupedColumns.asMap().entries.map((entry) {
                final index = entry.key;
                final columnId = entry.value;
                final column = widget.columns.firstWhere((col) => col.id == columnId);

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(column.label),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    final updated = List<String>.from(groupedColumns);
                    updated.removeAt(index);
                    _groupedByColumns.value = updated;
                  },
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpiar todo'),
                onPressed: () {
                  _groupedByColumns.value = [];
                },
                backgroundColor: AppTheme.darkGreyColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppTheme.darkGreyColor,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.close_fullscreen, size: 16),
                label: const Text('Minimizar todo'),
                onPressed: () {
                  final updated = Map<String, bool>.from(_groupExpanded.value);
                  updated.updateAll((key, value) => false);
                  _groupExpanded.value = updated;
                },
                backgroundColor: AppTheme.darkGreyColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppTheme.darkGreyColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCounter() {
    return ValueListenableBuilder<Set<T>>(
      valueListenable: _selectedItems,
      builder: (context, selectedItems, _) {
        final selectedCount = selectedItems.length;
        final totalCount = _filteredItems.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: Row(
            children: [
              Text(
                selectedCount > 0
                    ? '$selectedCount seleccionado${selectedCount > 1 ? 's' : ''} de $totalCount'
                    : '$totalCount registro${totalCount != 1 ? 's' : ''}',
                style: AppTheme.bodySmallTextStyle.copyWith(
                  color: AppTheme.darkGreyColor,
                ),
              ),
              if (selectedCount > 0 && widget.multiSelect) ...[
                const SizedBox(width: AppTheme.spacingSmall),
                TextButton(
                  onPressed: () {
                    _selectedItems.value = {};
                    widget.onSelectionChanged?.call(_selectedItems.value);
                  },
                  child: const Text('Limpiar selección'),
                ),
              ],
              if (selectedCount > 0 && widget.multiSelect) ...[
                const SizedBox(width: AppTheme.spacingSmall),
                ...widget.selectablesActions,
                const SizedBox(width: AppTheme.spacingSmall),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.download, color: AppTheme.primaryColor),
                  tooltip: 'Exportar seleccionados',
                  onSelected: _exportSelected,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Exportar a PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excel',
                      child: Row(
                        children: [
                          Icon(Icons.table_view, color: AppTheme.secondaryColor),
                          SizedBox(width: 8),
                          Text('Exportar a Excel'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Exportar a CSV'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  /// Header de tabla sticky con SliverPersistentHeader
  Widget _buildStickyTableHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TableHeaderDelegate(
        minHeight: 48,
        maxHeight: 48,
        child: ValueListenableBuilder<Set<T>>(
          valueListenable: _selectedItems,
          builder: (context, selectedItems, _) {
            return Container(
              color: AppTheme.backgroundColor,
              height: 48,
              child: Row(
                children: [
                  // Checkbox de seleccionar todo (si es seleccionable)
                  if (widget.selectable)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(
                        value: selectedItems.length == _filteredItems.length &&
                            _filteredItems.isNotEmpty,
                        tristate: selectedItems.isNotEmpty &&
                            selectedItems.length < _filteredItems.length,
                        onChanged: (value) {
                          if (value == true) {
                            _selectedItems.value = Set.from(_filteredItems);
                          } else {
                            _selectedItems.value = {};
                          }
                          widget.onSelectionChanged?.call(_selectedItems.value);
                        },
                      ),
                    ),
                  // Columnas visibles
                  ..._visibleColumns.map((column) => _buildColumnHeader(column)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Header individual de columna
  Widget _buildColumnHeader(DataTableColumnConfig<T> column) {
    final isGrouped = _groupedByColumns.value.contains(column.id);
    final canSort = column.sortable;
    final isNum = _filteredItems.isNotEmpty &&
        _filteredItems.any((item) {
          final value = column.getValue(item);
          return value is num;
        });

    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: _columnWidths,
      builder: (context, widths, _) {
        final columnWidth = _getColumnWidth(column);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTapDown: (details) {
                _showColumnOptionsSheet(column, details.globalPosition);
              },
              child: Container(
                width: columnWidth - 8, // Restar espacio del divisor
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGrouped)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.group_work,
                          size: 16,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        column.label,
                        style: AppTheme.subtitlesTextStyle.copyWith(
                          fontSize: 15,
                          color:
                              isGrouped ? AppTheme.secondaryColor : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canSort || isNum) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _sortColumnId.value == column.id
                            ? (_sortAscending.value
                                ? Icons.arrow_upward
                                : Icons.arrow_downward)
                            : Icons.more_vert,
                        size: 18,
                        color: _sortColumnId.value == column.id
                            ? AppTheme.secondaryColor
                            : AppTheme.darkGreyColor,
                      ),
                    ]
                  ],
                ),
              ),
            ),
            // Divisor arrastrable para redimensionar
            _ColumnResizer(
              onResize: (delta) {
                _updateColumnWidth(column.id, _getColumnWidth(column) + delta);
              },
            ),
          ],
        );
      },
    );
  }

  /// Construcción de tabla simple con SliverList (optimizado)
  Widget _buildSimpleSlivers() {
    final itemsToShow = widget.paginated && _groupedByColumns.value.isEmpty
        ? _paginatedItems
        : _filteredItems;

    return ValueListenableBuilder<Set<T>>(
      valueListenable: _selectedItems,
      builder: (context, selectedItems, _) {
        return SliverFixedExtentList(
          itemExtent: widget.rowHeight,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildDataRow(itemsToShow[index], 0),
            childCount: itemsToShow.length,
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
          ),
        );
      },
    );
  }

  /// Construcción de tabla agrupada con Slivers (optimizado)
  List<Widget> _buildGroupedSlivers() {
    return [
      ValueListenableBuilder<Map<String, bool>>(
        valueListenable: _groupExpanded,
        builder: (context, expandedMap, _) {
          // Flatten de la jerarquía a lista plana para renderizado eficiente
          final flattenedItems = _flattenGroupHierarchy(_groupedItems, 0);

          return ValueListenableBuilder<Set<T>>(
            valueListenable: _selectedItems,
            builder: (context, selectedItems, _) {
              return SliverList.builder(
                itemCount: flattenedItems.length,
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                itemBuilder: (context, index) {
                  final sliverItem = flattenedItems[index];

                  if (sliverItem.isGroupHeader) {
                    return _buildGroupHeader(
                      sliverItem.groupName!,
                      sliverItem.columnLabel,
                      sliverItem.itemCount!,
                      sliverItem.depth,
                      sliverItem.groupPath!,
                      sliverItem.isExpanded!,
                    );
                  } else {
                    return _buildDataRow(sliverItem.item as T, sliverItem.depth);
                  }
                },
              );
            },
          );
        },
      ),
    ];
  }

  /// Flatten jerarquía de grupos a lista plana para Sliver
  List<_SliverItem<T>> _flattenGroupHierarchy(List<_GroupNode<T>> nodes, int depth,
      [String parentPath = '']) {
    // Usar cache si existe y no ha cambiado
    if (_cachedFlattenedItems != null && depth == 0) {
      return _cachedFlattenedItems!;
    }

    final List<_SliverItem<T>> result = [];

    for (var node in nodes) {
      final hasChildren = node.children != null && node.children!.length > 1;
      final groupPath =
          parentPath.isEmpty ? node.displayName : '$parentPath/${node.displayName}';

      // Inicializar estado de expansión si no existe (por defecto cerrado)
      final expandedMap = _groupExpanded.value;
      if (!expandedMap.containsKey(groupPath)) {
        final updated = Map<String, bool>.from(expandedMap);
        updated[groupPath] = false;
        _groupExpanded.value = updated;
      }
      final isExpanded = _groupExpanded.value[groupPath] ?? false;

      // Agregar header de grupo (si tiene nombre)
      if (node.displayName.isNotEmpty) {
        result.add(_SliverItem<T>(
          type: _SliverItemType.groupHeader,
          groupName: node.displayName,
          columnLabel: node.columnLabel,
          itemCount: node.items.length,
          depth: depth,
          groupPath: groupPath,
          isExpanded: isExpanded,
        ));
      }

      // Solo mostrar contenido si el grupo está expandido
      if (isExpanded) {
        // Si tiene hijos, procesar recursivamente
        if (hasChildren) {
          result.addAll(_flattenGroupHierarchy(node.children!, depth + 1, groupPath));
        } else {
          // Si no tiene hijos, agregar las filas de datos
          for (var item in node.items) {
            result.add(_SliverItem<T>(
              type: _SliverItemType.dataRow,
              item: item,
              depth: depth,
            ));
          }
        }
      }
    }

    // Cachear resultado si es el nivel raíz
    if (depth == 0) {
      _cachedFlattenedItems = result;
    }

    return result;
  }

  /// Método auxiliar para encontrar un nodo de grupo por su path completo
  _GroupNode<T>? _findGroupNodeByPath(List<_GroupNode<T>> nodes, String groupPath) {
    for (var node in nodes) {
      // Construir el path completo del nodo
      final nodePath = node.path.join('/');

      if (nodePath == groupPath) {
        return node;
      }

      // Buscar recursivamente en los hijos
      if (node.children != null) {
        final found = _findGroupNodeByPath(node.children!, groupPath);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /// Widget de header de grupo
  Widget _buildGroupHeader(String groupName, String? columnLabel, int itemCount,
      int depth, String groupPath, bool isExpanded) {
    final indentation = depth * 16.0;

    // Encontrar items del grupo actual para calcular agregados usando el path completo
    final groupNode = _findGroupNodeByPath(_groupedItems, groupPath);
    final groupItems = groupNode?.items ?? [];

    // Calcular agregados para columnas numéricas visibles
    final aggregates = <String, Map<String, double>>{};
    if (groupItems.isNotEmpty) {
      for (var column in _visibleColumns) {
        final numericValues =
            groupItems.map((item) => column.getValue(item)).whereType<num>().toList();

        if (numericValues.isNotEmpty) {
          final sum =
              numericValues.fold<double>(0.0, (prev, val) => prev + val.toDouble());
          final avg = sum / numericValues.length;
          final min = numericValues.reduce((a, b) => a < b ? a : b).toDouble();
          final max = numericValues.reduce((a, b) => a > b ? a : b).toDouble();

          aggregates[column.id] = {
            'sum': sum,
            'avg': avg,
            'min': min,
            'max': max,
          };
        }
      }
    }

    return ValueListenableBuilder<Map<String, double>>(
        valueListenable: _columnWidths,
        builder: (context, value, child) {
          return InkWell(
            onTap: () {
              final updated = Map<String, bool>.from(_groupExpanded.value);
              updated[groupPath] = !isExpanded;
              _groupExpanded.value = updated;
            },
            child: Container(
              padding: EdgeInsets.only(
                left: AppTheme.spacingMedium + indentation,
                right: AppTheme.spacingMedium,
                top: AppTheme.spacingSmall,
                bottom: AppTheme.spacingSmall,
              ),
              color: AppTheme.secondaryColor.withValues(alpha: 0.1 - (depth * 0.02)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Botón de expandir/colapsar
                      Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 24,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 4),

                      //selector de grupo
                      if (widget.selectable)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Checkbox(
                            value: groupItems.isNotEmpty &&
                                groupItems
                                    .every((item) => _selectedItems.value.contains(item)),
                            onChanged: (value) {
                              final updated = Set<T>.from(_selectedItems.value);
                              if (value == true) {
                                updated.addAll(groupItems);
                              } else {
                                updated.removeAll(groupItems);
                              }
                              _selectedItems.value = updated;
                              widget.onSelectionChanged?.call(_selectedItems.value);
                            },
                          ),
                        ),

                      // Indicadores de profundidad
                      ...List.generate(
                        depth,
                        (_) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.subdirectory_arrow_right,
                            size: 16,
                            color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.folder_open : Icons.folder,
                        size: 20,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      if (columnLabel != null) ...[
                        Text(
                          '$columnLabel: ',
                          style: AppTheme.bodySmallTextStyle.copyWith(
                            color: AppTheme.darkGreyColor,
                          ),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          groupName,
                          style: AppTheme.subtitlesTextStyle.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$itemCount',
                          style: AppTheme.bodySmallTextStyle.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Mostrar agregados si hay columnas numéricas
                  if (aggregates.isNotEmpty && isExpanded) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.selectable ? 64.0 : 16.0,
                      ),
                      child: Wrap(
                        spacing: AppTheme.spacingSmall,
                        runSpacing: 4,
                        children: aggregates.entries.map((entry) {
                          final columnId = entry.key;
                          final stats = entry.value;
                          final column =
                              _visibleColumns.firstWhere((c) => c.id == columnId);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.successColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${column.label}: Suma: ${stats['sum']!.toStringAsFixed(1)} | Prom: ${stats['avg']!.toStringAsFixed(1)}',
                              style: AppTheme.bodySmallTextStyle.copyWith(
                                color: AppTheme.successColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        });
  }

  /// Widget de fila de datos individual (optimizado para Sliver)
  Widget _buildDataRow(T item, int depth) {
    final isSelected = _selectedItems.value.contains(item);
    final indentation = depth * 16.0;

    return ValueListenableBuilder<Map<String, double>>(
        valueListenable: _columnWidths,
        builder: (context, widths, _) {
          return InkWell(
            onTap: widget.selectable ? () => _toggleSelection(item) : null,
            child: Container(
              height: widget.rowHeight,
              padding: EdgeInsets.only(left: indentation),
              decoration: BoxDecoration(
                color: isSelected
                    ? (widget.selectedRowColor ??
                        AppTheme.secondaryColor.withValues(alpha: 0.15))
                    : null,
              ),
              child: Row(
                children: [
                  // Checkbox de selección
                  if (widget.selectable)
                    SizedBox(
                      width: 48,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(item),
                      ),
                    ),
                  // Celdas de datos visibles
                  ..._visibleColumns.map((column) => _buildDataCell(item, column)),
                ],
              ),
            ),
          );
        });
  }

  /// Widget de celda individual
  Widget _buildDataCell(T item, DataTableColumnConfig<T> column) {
    final value = column.getValue(item);
    Widget cellContent;

    if (column.builder != null) {
      cellContent = (column.builder!(item, value));
    } else {
      cellContent = Text(
        value?.toString() ?? '',
        style: AppTheme.bodyTextStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Wrap en InkWell si hay onTap
    if (column.onTap != null) {
      cellContent = InkWell(
        onTap: () => column.onTap!(item, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: cellContent,
        ),
      );
    }

    return Container(
      width: _getColumnWidth(column), // 🔧 Usar ancho personalizado o default
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: cellContent,
    );
  }

  void _showColumnOptionsSheet(DataTableColumnConfig<T> column, Offset position) {
    // Verificar si la columna tiene valores numéricos
    final hasNumericValues = _filteredItems.isNotEmpty &&
        _filteredItems.any((item) {
          final value = column.getValue(item);
          return value is num;
        });

    // Calcular estadísticas si es numérico
    double? sum;
    double? average;
    if (hasNumericValues) {
      final numericValues =
          _filteredItems.map((item) => column.getValue(item)).whereType<num>().toList();

      if (numericValues.isNotEmpty) {
        sum = numericValues.fold<double>(0.0, (prev, val) => prev + val.toDouble());
        average = sum / numericValues.length;
      }
    }

    final isSortedByThis = _sortColumnId.value == column.id;

    // Construir items del menú
    final List<PopupMenuEntry<String>> menuItems = [];

    // Opciones de ordenamiento
    if (column.sortable) {
      menuItems.addAll([
        PopupMenuItem<String>(
          value: 'sort_asc',
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 20,
                color: isSortedByThis && _sortAscending.value
                    ? AppTheme.secondaryColor
                    : AppTheme.darkGreyColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  'Ascendente (A-Z, 0-9)',
                  style: TextStyle(
                    color: isSortedByThis && _sortAscending.value
                        ? AppTheme.secondaryColor
                        : AppTheme.typographyColor,
                    fontWeight: isSortedByThis && _sortAscending.value
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSortedByThis && _sortAscending.value)
                Icon(Icons.check, size: 20, color: AppTheme.secondaryColor),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_desc',
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: isSortedByThis && !_sortAscending.value
                    ? AppTheme.secondaryColor
                    : AppTheme.darkGreyColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  'Descendente (Z-A, 9-0)',
                  style: TextStyle(
                    color: isSortedByThis && !_sortAscending.value
                        ? AppTheme.secondaryColor
                        : AppTheme.typographyColor,
                    fontWeight: isSortedByThis && !_sortAscending.value
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSortedByThis && !_sortAscending.value)
                Icon(Icons.check, size: 20, color: AppTheme.secondaryColor),
            ],
          ),
        ),
      ]);

      if (isSortedByThis) {
        menuItems.add(
          PopupMenuItem<String>(
            value: 'clear_sort',
            child: Row(
              children: [
                Icon(
                  Icons.clear,
                  size: 20,
                  color: AppTheme.darkGreyColor,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                const Text('Limpiar ordenamiento'),
              ],
            ),
          ),
        );
      }
    }

    // Estadísticas numéricas
    if (hasNumericValues && (sum != null || average != null)) {
      if (menuItems.isNotEmpty) {
        menuItems.add(const PopupMenuDivider());
      }

      if (sum != null) {
        menuItems.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppTheme.acentosColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      'Suma total',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.darkGreyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    sum.toStringAsFixed(2),
                    style: AppTheme.subtitlesTextStyle.copyWith(
                      color: AppTheme.acentosColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (average != null) {
        menuItems.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 18,
                      color: AppTheme.acentosColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      'Promedio',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.darkGreyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    average.toStringAsFixed(2),
                    style: AppTheme.subtitlesTextStyle.copyWith(
                      color: AppTheme.acentosColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Opción de agrupar/desagrupar
    final isGrouped = _groupedByColumns.value.contains(column.id);
    if (menuItems.isNotEmpty) {
      menuItems.add(const PopupMenuDivider());
    }

    if (isGrouped) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'ungroup',
          child: Row(
            children: [
              Icon(
                Icons.layers_clear,
                size: 20,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text('Desagrupar ${column.label}'),
            ],
          ),
        ),
      );
    } else {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'group_by',
          child: Row(
            children: [
              Icon(
                Icons.group_work,
                size: 20,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text('Agrupar por ${column.label}'),
            ],
          ),
        ),
      );
    }

    // Opciones de redimensionamiento (solo si tiene sentido según límites)
    final currentWidth = _getColumnWidth(column);
    final canExpand = currentWidth + 120 <= 500; // Límite máximo
    final canMinimize = currentWidth - 120 >= 80; // Límite mínimo

    if (canExpand || canMinimize) {
      if (menuItems.isNotEmpty) {
        menuItems.add(const PopupMenuDivider());
      }
    }

    if (canExpand) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'expandir',
          child: Row(
            children: [
              Icon(
                Icons.width_wide,
                size: 20,
                color: AppTheme.acentosColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text('Expandir ancho'),
            ],
          ),
        ),
      );
    }

    if (canMinimize) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'minimizar',
          child: Row(
            children: [
              Icon(
                Icons.close_fullscreen,
                size: 20,
                color: AppTheme.acentosColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text('Minimizar ancho'),
            ],
          ),
        ),
      );
    }

    if (menuItems.isNotEmpty) {
      menuItems.add(const PopupMenuDivider());
    }

    menuItems.add(
      PopupMenuItem<String>(
        value: 'ocultar',
        child: Row(
          children: [
            Icon(
              Icons.disabled_visible_sharp,
              size: 20,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text('Ocultar ${column.label}'),
          ],
        ),
      ),
    );

    if (menuItems.isEmpty) return;

    // Mostrar menú
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).then((value) {
      if (value == null) return;

      if (!mounted) return;

      switch (value) {
        case 'sort_asc':
          _applySorting(columnId: column.id, ascending: true);
          break;
        case 'sort_desc':
          _applySorting(columnId: column.id, ascending: false);
          break;
        case 'clear_sort':
          _applySorting(columnId: null, ascending: true);
          break;
        case 'group_by':
          if (!_groupedByColumns.value.contains(column.id)) {
            final updated = List<String>.from(_groupedByColumns.value);
            updated.add(column.id);
            _groupedByColumns.value = updated;
          }
          break;
        case 'ungroup':
          final updated = List<String>.from(_groupedByColumns.value);
          updated.remove(column.id);
          _groupedByColumns.value = updated;
          break;
        case 'expandir':
          final currentWidth = _getColumnWidth(column);
          _updateColumnWidth(column.id, currentWidth + 120);
          break;
        case 'minimizar':
          final currentWidth = _getColumnWidth(column);
          _updateColumnWidth(column.id, currentWidth - 120);
          break;
        case 'ocultar':
          // Verificar que quede al menos 1 columna visible
          if (_visibleColumns.length > 1) {
            setState(() {
              final updated = Set<String>.from(_hiddenColumns.value);
              updated.add(column.id);
              _hiddenColumns.value = updated;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debe haber al menos una columna visible'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          break;
      }
    });
  }

  Widget _buildActiveFiltersChips() {
    return ValueListenableBuilder<Map<String, Set<dynamic>>>(
      valueListenable: _activeFilters,
      builder: (context, filters, _) {
        if (filters.isEmpty || filters.values.every((v) => v.isEmpty)) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filtros activos:',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...filters.entries.expand((entry) {
                final columnId = entry.key;
                final values = entry.value;

                if (values.isEmpty) return <Widget>[];

                final column = widget.columns.firstWhereOrNull((c) => c.id == columnId);
                if (column == null) return <Widget>[];

                return values.map((value) {
                  return Chip(
                    avatar: Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    label: Text('${column.label}: ${value.toString()}'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      final updated =
                          Map<String, Set<dynamic>>.from(_activeFilters.value);
                      updated[columnId]?.remove(value);
                      if (updated[columnId]?.isEmpty ?? false) {
                        updated.remove(columnId);
                      }
                      _activeFilters.value = updated;
                    },
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                });
              }),
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpiar filtros'),
                onPressed: () {
                  _activeFilters.value = {};
                },
                backgroundColor: AppTheme.darkGreyColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppTheme.darkGreyColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => _FiltersDialog<T>(
        columns: widget.columns,
        items: widget.items,
        activeFilters: _activeFilters.value,
        onApply: (filters) {
          setState(() {
            _activeFilters.value = filters;
            _currentPage.value = 0;
          });
        },
      ),
    );
  }

  void _showColumnConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => _ColumnConfigDialog<T>(
        columns: widget.columns,
        hiddenColumns: _hiddenColumns.value,
        columnOrder: _columnOrder.value,
        onApply: (hidden, order) {
          setState(() {
            _hiddenColumns.value = hidden;
            _columnOrder.value = order;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (widget.emptyWidget != null) return widget.emptyWidget!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.darkGreyColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              widget.emptyMessage,
              style: AppTheme.subtitlesTextStyle.copyWith(
                color: AppTheme.darkGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, currentPage, _) {
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0 ? () => _currentPage.value-- : null,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Página ${currentPage + 1} de $_totalPages',
                style: AppTheme.bodyTextStyle,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    currentPage < _totalPages - 1 ? () => _currentPage.value++ : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Configuración de una columna de la tabla
class DataTableColumnConfig<T> {
  /// Identificador único de la columna
  final String id;

  /// Etiqueta a mostrar en el header
  final String label;

  /// Función para obtener el valor de esta columna para un item
  final dynamic Function(T) getValue;

  /// Widget builder personalizado para la celda
  /// Si no se provee, se usa Text(getValue(item).toString())
  final Widget Function(T item, dynamic value)? builder;

  /// Callback cuando se hace clic en una celda
  final void Function(T item, dynamic value)? onTap;

  /// Si la columna es ordenable
  final bool sortable;

  /// Función de ordenamiento personalizada
  final int Function(dynamic a, dynamic b)? customSort;

  /// Ancho fijo de la columna (opcional)
  final double? width;

  /// Función para formatear el valor cuando se agrupa por esta columna
  /// Si no se provee, se usa toString() del valor
  final String Function(dynamic value)? groupFormatter;

  const DataTableColumnConfig({
    required this.id,
    required this.label,
    required this.getValue,
    this.builder,
    this.onTap,
    this.sortable = false,
    this.customSort,
    this.width,
    this.groupFormatter,
  });
}

/// Nodo para representar grupos jerárquicos
class _GroupNode<T> {
  final List<String> path;
  final List<T> items;
  final List<_GroupNode<T>>? children;
  final String? columnLabel;

  _GroupNode({
    required this.path,
    required this.items,
    this.children,
    this.columnLabel,
  });

  String get displayName => path.isNotEmpty ? path.last : '';
  int get level => path.length;
}

/// Item para renderizado en Sliver (flatten de jerarquía)
enum _SliverItemType { groupHeader, dataRow }

class _SliverItem<T> {
  final _SliverItemType type;
  final T? item; // Para dataRow
  final String? groupName; // Para groupHeader
  final String? columnLabel; // Para groupHeader
  final int? itemCount; // Para groupHeader
  final int depth; // Profundidad de indentación
  final String? groupPath; // Path único del grupo para controlar expansión
  final bool? isExpanded; // Estado de expansión del grupo

  const _SliverItem({
    required this.type,
    this.item,
    this.groupName,
    this.columnLabel,
    this.itemCount,
    this.depth = 0,
    this.groupPath,
    this.isExpanded,
  });

  bool get isGroupHeader => type == _SliverItemType.groupHeader;
  bool get isDataRow => type == _SliverItemType.dataRow;
}

/// Dialog para configurar filtros de columnas
class _FiltersDialog<T> extends StatefulWidget {
  final List<DataTableColumnConfig<T>> columns;
  final List<T> items;
  final Map<String, Set<dynamic>> activeFilters;
  final Function(Map<String, Set<dynamic>>) onApply;

  const _FiltersDialog({
    required this.columns,
    required this.items,
    required this.activeFilters,
    required this.onApply,
  });

  @override
  State<_FiltersDialog<T>> createState() => _FiltersDialogState<T>();
}

class _FiltersDialogState<T> extends State<_FiltersDialog<T>> {
  late Map<String, Set<dynamic>> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, Set<dynamic>>.from(
      widget.activeFilters.map((key, value) => MapEntry(key, Set.from(value))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.filter_list, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingSmall),
          const Text('Filtros de columnas'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.separated(
          itemCount: widget.columns.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final column = widget.columns[index];
            final uniqueValues = widget.items
                .map((item) => column.getValue(item))
                .where((v) => v != null)
                .toSet()
                .take(100)
                .toList();

            if (uniqueValues.isEmpty) return const SizedBox.shrink();

            uniqueValues.sort((a, b) => a.toString().compareTo(b.toString()));

            final selectedValues = _filters[column.id] ?? {};

            return ExpansionTile(
              title: Text(
                column.label,
                style: AppTheme.subtitlesTextStyleBlack,
              ),
              subtitle: selectedValues.isNotEmpty
                  ? Text(
                      '${selectedValues.length} seleccionado${selectedValues.length > 1 ? 's' : ''}',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Todos'),
                            onPressed: () {
                              setState(() {
                                _filters[column.id] = Set.from(uniqueValues);
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.deselect, size: 16),
                            label: const Text('Ninguno'),
                            onPressed: () {
                              setState(() {
                                _filters.remove(column.id);
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...uniqueValues.map((value) {
                        final valueStr = value.toString();
                        final isSelected = selectedValues.contains(value);

                        return CheckboxListTile(
                          dense: true,
                          title: Text(valueStr),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (!_filters.containsKey(column.id)) {
                                _filters[column.id] = {};
                              }
                              if (checked == true) {
                                _filters[column.id]!.add(value);
                              } else {
                                _filters[column.id]!.remove(value);
                                if (_filters[column.id]!.isEmpty) {
                                  _filters.remove(column.id);
                                }
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _filters.clear();
            });
          },
          child: const Text('Limpiar todo'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_filters);
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

/// Dialog para configurar visibilidad y orden de columnas
class _ColumnConfigDialog<T> extends StatefulWidget {
  final List<DataTableColumnConfig<T>> columns;
  final Set<String> hiddenColumns;
  final List<String> columnOrder;
  final Function(Set<String>, List<String>) onApply;

  const _ColumnConfigDialog({
    required this.columns,
    required this.hiddenColumns,
    required this.columnOrder,
    required this.onApply,
  });

  @override
  State<_ColumnConfigDialog<T>> createState() => _ColumnConfigDialogState<T>();
}

class _ColumnConfigDialogState<T> extends State<_ColumnConfigDialog<T>> {
  late Set<String> _hidden;
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _hidden = Set.from(widget.hiddenColumns);
    _order = List.from(widget.columnOrder);
  }

  int get _visibleCount => widget.columns.length - _hidden.length;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.view_column, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingSmall),
          const Text('Configurar columnas'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      '$_visibleCount de ${widget.columns.length} columnas visibles (mínimo 1)',
                      style: AppTheme.bodySmallTextStyle.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Arrastra para reordenar',
              style: AppTheme.bodySmallTextStyle.copyWith(
                color: AppTheme.darkGreyColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _order.removeAt(oldIndex);
                    _order.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final columnId = _order[index];
                  final column = widget.columns.firstWhere((c) => c.id == columnId);
                  final isHidden = _hidden.contains(columnId);
                  final canHide = _visibleCount > 1 || isHidden;

                  return Padding(
                    key: ValueKey(columnId),
                    padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingSmall, right: AppTheme.spacingLarge),
                    child: CheckboxListTile(
                      title: Text(column.label),
                      subtitle: isHidden ? const Text('Oculta') : null,
                      value: !isHidden,
                      controlAffinity: ListTileControlAffinity.leading,
                      enabled: canHide,
                      onChanged: canHide
                          ? (checked) {
                              setState(() {
                                if (checked == true) {
                                  _hidden.remove(columnId);
                                } else {
                                  _hidden.add(columnId);
                                }
                              });
                            }
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _hidden.clear();
              _order = widget.columns.map((c) => c.id).toList();
            });
          },
          child: const Text('Restablecer'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_hidden, _order);
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

/// Delegate para hacer el header sticky con SliverPersistentHeader
class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _TableHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_TableHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

/// Estados del divisor de redimensionamiento de columna
enum _ResizerState { idle, hovering, dragging }

/// Widget divisor arrastrable para redimensionar columnas
class _ColumnResizer extends StatefulWidget {
  final Function(double delta) onResize;

  const _ColumnResizer({required this.onResize});

  @override
  State<_ColumnResizer> createState() => _ColumnResizerState();
}

class _ColumnResizerState extends State<_ColumnResizer> {
  _ResizerState _state = _ResizerState.idle;
  double _pendingDelta = 0;
  bool _resizeScheduled = false;

  static const double _dragSensitivity = 3;

  static const double _minDeltaToApply = 0.35;

  void _scheduleResizeFlush() {
    if (_resizeScheduled) return;

    _resizeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resizeScheduled = false;

      if (!mounted) return;

      _flushPendingResize();
    });
  }

  void _flushPendingResize() {
    if (_pendingDelta.abs() < _minDeltaToApply) {
      _pendingDelta = 0;
      return;
    }

    widget.onResize(_pendingDelta);
    _pendingDelta = 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _state = _ResizerState.hovering),
      onExit: (_) => setState(() {
        if (_state != _ResizerState.dragging) {
          _state = _ResizerState.idle;
        }
      }),
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _pendingDelta = 0;
          _resizeScheduled = false;
          setState(() {
            _state = _ResizerState.dragging;
          });
        },
        onHorizontalDragUpdate: (details) {
          final adjustedDelta = details.delta.dx * _dragSensitivity;
          _pendingDelta += adjustedDelta;
          _scheduleResizeFlush();
        },
        onHorizontalDragEnd: (_) {
          // _resizeScheduled = false;
          // _flushPendingResize();
          setState(() {
            _state = _ResizerState.idle;
          });
        },
        child: Container(
          width: 8,
          height: 48,
          color: _state == _ResizerState.dragging
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : (_state == _ResizerState.hovering
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent),
          child: Center(
            child: Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: _state != _ResizerState.idle
                    ? AppTheme.primaryColor
                    : AppTheme.darkGreyColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
