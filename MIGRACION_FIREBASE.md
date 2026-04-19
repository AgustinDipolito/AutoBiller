# Guía de Migración a Firebase - Paso a Paso

Esta guía te ayudará a migrar tus servicios actuales para usar Firebase Firestore.

## ⚠️ IMPORTANTE: Backup antes de empezar

Antes de realizar cualquier cambio, asegúrate de:
1. Hacer commit de todos tus cambios actuales
2. Crear un backup de la carpeta del proyecto
3. Probar primero en un dispositivo de prueba

## Estructura de Archivos

Se han creado los siguientes archivos nuevos:

### Servicios Base
- `lib/services/firebase_service.dart` - Servicio base de Firebase
- `lib/services/firebase_catalogo_sync.dart` - Sincronización del catálogo
- `lib/services/firebase_stock_sync.dart` - Sincronización del stock
- `lib/services/firebase_pedido_sync.dart` - Sincronización de pedidos

### Versiones con Firebase (ejemplos)
- `lib/services/catalogo_service_with_firebase.dart` - Ejemplo de integración para catálogo
- `lib/services/stock_service_with_firebase.dart` - Ejemplo de integración para stock
- `lib/services/pedido_service_with_firebase.dart` - Ejemplo de integración para pedidos

## Paso 1: Configurar Firebase Console

### 1.1. Crear Proyecto
1. Ve a https://console.firebase.google.com/
2. Click en "Agregar proyecto"
3. Nombre del proyecto: `dist-v2` (o el que prefieras)
4. Sigue los pasos del asistente

### 1.2. Habilitar Firestore
1. En el menú lateral, ve a "Build" → "Firestore Database"
2. Click en "Crear base de datos"
3. Selecciona ubicación (recomendado: us-central o southamerica-east1)
4. Modo de inicio: **"Empezar en modo de prueba"** (por ahora)

### 1.3. Configurar Reglas de Seguridad
En la pestaña "Reglas", copia y pega las reglas del archivo `FIREBASE_SETUP.md`

## Paso 2: Configurar Firebase en tu App

### 2.1. Instalar FlutterFire CLI

Abre PowerShell y ejecuta:

```powershell
dart pub global activate flutterfire_cli
```

### 2.2. Configurar Firebase para tu proyecto

En el directorio del proyecto, ejecuta:

```powershell
flutterfire configure
```

Sigue las instrucciones:
- Selecciona tu proyecto de Firebase
- Selecciona las plataformas (Android, iOS, Web)
- Esto creará automáticamente los archivos de configuración

### 2.3. Instalar dependencias

```powershell
flutter pub get
```

## Paso 3: Inicializar Firebase en main.dart

Edita tu archivo `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generado por flutterfire configure
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar servicio de Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  runApp(MyApp());
}
```

## Paso 4: Migrar CatalogoService

### Opción A: Reemplazar el archivo completo (Recomendado para empezar)

1. Renombra el archivo actual:
   ```powershell
   Rename-Item "lib/services/catalogo_service_with_firebase.dart" "lib/services/catalogo_service_old.dart"
   ```

2. Renombra el nuevo archivo:
   ```powershell
   Rename-Item "lib/services/catalogo_service_with_firebase.dart" "lib/services/catalogo_service_with_firebase.dart"
   ```

### Opción B: Integrar gradualmente

Si prefieres integrar poco a poco, sigue estos pasos:

1. Abre `lib/services/catalogo_service_with_firebase.dart`
2. Agrega los imports al inicio:
   ```dart
   import 'firebase_catalogo_sync.dart';
   import 'firebase_service.dart';
   ```

3. Agrega las propiedades al servicio:
   ```dart
   final FirebaseCatalogoSync _firebaseSync = FirebaseCatalogoSync();
   final FirebaseService _firebaseService = FirebaseService();
   bool _syncEnabled = false;
   ```

4. Agrega el método para activar Firebase:
   ```dart
   Future<void> setFirebaseSync(bool enabled) async {
     // Copiar implementación del archivo _with_firebase
   }
   ```

5. Modifica los métodos existentes para sincronizar (ver archivo de ejemplo)

### Activar sincronización

En tu UI o al iniciar la app:

```dart
final catalogoService = CatalogoService();
await catalogoService.setFirebaseSync(true); // Activar Firebase
```

## Paso 5: Migrar StockService

Similar al paso anterior:

### Opción A: Reemplazo completo
```powershell
Rename-Item "lib/services/stock_service_with_firebase.dart" "lib/services/stock_service_old.dart"
Rename-Item "lib/services/stock_service_with_firebase.dart" "lib/services/stock_service_with_firebase.dart"
```

### Opción B: Ver archivo de ejemplo y copiar la lógica

### Activar sincronización
```dart
final stockService = StockService();
await stockService.setFirebaseSync(true);
```

## Paso 6: Migrar PedidoService

### Opción A: Reemplazo completo
```powershell
Rename-Item "lib/services/pedido_service.dart" "lib/services/pedido_service_old.dart"
Rename-Item "lib/services/pedido_service_with_firebase.dart" "lib/services/pedido_service.dart"
```

### Opción B: Ver archivo de ejemplo y copiar la lógica

### Activar sincronización
```dart
final pedidoService = PedidoService();
await pedidoService.setFirebaseSync(true, autoSync: true);
```

## Paso 7: Configurar Providers (si usas Provider)

