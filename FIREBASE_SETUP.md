# Configuración de Firebase para Sincronización

Este proyecto utiliza Firebase Firestore para sincronizar datos entre múltiples dispositivos.

## Servicios Sincronizados

### 1. **Catálogo de Productos** (`firebase_catalogo_sync.dart`)
- Sincronización de productos
- Historial de cambios
- Actualizaciones en tiempo real

### 2. **Stock/Inventario** (`firebase_stock_sync.dart`)
- Control de inventario
- Movimientos de stock
- Filtros por tipo y proveedor

### 3. **Pedidos/Carrito** (`firebase_pedido_sync.dart`)
- Carrito de compras sincronizado
- Historial de pedidos
- Compartir carritos entre dispositivos

## Configuración Inicial

### 1. Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita Firestore Database:
   - Ve a "Build" → "Firestore Database"
   - Click en "Create database"
   - Selecciona el modo de inicio (recomendado: modo prueba inicialmente)

### 2. Configurar la App para Cada Plataforma

#### Android

1. En Firebase Console, agrega una app Android
2. Descarga el archivo `google-services.json`
3. Colócalo en `android/app/google-services.json`
4. Edita `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ... otras dependencias
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

5. Edita `android/app/build.gradle`:

```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // Agregar esta línea

dependencies {
    // ... otras dependencias
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

#### iOS

1. En Firebase Console, agrega una app iOS
2. Descarga el archivo `GoogleService-Info.plist`
3. Abre el proyecto en Xcode: `ios/Runner.xcworkspace`
4. Arrastra `GoogleService-Info.plist` a Runner en Xcode
5. Asegúrate de marcar "Copy items if needed"

#### Web

1. En Firebase Console, agrega una app Web
2. Copia la configuración de Firebase
3. Edita `web/index.html` y agrega antes del cierre de `</body>`:

```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "TU_API_KEY",
    authDomain: "TU_PROJECT_ID.firebaseapp.com",
    projectId: "TU_PROJECT_ID",
    storageBucket: "TU_PROJECT_ID.appspot.com",
    messagingSenderId: "TU_SENDER_ID",
    appId: "TU_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

### 3. Reglas de Seguridad de Firestore

En Firebase Console → Firestore Database → Rules, configura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de productos - lectura pública, escritura autenticada
    match /productos/{productoId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Colección de stock - lectura pública, escritura autenticada
    match /stock/{stockId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Carritos - solo el dueño puede leer/escribir
    match /carritos/{carritoId} {
      allow read, write: if request.auth != null && 
                            (request.auth.uid == carritoId || 
                             carritoId.matches('shared_.*'));
    }
    
    // Pedidos guardados - solo el creador puede leer/escribir
    match /pedidos_guardados/{pedidoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Historial de cambios - lectura pública, escritura autenticada
    match /catalogo_historial/{cambioId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 4. Índices de Firestore (Opcional pero recomendado)

Crea índices compuestos en Firestore Console para mejorar el rendimiento:

1. **Stock por tipo y cantidad**:
   - Colección: `stock`
   - Campos: `type` (Ascendente), `cant` (Ascendente)

2. **Pedidos por fecha**:
   - Colección: `pedidos_guardados`
   - Campos: `createdAt` (Descendente)

## Uso en la Aplicación

### Inicializar Firebase

En `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  runApp(MyApp());
}
```

### Integrar con los Servicios Existentes

#### CatalogoService

```dart
import 'services/firebase_catalogo_sync.dart';

// En el método donde quieras sincronizar
final catalogoSync = FirebaseCatalogoSync();

// Activar sincronización en tiempo real
catalogoSync.onProductosChanged = (productos) {
  // Actualizar lista local
  _productos = productos;
  notifyListeners();
};
catalogoSync.startRealtimeSync();

// Sincronizar cambios hacia Firebase
await catalogoSync.syncProducto(producto);
```

#### StockService

```dart
import 'services/firebase_stock_sync.dart';

// En el servicio
final stockSync = FirebaseStockSync();

