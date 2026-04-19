import 'package:dist_v2/services/stock_analysis_service.dart';
import 'package:flutter/material.dart';

/// Widget for displaying and managing low stock alerts
/// Shows a badge with alert count and navigates to StockAlertsPage
class LowStockAlertsButton extends StatelessWidget {
  const LowStockAlertsButton({
    super.key,
    required this.stockAnalysisService,
  });

  final StockAnalysisService stockAnalysisService;

  @override
  Widget build(BuildContext context) {
    final alertCount = stockAnalysisService.totalAlertCount;
    final criticalCount = stockAnalysisService.criticalCount;

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: criticalCount > 0 ? Colors.red.shade700 : Colors.orange.shade700,
          ),
          tooltip: 'Ver alertas de stock bajo',
          onPressed: () => Navigator.pushNamed(context, 'stockAlerts'),
        ),
        if (alertCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: criticalCount > 0 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$alertCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

