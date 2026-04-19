import 'package:dist_v2/helpers/fuzzy_matcher.dart';
import 'package:dist_v2/models/stock.dart';
import 'package:dist_v2/models/stock_alert.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/services/stock_service_with_firebase.dart';
import 'package:flutter/material.dart';

/// Service for analyzing stock levels against sales data
/// Generates alerts for products below statistically-determined minimums
class StockAnalysisService with ChangeNotifier {
  final StockService _stockService;
  final AnalysisService _analysisService;
  final ClienteService _clienteService;

  List<StockAlert> _alerts = [];
  bool _isAnalyzing = false;

  StockAnalysisService(
    this._stockService,
    this._analysisService,
    this._clienteService,
  );

  List<StockAlert> get alerts => _alerts;
  bool get isAnalyzing => _isAnalyzing;

  /// Get alerts grouped by level
  Map<String, List<StockAlert>> get alertsByLevel {
    final grouped = <String, List<StockAlert>>{};

    for (final alert in _alerts) {
      grouped.putIfAbsent(alert.alertLevel, () => []).add(alert);
    }

    return grouped;
  }

  /// Get count of critical alerts
  int get criticalCount => _alerts.where((a) => a.isCritical).length;

  /// Get count of warning alerts
  int get warningCount => _alerts.where((a) => a.isWarning).length;

  /// Get total alert count
  int get totalAlertCount => _alerts.length;

  /// Analyzes all stock items and generates alerts
  /// Compares current stock levels against sales-based thresholds
  Future<void> analyzeStockLevels({int minConfidence = 85}) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      _alerts.clear();

      // Get all stock items
      final stockItems = _stockService.stock;

      // Get all sales data (VipItems)
      final salesData = _analysisService.vipItems;

      if (salesData.isEmpty) {
        // No sales data to analyze against
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      // Link stock items to sales data using fuzzy matching
      final links = _linkStockToSales(
        stockItems: stockItems,
        salesData: salesData,
        minConfidence: minConfidence,
      );

      // Filter pedidos to last 6 months for stock analysis
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final recentPedidos = _clienteService.clientes
          .where((pedido) => pedido.fecha.isAfter(sixMonthsAgo))
          .toList();

      // Generate alerts for linked items
      for (final entry in links.entries) {
        final stock = entry.key;
        final matchResult = entry.value;
        final vipItem = matchResult.item;

        // Calculate statistics (using only last 6 months)
        final stats = _analysisService.calculateProductStats(
          vipItem,
          recentPedidos,
        );

        final avgWeeklySales = stats['avgWeeklySales']!.toInt();
        final trend = stats['trend']!.toInt();

        // Skip items with no sales history
        if (avgWeeklySales == 0) continue;

        // Determine alert level and recommended minimum
        String alertLevel;
        int recommendedMinimum;

        if (stock.cant < avgWeeklySales) {
          // Critical: less than 1 week of sales
          alertLevel = 'critical';
          recommendedMinimum = avgWeeklySales * 2;
        } else if (stock.cant < avgWeeklySales * 2) {
          // Warning: less than 2 weeks of sales
          alertLevel = 'warning';
          recommendedMinimum = avgWeeklySales * 2;
        } else {
          // Stock level is acceptable, skip
          continue;
        }

        // Create alert
        final alert = StockAlert(
          stockItem: stock,
          salesData: vipItem,
          currentQuantity: stock.cant,
          recommendedMinimum: recommendedMinimum,
          avgWeeklySales: avgWeeklySales,
          matchConfidence: matchResult.score.toDouble(),
          alertLevel: alertLevel,
          trend: trend,
        );

        _alerts.add(alert);
      }

      // Sort alerts: critical first, then by deficit
      _alerts.sort((a, b) {
        if (a.isCritical && !b.isCritical) return -1;
        if (!a.isCritical && b.isCritical) return 1;
        return b.deficit.compareTo(a.deficit);
      });
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Links Stock items to VipItems using fuzzy matching
  /// Handles color/type variants by matching composite keys
  Map<Stock, _MatchWithItem> _linkStockToSales({
    required List<Stock> stockItems,
    required List<VipItem> salesData,
    required int minConfidence,
  }) {
    final links = <Stock, _MatchWithItem>{};

    // Create lookup candidates: "nombre|tipo" composite keys
    final candidates = salesData.map((vip) => vip.nombre).toList();

    for (final stock in stockItems) {
      // Try to find best match for stock name
      final matchResult = FuzzyMatcher.findBestMatch(
        stock.name,
        candidates,
        minConfidence: minConfidence,
      );

      if (matchResult != null) {
        final matchedVipItem = salesData[matchResult.index];

        links[stock] = _MatchWithItem(
          item: matchedVipItem,
          score: matchResult.score,
        );
      }
    }

    return links;
  }

  /// Clears all alerts
  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  /// Get alerts for a specific alert level
  List<StockAlert> getAlertsByLevel(String level) {
    return _alerts.where((a) => a.alertLevel == level).toList();
  }

  /// Get alerts for a specific stock type
  List<StockAlert> getAlertsByStockType(StockType type) {
    return _alerts.where((a) => a.stockItem.type == type).toList();
  }

  /// Get alerts for a specific provider
  List<StockAlert> getAlertsByProvider(Proveedor provider) {
    return _alerts.where((a) => a.stockItem.proveedor == provider).toList();
  }
}

/// Internal class to hold match result with VipItem
class _MatchWithItem {
  final VipItem item;
  final int score;

  _MatchWithItem({
    required this.item,
    required this.score,
  });
}
