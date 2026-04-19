# AutoBiller

## Desktop app for markets to make bills from a local list of items.

### Features:
- SearchBar
- Save by client name
- DataSave
- DataExport in PDF
- **🔥 Firebase Sync** - Sincronización en tiempo real de stock y pedidos

## 🔥 Firebase Integration

Esta aplicación ahora incluye sincronización completa con Firebase para:

### Stock Service
- Sincronización automática de inventario
- Backup en la nube
- Acceso multi-dispositivo
- Modo offline con persistencia local

### Cliente Service (Pedidos)
- Sincronización de pedidos entre dispositivos
- Historial de pedidos en la nube
- Protección de datos locales
- Merge inteligente de datos

### Documentación

- [📚 FIREBASE_SETUP.md](./FIREBASE_SETUP.md) - Configuración inicial de Firebase
- [📱 CLIENTE_FIREBASE_SYNC.md](./CLIENTE_FIREBASE_SYNC.md) - Guía de sincronización de pedidos
- [🔧 MIGRACION_FIREBASE.md](./MIGRACION_FIREBASE.md) - Migración de datos existentes

### Ejemplo de Uso

```dart
// Activar sincronización para Stock
final stockService = Provider.of<StockService>(context);
await stockService.setFirebaseSync(true);

// Activar sincronización para Pedidos
final clienteService = Provider.of<ClienteService>(context);
await clienteService.setFirebaseSync(true);

// Migración segura desde Android
await stockService.firstSyncFromAndroid();
await clienteService.firstSyncFromAndroid();
```

Ver [firebase_sync_example.dart](./lib/examples/firebase_sync_example.dart) para un ejemplo completo.

## 🚀 Quick Start

1. Instalar dependencias:
   ```bash
   flutter pub get
   ```

2. Configurar Firebase (opcional):
   - Seguir guía en [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)

3. Ejecutar app:
   ```bash
   flutter run
   ```

## 📁 Estructura del Proyecto

```
lib/
  ├── services/
  │   ├── stock_service_with_firebase.dart    # ✅ Con Firebase
  │   ├── cliente_service.dart                # ✅ Con Firebase
  │   ├── firebase_service.dart               # Servicio base
  │   ├── firebase_stock_sync.dart            # Sync de stock
  │   └── firebase_pedido_sync.dart           # Sync de pedidos
  ├── models/
  ├── pages/
  └── examples/
      └── firebase_sync_example.dart          # Ejemplo de uso
```

## 🔐 Seguridad

- Los datos siempre se guardan localmente primero
- Firebase es un backup adicional, no el almacenamiento principal
- Autenticación anónima (no requiere login)
- Modo offline completo

## 📝 Notas

- La app funciona perfectamente sin Firebase
- Firebase es opcional y se puede activar/desactivar en cualquier momento
- Los datos locales nunca se pierden

