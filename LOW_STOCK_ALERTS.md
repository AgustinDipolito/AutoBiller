# Low Stock Alert System - Usage Guide

## Overview
The Low Stock Alert System automatically identifies products that are running low based on sales statistics. It uses fuzzy matching to link Stock items with sales data, handling name variations like "CORDÓN 4,5 mm" vs "Cordon 4.5mm".

## Features

### 📱 Dedicated Page
- Full-screen interface at route `stockAlerts`
- Advanced filters by level, type, and provider
- Real-time search functionality
- Individual and batch export capabilities

### 🔍 Filtering & Search
- **Level filters**: All, Critical (🔴), Warning (🟠)
- **Type filter**: Filter by StockType (burlete, cierre, manija, etc.)
- **Provider filter**: Filter by Proveedor (axal, flexico, bronzen, etc.)
- **Search**: Real-time text search by product name
- **Clear all**: One-click filter reset

### 📊 Smart Export
- **Individual export**: Tap any alert card to copy
- **Batch export**: Copy all filtered alerts at once
- **Clean format**: `ProductName: Quantity`
- **Standard ranges**: Auto-rounds to [1, 5, 10, 15, 20, 25, 50, 100]
- **Smart rounding**: Values >100 round to multiples of 50

Example export:
```
CORDÓN 4,5 mm: 20
T-89 Negro: 15
BURLETE EPDM: 25
```

## User Interface

### Stock Page Button
- **Location**: Stock page AppBar
- **Icon color**: Red (critical) / Orange (warnings)
- **Badge**: Shows total alert count
- **Click**: Navigates to dedicated alerts page

### Alerts Page Layout

#### Header
- Title: "Alertas de Stock Bajo"
- Actions: Copy All, Refresh/Reanalyze

#### Search Bar
- Placeholder: "Buscar producto..."
- Real-time filtering as you type
- Clear button when text is present

#### Filter Chips
- **Todos**: Show all alerts
- **🔴 Crítico**: Stock < 1 week of sales
- **🟠 Advertencia**: Stock < 2 weeks of sales
- **Tipo**: Dropdown with all StockType values
- **Proveedor**: Dropdown with all Proveedor values
- **Limpiar filtros**: Reset all filters

#### Summary Cards
Three cards showing:
1. **Crítico** (red): Count of critical alerts
2. **Advertencia** (orange): Count of warning alerts
3. **Total** (blue): Total filtered alerts

#### Alert Cards
Each card displays:
- **Icon**: Error (critical) or Warning badge
- **Product name** (bold)
- **Current stock** chip
- **Recommended quantity** chip (rounded to standard range)
- **Weekly sales** trend
- **Growth trend** (% with up/down arrow)
- **Copy button**: Tap card or button to export

### Empty State
- Green checkmark icon
- "No hay alertas" message
- Confirmation all products have sufficient stock

## How It Works

### 1. **Fuzzy Matching**
- Uses `FuzzyMatcher` to match Stock names against sales data (VipItems)
- Handles accent variations, spacing, and punctuation differences
- Default confidence threshold: 70%
- Separate thresholds per color/variant

### 2. **Statistical Thresholds**
Based on weekly sales averages:
- **Critical** 🔴: Stock < 1 week of average sales
- **Warning** 🟠: Stock < 2 weeks of average sales

### 3. **Exclusions**
- Products without sales history are excluded from alerts
- Only items with matched sales data (≥70% confidence) are analyzed

### 4. **Standard Range Rounding**
Deficit quantities are rounded to standard purchasing ranges:
- Ranges: 1, 5, 10, 15, 20, 25, 50, 100
- Values >100: Multiples of 50 (150, 200, 250...)
- Example: Deficit of 13 → rounds to 15

## Programmatic Usage

### Navigate to Page
```dart
Navigator.pushNamed(context, 'stockAlerts');
```

### Trigger Analysis
```dart
final stockAnalysisService = Provider.of<StockAnalysisService>(context, listen: false);
await stockAnalysisService.analyzeStockLevels();
```

### Access Alerts
```dart
final stockAnalysisService = Provider.of<StockAnalysisService>(context);

// Get all alerts
List<StockAlert> alerts = stockAnalysisService.alerts;

// Get by level
List<StockAlert> critical = stockAnalysisService.getAlertsByLevel('critical');
List<StockAlert> warnings = stockAnalysisService.getAlertsByLevel('warning');

// Get counts
int totalAlerts = stockAnalysisService.totalAlertCount;
int criticalCount = stockAnalysisService.criticalCount;
int warningCount = stockAnalysisService.warningCount;

// Filter by type or provider
List<StockAlert> byType = stockAnalysisService.getAlertsByStockType(StockType.burlete);
List<StockAlert> byProvider = stockAnalysisService.getAlertsByProvider(Proveedor.axal);
```

### StockAlert Properties
```dart
StockAlert alert = alerts.first;

alert.stockItem;           // Stock object
alert.salesData;           // VipItem object (can be null)
alert.currentQuantity;     // Current stock level
alert.recommendedMinimum;  // Suggested minimum stock
alert.avgWeeklySales;      // Weekly sales average
alert.matchConfidence;     // 0-100 match confidence
alert.alertLevel;          // 'critical' or 'warning'
alert.trend;               // Growth percentage (-100 to +100)

// Helpers
alert.isCritical;          // true if critical
alert.isWarning;           // true if warning
alert.deficit;             // Recommended - Current
```

## Configuration

### Adjust Confidence Threshold
In `stock_analysis_service.dart`, the `analyzeStockLevels()` method accepts `minConfidence`:
```dart
await stockAnalysisService.analyzeStockLevels(minConfidence: 80); // Higher = stricter
```

### Adjust Threshold Multipliers
Edit thresholds in `StockAnalysisService._linkStockToSales()`:
```dart
if (stock.cant < avgWeeklySales) {
  alertLevel = 'critical';
  recommendedMinimum = avgWeeklySales * 2;  // Change multiplier here
} else if (stock.cant < avgWeeklySales * 3) {  // Change multiplier here
  alertLevel = 'warning';
  recommendedMinimum = avgWeeklySales * 3;
}
```

### Adjust Standard Ranges
In `stock_alerts_page.dart`, modify `_roundToStandardRange()`:
```dart
const ranges = [1, 5, 10, 15, 20, 25, 50, 100]; // Customize ranges
```

## Performance Considerations
- Analysis runs automatically on app startup (after 2-second delay)
- Manual refresh available via AppBar button
- Filters apply client-side (instant updates)
- Incremental updates: Rerun analysis after stock changes

## Technical Details

### Files Created
- `lib/helpers/fuzzy_matcher.dart` - String similarity matching
- `lib/models/stock_alert.dart` - Alert data structure
- `lib/services/stock_analysis_service.dart` - Core analysis logic
- `lib/pages/stock_alerts_page.dart` - Dedicated full-screen UI
- `lib/widgets/low_stock_alerts.dart` - Badge button widget

### Dependencies Added
- `fuzzywuzzy: ^1.1.6` - Levenshtein distance algorithm

### Services Modified
- `analysis_service.dart` - Added `calculateProductStats()` method
- `main.dart` - Wired `StockAnalysisService` in Provider tree
- `stock_page.dart` - Added alert button to AppBar
- `principal_page.dart` - Auto-analyze on app startup
- `routes.dart` - Added `stockAlerts` route
