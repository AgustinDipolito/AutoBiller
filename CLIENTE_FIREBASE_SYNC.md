# Sincronización Firebase para ClienteService

## 📋 Descripción

El `ClienteService` ahora incluye sincronización automática con Firebase, similar a `StockService`. Esto permite:

- ✅ Sincronizar pedidos entre dispositivos
- ✅ Backup automático en la nube
- ✅ Sincronización en tiempo real
- ✅ Protección de datos locales durante la migración
- ✅ Modo offline (los datos se guardan localmente siempre)

## 🚀 Uso Básico

### 1. Inicialización Simple

```dart
final clienteService = Provider.of<ClienteService>(context, listen: false);

// Inicializar normalmente (sin Firebase)
clienteService.init();

// O inicializar con Firebase automático
await clienteService.initWithFirebase();
```

### 2. Activar Sincronización Manualmente

```dart
// Activar sincronización (modo seguro por defecto)
await clienteService.setFirebaseSync(true);

// Desactivar sincronización
await clienteService.setFirebaseSync(false);
```

## 📤 Primera Sincronización (Android → Firebase)

Si ya tienes pedidos guardados en Android y quieres migrarlos a Firebase de forma segura:

```dart
final clienteService = Provider.of<ClienteService>(context, listen: false);

// Cargar datos locales primero
clienteService.init();

// Migrar a Firebase de forma segura
final success = await clienteService.firstSyncFromAndroid();

if (success) {
  print('✅ Pedidos migrados exitosamente a Firebase');
} else {
  print('❌ Error en la migración');
}
```

### ¿Qué hace `firstSyncFromAndroid()`?

1. ✅ Sube TODOS tus pedidos locales a Firebase
2. ✅ Verifica que se subieron correctamente
3. ✅ Activa sincronización bidireccional
4. ✅ **NO sobrescribe tus datos locales**

## 🔄 Estrategias de Sincronización

### Opción 1: Priorizar Datos Locales (Recomendado para migración)

```dart
await clienteService.setFirebaseSync(
  true,
  uploadLocalFirst: true,
  mergeStrategy: 'local',
);
```

**Comportamiento:**
- Sube datos locales primero
- Si hay conflicto, mantiene los datos locales
- Descarga de Firebase solo si local está vacío

### Opción 2: Priorizar Firebase

```dart
await clienteService.setFirebaseSync(
  true,
  uploadLocalFirst: false,
  mergeStrategy: 'remote',
);
```

**Comportamiento:**
- Descarga datos de Firebase y sobrescribe locales
- Útil si confías más en Firebase que en local

### Opción 3: Combinar (Merge Inteligente)

```dart
await clienteService.setFirebaseSync(
  true,
  uploadLocalFirst: true,
  mergeStrategy: 'merge',
);
```

**Comportamiento:**
- Combina datos locales y remotos
- Usa el pedido más reciente cuando hay duplicados
- Mantiene pedidos únicos de ambos lados

## 📊 Verificar Estado de Sincronización

```dart
final status = await clienteService.getSyncStatus();

print('Pedidos locales: ${status['localPedidos']}');
print('Pedidos en Firebase: ${status['firebasePedidos']}');
print('Firebase habilitado: ${status['firebaseEnabled']}');
print('Firebase inicializado: ${status['firebaseInitialized']}');
```

## 🔧 Operaciones con Firebase

### Sincronizar Manualmente

```dart
// Forzar subida de todos los pedidos
await clienteService.syncNow();
```

### Descargar desde Firebase

```dart
// Descargar y sobrescribir con datos de Firebase
await clienteService.loadFromFirebase();
```

### Verificar si Firebase está Activo

```dart
if (clienteService.isFirebaseEnabled) {
  print('Firebase está activo');
} else {
  print('Firebase no está disponible');
}
```

## 📱 Ejemplo Completo: Flujo de Migración

```dart
class MigrationScreen extends StatefulWidget {
  @override
  _MigrationScreenState createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isMigrating = false;
  String _status = '';

  Future<void> _migrateToFirebase() async {
    setState(() {
      _isMigrating = true;
      _status = 'Iniciando migración...';
    });

    final clienteService = Provider.of<ClienteService>(context, listen: false);

    try {
      // 1. Cargar datos locales
      setState(() => _status = 'Cargando datos locales...');
      clienteService.init();

      // 2. Verificar que hay datos
      if (clienteService.clientes.isEmpty) {
        setState(() {
          _status = 'No hay pedidos para migrar';
          _isMigrating = false;
        });
        return;
      }

      setState(() => _status = 'Encontrados ${clienteService.clientes.length} pedidos');

      // 3. Migrar a Firebase
      setState(() => _status = 'Subiendo a Firebase...');
      final success = await clienteService.firstSyncFromAndroid();

      if (success) {
        setState(() => _status = '✅ Migración exitosa!');
        
        // 4. Verificar estado
        final status = await clienteService.getSyncStatus();
        setState(() {
          _status = '✅ Migración completada\n'
              'Local: ${status['localPedidos']}\n'
              'Firebase: ${status['firebasePedidos']}';
        });
      } else {
        setState(() => _status = '❌ Error en la migración');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Migración a Firebase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isMigrating)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _migrateToFirebase,
                child: Text('Migrar Pedidos a Firebase'),
              ),
            SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

## 🔐 Seguridad de Datos

### Los datos locales NUNCA se pierden

- ✅ Todos los pedidos se guardan en `SharedPreferences` (local)
- ✅ Firebase es un **backup adicional**, no el almacenamiento principal
- ✅ Si Firebase falla, la app sigue funcionando con datos locales
- ✅ Puedes desactivar Firebase en cualquier momento

### Modo Offline

La app funciona perfectamente sin conexión:

```dart
// Esto funciona sin internet
clienteService.guardarPedido('Cliente 1', items, total);

// Cuando se recupere la conexión, se sincronizará automáticamente
```

## 🐛 Resolución de Problemas

### Firebase no se inicializa

```dart
final firebaseService = FirebaseService();
final initialized = await firebaseService.initialize();

if (!initialized) {
  print('Verifica la configuración de Firebase en firebase_service.dart');
}
```

### Pedidos duplicados

Si tienes pedidos duplicados, usa merge:

```dart
await clienteService.setFirebaseSync(true, mergeStrategy: 'merge');
```

### Limpiar Firebase y empezar de nuevo

```dart
// Desactivar sincronización
await clienteService.setFirebaseSync(false);

// Eliminar datos de Firebase manualmente desde Firebase Console
// Luego volver a activar con datos locales
await clienteService.firstSyncFromAndroid();
```

## 📝 Notas Importantes

1. **Autenticación Anónima**: La app usa autenticación anónima de Firebase (no requiere login)
2. **Identificación de Dispositivo**: Cada dispositivo se identifica automáticamente con un UID único
3. **Persistencia Offline**: Firebase guarda datos localmente y sincroniza cuando hay conexión
4. **Costo**: Firebase tiene un plan gratuito generoso (ver límites en Firebase Console)

## 🔗 Servicios Relacionados

- `StockService` - Sincronización de inventario
- `FirebaseService` - Servicio base de Firebase
- `FirebasePedidoSync` - Sincronización de pedidos (usado internamente)

## 📚 Más Información

- [Documentación Firebase](https://firebase.google.com/docs)
- [Firestore Offline Persistence](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) - Configuración inicial de Firebase
