# 🔥 Firebase Firestore - Sistema de Sincronización

Sistema completo de sincronización con Firebase Firestore para sincronizar Catálogo, Stock y Pedidos entre múltiples dispositivos.

## 📁 Archivos Creados

### ✅ Servicios Core de Firebase

1. **`lib/services/firebase_service.dart`**
   - Servicio base de Firebase
   - Manejo de autenticación anónima
   - Métodos genéricos CRUD para Firestore
   - Gestión de conexión y estado

2. **`lib/services/firebase_catalogo_sync.dart`**
   - Sincronización del catálogo de productos
   - Sincronización de historial de cambios
   - Sincronización en tiempo real
   - Operaciones masivas

3. **`lib/services/firebase_stock_sync.dart`**
   - Sincronización de inventario/stock
   - Control de movimientos
   - Filtros y búsquedas
   - Actualización de cantidades

4. **`lib/services/firebase_pedido_sync.dart`**
   - Sincronización de carritos de compras
   - Historial de pedidos guardados
   - Compartir carritos entre dispositivos
   - Códigos de compartir con expiración

### 📚 Ejemplos de Integración

5. **`lib/services/catalogo_service_with_firebase.dart`**
   - Ejemplo completo de CatalogoService con Firebase integrado
   - Muestra cómo activar/desactivar sincronización
   - Backup automático local + Firebase

6. **`lib/services/stock_service_with_firebase.dart`**
   - Ejemplo completo de StockService con Firebase integrado
   - Sincronización automática de cambios
   - Notificaciones en tiempo real

7. **`lib/services/pedido_service_with_firebase.dart`**
   - Ejemplo completo de PedidoService con Firebase integrado
   - Auto-sincronización del carrito
   - Funciones de compartir y historial

8. **`lib/main_firebase_example.dart`**
   - Ejemplo de configuración en main.dart
   - Inicialización de Firebase
   - UI de demostración para activar/desactivar Firebase

### 📖 Documentación

9. **`FIREBASE_SETUP.md`**
   - Configuración completa de Firebase Console
   - Configuración para Android, iOS y Web
   - Reglas de seguridad de Firestore
   - Estructura de datos
   - Troubleshooting

10. **`MIGRACION_FIREBASE.md`**
    - Guía paso a paso de migración
    - Instrucciones para cada servicio
    - Opciones de migración gradual vs completa
    - Ejemplos de código
    - Cómo revertir cambios

11. **`README_FIREBASE.md`** (este archivo)
    - Resumen del sistema
    - Enlaces rápidos
    - Próximos pasos

## 🚀 Quick Start

### 1. Instalar Dependencias

Las dependencias ya están agregadas en `pubspec.yaml`:

```bash
flutter pub get
```

### 2. Configurar Firebase

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar proyecto
flutterfire configure
```

### 3. Inicializar en tu App

Ver `lib/main_firebase_example.dart` para un ejemplo completo.

Básicamente:

```dart
// En main.dart
await Firebase.initializeApp();
await FirebaseService().initialize();

// En tus servicios
await catalogoService.setFirebaseSync(true);
await stockService.setFirebaseSync(true);
await pedidoService.setFirebaseSync(true);
```

## ✨ Características Principales

### 🔄 Sincronización Bidireccional
- Los cambios en un dispositivo se reflejan automáticamente en todos los demás
- Sincronización en tiempo real usando Firestore Snapshots

### 💾 Persistencia Offline
- Todos los datos se guardan localmente como backup
- Funciona sin conexión a internet
- Se sincroniza automáticamente cuando hay conexión

### 🔐 Seguridad
- Autenticación anónima por dispositivo
- Reglas de seguridad configurables
- Metadata de sincronización (deviceId, timestamp, version)

### 🎯 Características Específicas

#### Catálogo
- ✅ Sincronización de productos
- ✅ Historial de cambios por producto
- ✅ Actualizaciones masivas de precios
- ✅ Filtros por familia, marca, tipo

#### Stock
- ✅ Control de inventario en tiempo real
- ✅ Registro de movimientos
- ✅ Alertas de stock bajo
- ✅ Búsquedas y filtros avanzados

#### Pedidos
- ✅ Carrito sincronizado entre dispositivos
- ✅ Compartir carritos con código QR/texto
- ✅ Historial de pedidos completados
- ✅ Búsqueda por fechas y clientes

## 📋 Estructura de Datos en Firestore

### Colecciones Principales

```
firestore/
├── productos/           # Catálogo de productos
│   └── {productoId}
├── stock/              # Inventario
│   └── {stockId}
├── carritos/           # Carritos activos
│   └── {deviceId}
├── pedidos_guardados/  # Historial de pedidos
│   └── {pedidoId}
└── catalogo_historial/ # Cambios en catálogo
    └── {cambioId}