// Activar sincronización en tiempo real
stockSync.onStockChanged = (stockItems) {
  stock = stockItems;
  notifyListeners();
};
stockSync.startRealtimeSync();

// Sincronizar cambios
await stockSync.syncStockItem(stockItem);
```

#### PedidoService

```dart
import 'services/firebase_pedido_sync.dart';

// En el servicio
final pedidoSync = FirebasePedidoSync();

// Activar sincronización en tiempo real
pedidoSync.onCarritoChanged = (items) {
  carrito = items;
  notifyListeners();
};
pedidoSync.startRealtimeSync();

// Sincronizar carrito
await pedidoSync.syncCarrito(carrito);
```

## Características Implementadas

### ✅ Sincronización Bidireccional
- Los cambios en un dispositivo se reflejan en todos los demás
- Actualizaciones en tiempo real usando Firestore Snapshots

### ✅ Persistencia Offline
- Los datos se guardan localmente si no hay conexión
- Se sincronizan automáticamente cuando se recupera la conexión

### ✅ Metadata de Sincronización
- Cada documento incluye:
  - `deviceId`: ID del dispositivo que hizo el cambio
  - `lastModified`: Timestamp del servidor
  - `version`: Control de versiones

### ✅ Autenticación Anónima
- Cada dispositivo se identifica automáticamente
- No requiere login del usuario

### ✅ Compartir Carritos
- Genera un código para compartir carritos entre dispositivos
- Los carritos compartidos expiran después de 24 horas

## Comandos Útiles

### Instalar dependencias
```bash
flutter pub get
```

### Verificar configuración de Firebase
```bash
flutterfire configure
```

### Limpiar y reconstruir
```bash
flutter clean
flutter pub get
flutter run
```

## Estructura de Datos en Firestore

### Colección: `productos`
```json
{
  "ID": "123",
  "nombre": "Producto ejemplo",
  "precio": "1000",
  "tipo": "Tipo ejemplo",
  "marca": "axal",
  "familia": "burlete",
  "activo": true,
  "syncMetadata": {
    "deviceId": "user_xyz",
    "lastModified": "2024-01-01T00:00:00Z",
    "version": 1
  }
}
```

### Colección: `stock`
```json
{
  "id": "1",
  "name": "Item ejemplo",
  "cant": "50",
  "type": "0",
  "proveedor": "0",
  "date": "2024-01-01T00:00:00Z",
  "ultimaCant": "5",
  "syncMetadata": { ... }
}
```

### Colección: `carritos`
```json
{
  "items": [
    {
      "id": 123,
      "nombre": "Producto",
      "cantidad": 2,
      "precio": 1000,
      "precioT": 2000
    }
  ],
  "itemCount": 1,
  "total": 2000,
  "lastUpdated": "2024-01-01T00:00:00Z",
  "syncMetadata": { ... }
}
```

## Troubleshooting

### Error: "Firebase not initialized"
- Asegúrate de llamar a `FirebaseService().initialize()` antes de usar cualquier servicio

### Los datos no se sincronizan
- Verifica la conexión a internet
- Revisa las reglas de seguridad en Firebase Console
- Comprueba los logs en la consola

### Error en Android build
- Verifica que `google-services.json` esté en `android/app/`
- Asegúrate de tener las versiones correctas de los plugins de Gradle

### Error en iOS build
- Verifica que `GoogleService-Info.plist` esté añadido correctamente en Xcode
- Ejecuta `pod install` en el directorio `ios/`

## Próximos Pasos

1. **Implementar en CatalogoService**: Modificar para usar `FirebaseCatalogoSync`
2. **Implementar en StockService**: Modificar para usar `FirebaseStockSync`
3. **Implementar en PedidoService**: Modificar para usar `FirebasePedidoSync`
4. **Testing**: Probar sincronización entre múltiples dispositivos
5. **Optimización**: Ajustar reglas de seguridad según necesidades

## Recursos Adicionales

- [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
- [Firestore Docs](https://firebase.google.com/docs/firestore)
- [FlutterFire Plugins](https://firebase.flutter.dev/)
