import 'package:dist_v2/models/stock.dart';
import 'package:dist_v2/models/vip_item.dart';

/// Represents a low stock alert for a Stock item
class StockAlert {
  final Stock stockItem;
  final VipItem? salesData;
  final int currentQuantity;
  final int recommendedMinimum;
  final int avgWeeklySales;
  final double matchConfidence; // 0-100
  final String alertLevel; // 'critical', 'warning', 'info'
  final int trend; // Growth percentage

  StockAlert({
    required this.stockItem,
    this.salesData,
    required this.currentQuantity,
    required this.recommendedMinimum,
    required this.avgWeeklySales,
    required this.matchConfidence,
    required this.alertLevel,
    required this.trend,
  });

  /// Whether this is a critical alert (stock < 1 week of sales)
  bool get isCritical => alertLevel == 'critical';

  /// Whether this is a warning alert (stock < 2 weeks of sales)
  bool get isWarning => alertLevel == 'warning';

  /// Difference between current stock and recommended minimum
  int get deficit => recommendedMinimum - currentQuantity;

  @override
  String toString() {
    return 'StockAlert(${stockItem.name}, current: $currentQuantity, '
        'recommended: $recommendedMinimum, level: $alertLevel, '
        'confidence: ${matchConfidence.toStringAsFixed(0)}%)';
  }
}
