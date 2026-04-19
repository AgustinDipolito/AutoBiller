import 'package:dist_v2/models/stock.dart';
import 'package:dist_v2/models/stock_alert.dart';
import 'package:dist_v2/services/stock_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Dedicated page for viewing and managing stock alerts
class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  final _searchController = TextEditingController();
  String _selectedLevel = 'all'; // 'all', 'critical', 'warning'
  StockType? _selectedType;
  Proveedor? _selectedProvider;
  List<StockAlert> _filteredAlerts = [];
  Set<StockAlert> _selectedAlerts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final stockAnalysisService =
        Provider.of<StockAnalysisService>(context, listen: false);
    var alerts = stockAnalysisService.alerts;

    // Filter by level
    if (_selectedLevel == 'critical') {
      alerts = alerts.where((a) => a.isCritical).toList();
    } else if (_selectedLevel == 'warning') {
      alerts = alerts.where((a) => a.isWarning).toList();
    }

    // Filter by type
    if (_selectedType != null) {
      alerts = alerts.where((a) => a.stockItem.type == _selectedType).toList();
    }

    // Filter by provider
    if (_selectedProvider != null) {
      alerts = alerts.where((a) => a.stockItem.proveedor == _selectedProvider).toList();
    }

    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      alerts =
          alerts.where((a) => a.stockItem.name.toLowerCase().contains(query)).toList();
    }

    setState(() {
      _filteredAlerts = alerts;
      // Clear selection when filters change
      _selectedAlerts.clear();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedLevel = 'all';
      _selectedType = null;
      _selectedProvider = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  int _roundToStandardRange(int value) {
    const ranges = [0, 1, 5, 10, 15, 20, 25, 50, 100];

    for (int range in ranges) {
      if (value <= range) return range;
    }

    // Si es mayor a 100, redondear a múltiplos de 50
    return ((value / 50).ceil() * 50);
  }

  Future<void> _exportSingleItem(StockAlert alert) async {
    final deficit = alert.deficit;
    final rounded = _roundToStandardRange(deficit);

    final text = '${alert.stockItem.name}: $rounded';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copiado: $text'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportAll() async {
    final buffer = StringBuffer();

    // Usar selección si hay alertas seleccionadas, sino usar filtradas
    final alertsToExport =
        _selectedAlerts.isEmpty ? _filteredAlerts : _selectedAlerts.toList();

    // Agrupar por proveedor
    final Map<Proveedor, List<StockAlert>> alertsByProvider = {};
    for (final alert in alertsToExport) {
      alertsByProvider.putIfAbsent(alert.stockItem.proveedor, () => []).add(alert);
    }

    // Ordenar proveedores alfabéticamente
    final sortedProviders = alertsByProvider.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    // Generar texto organizado por proveedor
    for (final proveedor in sortedProviders) {
      final alerts = alertsByProvider[proveedor]!;

      // Encabezado del proveedor
      buffer.writeln('--- ${proveedor.toString().split('.').last.toUpperCase()} ---');

      // Items del proveedor
      for (final alert in alerts) {
        final deficit = alert.deficit;
        final rounded = _roundToStandardRange(deficit);
        buffer.writeln('${alert.stockItem.name}: $rounded');
      }

      buffer.writeln(); // Línea en blanco entre proveedores
    }

    final text = buffer.toString().trim();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      final selectionText =
          _selectedAlerts.isEmpty ? '' : ' (${_selectedAlerts.length} seleccionados)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${alertsToExport.length} items copiados$selectionText (${sortedProviders.length} proveedores)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedAlerts.length == _filteredAlerts.length) {
        // Deseleccionar todas
        _selectedAlerts.clear();
      } else {
        // Seleccionar todas las filtradas
        _selectedAlerts = Set.from(_filteredAlerts);
      }
    });
  }

  void _toggleSelection(StockAlert alert) {
    setState(() {
      if (_selectedAlerts.contains(alert)) {
        _selectedAlerts.remove(alert);
      } else {
        _selectedAlerts.add(alert);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockAnalysisService = Provider.of<StockAnalysisService>(context);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: _selectedAlerts.isEmpty
            ? const Text('Alertas de Stock Bajo')
            : Text('${_selectedAlerts.length} seleccionados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reanalizar',
            color: Colors.black,
            onPressed: () async {
              await stockAnalysisService.analyzeStockLevels();
              _applyFilters();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => _applyFilters(),
                    ),
                  ),
                ),
                if (_filteredAlerts.isNotEmpty) ...[
                  IconButton(
                    color: Colors.black,
                    icon: Icon(
                      _selectedAlerts.length == _filteredAlerts.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    tooltip: _selectedAlerts.length == _filteredAlerts.length
                        ? 'Deseleccionar todas'
                        : 'Seleccionar todas',
                    onPressed: _toggleSelectAll,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.copy_all),
                  tooltip: 'Copiar todo',
                  onPressed: _exportAll,
                ),
              ],
            ),

            // Filters
            _buildFilters(stockAnalysisService),

            const Divider(height: 1),

            // Alerts list
            Expanded(
              child: stockAnalysisService.isAnalyzing
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAlerts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = _filteredAlerts[index];
                            return _buildAlertCard(alert);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(StockAnalysisService service) {
    final hasActiveFilters =
        _selectedLevel != 'all' || _selectedType != null || _selectedProvider != null;
    final critical = service.alerts.where((a) => a.isCritical).length;
    final warning = service.alerts.where((a) => a.isWarning).length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Level filter
            ChoiceChip(
              label: const Text('Todos'),
              showCheckmark: false,
              avatar: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade700,
                child: Text(
                  '${service.alerts.length}',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
              selected: _selectedLevel == 'all',
              onSelected: (selected) {
                setState(() => _selectedLevel = 'all');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Text('Crítico ($critical)'),
                ],
              ),
              selected: _selectedLevel == 'critical',
              selectedColor: Colors.red.shade100,
              onSelected: (selected) {
                setState(() => _selectedLevel = 'critical');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text('Advertencia ($warning)'),
                ],
              ),
              selected: _selectedLevel == 'warning',
              selectedColor: Colors.orange.shade100,
              onSelected: (selected) {
                setState(() => _selectedLevel = 'warning');
                _applyFilters();
              },
            ),
            const SizedBox(width: 16),

            // Type filter
            PopupMenuButton<StockType?>(
              child: Chip(
                avatar: const Icon(Icons.category, size: 16),
                label: Text(_selectedType?.toString().split('.').last ?? 'Tipo'),
                deleteIcon:
                    _selectedType != null ? const Icon(Icons.close, size: 16) : null,
                onDeleted: _selectedType != null
                    ? () {
                        setState(() => _selectedType = null);
                        _applyFilters();
                      }
                    : null,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todos'),
                ),
                ...StockType.values.map((type) => PopupMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    )),
              ],
              onSelected: (type) {
                setState(() => _selectedType = type);
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),

            // Provider filter
            PopupMenuButton<Proveedor?>(
              child: Chip(
                avatar: const Icon(Icons.local_shipping, size: 16),
                label: Text(_selectedProvider?.toString().split('.').last ?? 'Proveedor'),
                deleteIcon:
                    _selectedProvider != null ? const Icon(Icons.close, size: 16) : null,
                onDeleted: _selectedProvider != null
                    ? () {
                        setState(() => _selectedProvider = null);
                        _applyFilters();
                      }
                    : null,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todos'),
                ),
                ...Proveedor.values.map((prov) => PopupMenuItem(
                      value: prov,
                      child: Text(prov.toString().split('.').last),
                    )),
              ],
              onSelected: (prov) {
                setState(() => _selectedProvider = prov);
                _applyFilters();
              },
            ),

            if (hasActiveFilters) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
                onPressed: _clearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay alertas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos los productos tienen stock suficiente',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(StockAlert alert) {
    final stock = alert.stockItem;
    final deficit = alert.avgWeeklySales;
    final roundedDeficit = _roundToStandardRange(deficit);
    final isCritical = alert.isCritical;
    final isSelected = _selectedAlerts.contains(alert);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Colors.white,
      child: InkWell(
        onDoubleTap: () => _exportSingleItem(alert),
        onTap: () => _toggleSelection(alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedCrossFade(
                  firstChild: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleSelection(alert),
                    activeColor: Colors.blueGrey,
                  ),
                  secondChild: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: (isCritical ? Colors.red : Colors.orange)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCritical ? Icons.error : Icons.warning,
                      color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  crossFadeState:
                      isSelected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: Durations.short4)
              // Checkbox
              ,
              const SizedBox(width: 8),
              // Icon

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          'Actual: ${stock.cant}',
                          Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        if (roundedDeficit > 0)
                          _buildInfoChip(
                            'Recomendado: $roundedDeficit',
                            isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${alert.avgWeeklySales} u/semana',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (alert.trend != 0) ...[
                          const SizedBox(width: 12),
                          Icon(
                            alert.trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: alert.trend > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${alert.trend > 0 ? '+' : ''}${alert.trend}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: alert.trend > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Copy button
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                color: Colors.grey.shade700,
                tooltip: 'Copiar',
                onPressed: () => _exportSingleItem(alert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
