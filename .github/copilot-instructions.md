# Copilot instructions (dist_v2)

## Architecture overview
- Flutter billing app using Provider pattern with service singletons as `ChangeNotifier`s. All providers wired in [lib/main.dart](lib/main.dart): `PedidoService`, `ClienteService`, `ListaService`, `AnalysisService`, `StockService`.
- **Local-first architecture**: All data persists via `SharedPreferences` in `UserPreferences` ([lib/models/user_preferences.dart](lib/models/user_preferences.dart)), then optionally syncs to Firebase. App works fully offline.
- Firebase is **completely optional** and initialized at startup via `FirebaseService` (anonymous auth + Firestore). See [lib/services/firebase_service.dart](lib/services/firebase_service.dart).
- **Critical sync rule** (appears in all sync-enabled services): `setFirebaseSync(true)` does **GET if local is empty, PUT if local has data**. Never destructive. Pattern in [lib/services/catalogo_service_with_firebase.dart](lib/services/catalogo_service_with_firebase.dart), [lib/services/stock_service_with_firebase.dart](lib/services/stock_service_with_firebase.dart), [lib/services/cliente_service.dart](lib/services/cliente_service.dart).
- Catalog (`ListaService`) supports dual modes: `offline` (assets/catalogo.json) or `firebase`. Switch via `switchMode()` which delegates to `CatalogoService`. See [lib/services/lista_service.dart](lib/services/lista_service.dart).
- Firebase sync layer boundaries (separate concerns cleanly):
  - Stock: [lib/services/firebase_stock_sync.dart](lib/services/firebase_stock_sync.dart)
  - Catalog: [lib/services/firebase_catalogo_sync.dart](lib/services/firebase_catalogo_sync.dart)
  - Pedidos/Carrito: [lib/services/firebase_pedido_sync.dart](lib/services/firebase_pedido_sync.dart)
- Order deduplication: `ClienteService` uses `_extractHash()` to compare `Key` strings (format: `[<[<[#a1b2c]>]>]`), preventing duplicate orders. Hash extraction helpers in [lib/models/user_preferences.dart](lib/models/user_preferences.dart).

## Data models and key relationships
- `Pedido` (order) contains list of `Item` + metadata (date, total, Key). Persisted in `ClienteService` + `UserPreferences`.
- `PedidoService` manages **only in-memory cart**; persisted orders live exclusively in `ClienteService`.
- `Stock` model ([lib/models/stock.dart](lib/models/stock.dart)) has `cambiosPendientes` boolean flag. When true, `_syncPendientes()` in `StockService` batches and syncs only modified items to Firebase.
- `Producto` ([lib/models/producto.dart](lib/models/producto.dart)) is extended catalog model supporting custom fields, metadata, history tracking via `CatalogoService`.
- SharedPreferences key naming: `pedidos<Key>` for orders, `stock<Key>` for inventory.

## State management and UI patterns
- Access services in widgets: `Provider.of<ServiceName>(context)` (rebuilds on change) or `Provider.of<ServiceName>(context, listen: false)` (one-time access).
- Services call `notifyListeners()` after state changes to trigger UI rebuilds.
- Example from codebase: Stock updates mark `cambiosPendientes = true`, call `_guardarYSincronizar()` (local save + optional Firebase sync), then `notifyListeners()`.

## Developer workflows
- Install deps: `flutter pub get`
- Run app: `flutter run` (mobile) or `flutter run -d chrome` (web)
- Clean rebuild: `flutter clean && flutter pub get && flutter run`
- Firebase setup/migration: See [FIREBASE_SETUP.md](FIREBASE_SETUP.md), [MIGRACION_FIREBASE.md](MIGRACION_FIREBASE.md), [CLIENTE_FIREBASE_SYNC.md](CLIENTE_FIREBASE_SYNC.md)
- Catalog asset: [assets/catalogo.json](assets/catalogo.json) (JSON array of products for offline mode)

## Project-specific conventions and critical patterns
- **Always write to local storage first**, then conditionally sync to Firebase if `_syncEnabled && FirebaseService.isInitialized`.
- **Never call Firestore directly** from UI or main services. Use service APIs: `setFirebaseSync(bool)`, `syncNow()`, `loadFromFirebase()`.
- **Batch sync optimization**: `cambiosPendientes` flag pattern (see `StockService`) marks items needing sync. `_syncPendientes()` syncs only modified items, not entire dataset.
- **Catalog operations** (bulk price updates, history) must go through `CatalogoService` to maintain consistency between local history and optional Firebase sync.
- **Order persistence flow**: Cart (`PedidoService`) → Save via `ClienteService.guardarPedido()` → `UserPreferences.setPedido()` → Optional Firebase sync if enabled.
- Firebase config embedded as `MyFirebaseOptions` in [lib/services/firebase_service.dart](lib/services/firebase_service.dart) (no separate generated `firebase_options.dart`).

## Testing and debugging
- Check Firebase sync status: Look for debug prints `📥`, `📤`, `✅`, `❌` in service sync methods.
- Test offline mode: App must work fully without Firebase (disable sync or no internet).
- Order deduplication test: Create orders with same items/date; verify hash comparison prevents duplicates.
- Catalog mode switching: Toggle between `offline` and `firebase` modes; verify data source changes correctly.