Si estás usando `provider` para gestión de estado, actualiza tus providers:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CatalogoService()),
    ChangeNotifierProvider(create: (_) => StockService()),
    ChangeNotifierProvider(create: (_) => PedidoService()),
  ],
  child: MyApp(),
)
```

Y luego, después de inicializar, activa Firebase:

```dart
// En un initState o método de inicio
final catalogoService = Provider.of<CatalogoService>(context, listen: false);
await catalogoService.setFirebaseSync(true);

final stockService = Provider.of<StockService>(context, listen: false);
await stockService.setFirebaseSync(true);

final pedidoService = Provider.of<PedidoService>(context, listen: false);
await pedidoService.setFirebaseSync(true);
```

## Paso 8: Probar la Sincronización

### 8.1. Prueba en un dispositivo

1. Ejecuta la app:
   ```powershell
   flutter run
   ```

2. Verifica en los logs que aparezca:
   ```
   Firebase inicializado correctamente
   Sincronización Firebase activada
   ```

3. Haz cambios en el catálogo, stock o pedidos
4. Ve a Firebase Console → Firestore Database
5. Deberías ver las colecciones creadas con tus datos

### 8.2. Prueba sincronización entre dispositivos

1. Ejecuta la app en dos dispositivos/emuladores diferentes
2. En el dispositivo 1, agrega un producto al catálogo
3. En el dispositivo 2, deberías ver el producto aparecer automáticamente
4. Lo mismo con stock y pedidos

## Paso 9: Características Adicionales

### Compartir Carrito

```dart
// En el dispositivo 1
final shareId = await pedidoService.shareCarrito();
print('Código para compartir: $shareId');

// En el dispositivo 2
await pedidoService.importSharedCarrito(shareId);
```

### Historial de Pedidos

```dart
// Guardar pedido al finalizar
await pedidoService.savePedido(
  customerName: 'Cliente XYZ',
  notes: 'Entrega urgente',
);

// Obtener historial
final pedidos = await pedidoService.getHistorialPedidos(
  limit: 20,
  startDate: DateTime.now().subtract(Duration(days: 30)),
);
```

### Ver Cambios en el Catálogo

```dart
// Obtener historial de un producto
final cambios = await catalogoService.getHistorial(
  productoId: '123',
);

// Mostrar en UI
for (final cambio in cambios) {
  print('${cambio.campo}: ${cambio.valorAnterior} → ${cambio.valorNuevo}');
}
```

## Paso 10: Modo Híbrido (Local + Firebase)

Los servicios están diseñados para funcionar en modo híbrido:

- **Siempre se guarda backup local** (SharedPreferences)
- **Firebase es opcional** y se puede activar/desactivar
- **Si Firebase falla**, la app sigue funcionando con datos locales

```dart
// Desactivar Firebase temporalmente
await catalogoService.setFirebaseSync(false);

// Reactivar más tarde
await catalogoService.setFirebaseSync(true);
```

## Paso 11: Configuración de Producción

Cuando estés listo para producción:

### 11.1. Actualizar Reglas de Firestore

Cambia las reglas a modo producción (ver `FIREBASE_SETUP.md`)

### 11.2. Configurar Índices

En Firebase Console → Firestore → Indexes, crea los índices recomendados

### 11.3. Monitoreo

Activa Firebase Analytics y Crashlytics para monitorear:
```yaml
# En pubspec.yaml
dependencies:
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
```

## Troubleshooting

### Error: "Firebase not initialized"
**Solución**: Asegúrate de llamar a `FirebaseService().initialize()` en `main.dart`

### Los datos no aparecen en Firestore
**Solución**: 
1. Verifica que `setFirebaseSync(true)` esté siendo llamado
2. Revisa los logs para ver errores
3. Verifica las reglas de Firestore

### La app se congela al sincronizar
**Solución**: 
1. Reduce la cantidad de datos que sincronizas de una vez
2. Usa paginación para historial de pedidos
3. Implementa sincronización en background

### Conflictos entre dispositivos
**Solución**: 
- Los datos usan "last write wins" por defecto
- Para lógica más compleja, considera usar transacciones de Firestore

## Revertir Cambios

Si necesitas volver atrás:

1. Restaura los archivos originales:
   ```powershell
   Rename-Item "lib/services/catalogo_service_old.dart" "lib/services/catalogo_service_with_firebase.dart"
   Rename-Item "lib/services/stock_service_old.dart" "lib/services/stock_service_with_firebase.dart"
   Rename-Item "lib/services/pedido_service_old.dart" "lib/services/pedido_service.dart"
   ```

2. Remueve las dependencias de Firebase del `pubspec.yaml`

3. Ejecuta `flutter pub get`

## Próximos Pasos

Una vez que la sincronización básica funcione:

1. **Implementar autenticación real** (reemplazar anónima)
2. **Agregar permisos por usuario** (roles: admin, vendedor, etc.)
3. **Implementar sincronización selectiva** (solo datos necesarios)
4. **Agregar funciones de Cloud Functions** para lógica del servidor
5. **Implementar notificaciones push** para cambios importantes

## Soporte

Si tienes problemas:
1. Revisa los logs de Flutter: `flutter logs`
2. Revisa Firestore Console para ver errores
3. Verifica la documentación oficial: https://firebase.google.com/docs/flutter/setup
4. Consulta los archivos de ejemplo en `lib/services/*_with_firebase.dart`