```

## 🎨 Modo de Uso

### Opción 1: Migración Gradual (Recomendada)

1. Mantén tus servicios actuales
2. Agrega los métodos de sincronización
3. Activa Firebase solo cuando estés listo
4. Prueba con un dispositivo primero

Ver: `MIGRACION_FIREBASE.md` - Opción B

### Opción 2: Reemplazo Completo

1. Renombra tus servicios actuales (backup)
2. Usa las versiones `_with_firebase.dart`
3. Activa Firebase desde el inicio

Ver: `MIGRACION_FIREBASE.md` - Opción A

### Opción 3: Modo Híbrido

- Los servicios están diseñados para funcionar en **modo híbrido**
- Firebase se puede activar/desactivar dinámicamente
- Siempre hay backup local

```dart
// Activar Firebase
await service.setFirebaseSync(true);

// Desactivar Firebase (solo local)
await service.setFirebaseSync(false);
```

## 🔧 Configuración Avanzada

### Reglas de Seguridad Personalizadas

Edita las reglas en Firebase Console según tus necesidades:

```javascript
// Ejemplo: Solo el creador puede modificar sus pedidos
match /pedidos_guardados/{pedidoId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
                  request.auth.uid == resource.data.deviceId;
}
```

### Índices para Mejor Rendimiento

Crea índices compuestos en Firestore Console:

- `stock`: `(type, cant)`
- `pedidos_guardados`: `(createdAt DESC)`
- `catalogo_historial`: `(productoId, fecha DESC)`

### Límites y Cuotas

Firebase gratuito incluye:
- 50,000 lecturas/día
- 20,000 escrituras/día
- 1 GB almacenamiento

Para producción, considera el plan Blaze (pay-as-you-go)

## 📱 Testing

### Probar en Emulador Local

```bash
# Instalar Firebase Emulator Suite
npm install -g firebase-tools
firebase init emulators

# Ejecutar emuladores
firebase emulators:start
```

Luego conecta tu app al emulador (ver documentación oficial)

### Probar Sincronización

1. Ejecuta en 2 dispositivos/emuladores
2. Haz cambios en uno
3. Verifica que aparezcan en el otro automáticamente

## 🐛 Troubleshooting Común

### "Firebase not initialized"
→ Llama a `FirebaseService().initialize()` en `main.dart`

### Los datos no se sincronizan
→ Verifica reglas de Firestore y conexión a internet

### Error en Android build
→ Verifica `google-services.json` en `android/app/`

### Error en iOS build  
→ Verifica `GoogleService-Info.plist` en Xcode

Ver más en: `FIREBASE_SETUP.md` sección Troubleshooting

## 📚 Recursos Adicionales

### Documentación
- [Firebase Setup Completo](./FIREBASE_SETUP.md)
- [Guía de Migración](./MIGRACION_FIREBASE.md)
- [Ejemplo de Main](./lib/main_firebase_example.dart)

### Enlaces Oficiales
- [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
- [Firestore Docs](https://firebase.google.com/docs/firestore)
- [FlutterFire](https://firebase.flutter.dev/)

## 🎯 Próximos Pasos

Ahora que tienes el sistema de sincronización creado:

1. **Lee** `FIREBASE_SETUP.md` para configurar Firebase Console
2. **Ejecuta** `flutterfire configure` para configurar tu proyecto
3. **Sigue** `MIGRACION_FIREBASE.md` para migrar tus servicios
4. **Prueba** en un dispositivo de prueba primero
5. **Activa** Firebase cuando estés listo

## ❓ FAQ

**¿Puedo usar solo algunos servicios con Firebase?**
> Sí, puedes activar Firebase solo en CatalogoService y dejar los otros locales.

**¿Qué pasa si no tengo internet?**
> La app sigue funcionando con datos locales. Se sincroniza cuando vuelva la conexión.

**¿Puedo usar mi propia autenticación?**
> Sí, modifica `firebase_service.dart` para usar Firebase Auth con email/password.

**¿Los datos locales se borran?**
> No, siempre se mantiene un backup local en SharedPreferences.

**¿Cuánto cuesta Firebase?**
> El plan gratuito es suficiente para empezar. Escala según necesites.

## 📞 Soporte

Si necesitas ayuda:
1. Revisa `FIREBASE_SETUP.md` y `MIGRACION_FIREBASE.md`
2. Consulta los logs: `flutter logs`
3. Revisa Firebase Console para errores
4. Consulta los ejemplos en `lib/services/*_with_firebase.dart`

---

**Estado**: ✅ Sistema completo implementado y listo para usar

**Próximo paso**: Configurar Firebase Console (ver `FIREBASE_SETUP.md`)
