# Módulo de Gestión de Catálogo

## 📋 Descripción
Módulo completo para gestionar la lista de precios de productos, con capacidad de migración a Firebase.

## ✨ Características Implementadas

### 1. **Modelo de Datos Extendido** (`producto.dart`)
- ✅ Campos obligatorios: `id`, `nombre`, `precio`
- ✅ Campos opcionales: `tipo`, `marca`, `codigoStock`, `familia`, `descripcion`
- ✅ Campo `activo` (boolean): Para activar/desactivar productos
- ✅ Campo `esOferta` (boolean): Para marcar productos en oferta (aparecen destacados en PDF)
- ✅ Timestamps: `fechaCreacion`, `fechaModificacion`
- ✅ Compatible con formato actual de `catalogo.json`
- ✅ Preparado para Firebase

### 2. **Servicio de Gestión** (`catalogo_service_with_firebase.dart`)
- ✅ **CRUD completo**: Crear, leer, actualizar y eliminar productos
- ✅ **Búsqueda por nombre**: Filtrado rápido
- ✅ **Actualización masiva de precios**: 4 modos de edición
  - **Aumentar/Disminuir por %**: +10%, -15%, etc.
  - **Sumar/Restar monto fijo**: +$500, -$200, etc.
  - **Asignar precio fijo**: Todos a $5000
  - **Activar/Desactivar productos**: Estado activo/inactivo
- ✅ **Filtros flexibles**: Por familia/marca/tipo en todas las operaciones
- ✅ **Historial de cambios**: Registra todas las modificaciones
- ✅ **Almacenamiento local**: SharedPreferences (fácil migración a Firebase)
- ✅ **Obtención de filtros**: Listas únicas de familias, marcas y tipos
- ✅ **ID automático**: Genera el siguiente ID disponible

### 3. **Interfaz de Usuario** (`catalogo_page.dart`)
- ✅ **Tabla interactiva**: Usando `FinnappDataTable`
  - Ordenamiento por columnas
  - Búsqueda por nombre
  - Paginación (20 items por página)
  - Selección múltiple
  - Contador de items
- ✅ **Columnas visuales**:
  - ID, Nombre, Precio (formateado)
  - Tipo, Familia, Marca, Código Stock
  - **Estado** (Activo/Inactivo con badge verde/rojo)
  - **Oferta** (Checkbox interactivo color naranja)
  - Acciones (Editar/Eliminar)
- ✅ **Acciones por producto**:
  - Editar (botón azul)
  - Eliminar (botón rojo con confirmación)
- ✅ **Acciones globales**:
  - ➕ Nuevo Producto
  - 📝 **Editar Precios** (masivo, sobre seleccionados) con 4 modos:
    - Aumentar/Disminuir por %
    - Sumar/Restar monto fijo
    - Asignar precio fijo
    - Activar/Desactivar
  - 📜 Ver Historial
  - 📤 Importar (placeholder para Excel)
  - 📥 **Exportar** (implementado)
    - **PDF**: Solo productos activos, agrupados por familia, sección de ofertas
    - **Excel**: Todos los productos, todas las columnas, con/sin estadísticas

### 4. **Formularios**
#### ProductoFormDialog
- Crear y editar productos individuales
- Validación de campos obligatorios
- ID automático en creación
- Campos opcionales flexibles
- **Campos inteligentes Tipo y Familia**:
  - Dropdown con opciones predefinidas de `StockType` y `Proveedor`
  - Permite escribir valores personalizados manualmente
  - Sugerencias visuales y tooltips
- **Checkbox "Es Oferta"**:
  - Marca productos para destacar en sección de ofertas del PDF
  - Color naranja para identificación visual

#### EdicionMasivaDialog
- **4 modos de edición**:
  1. **Aumentar/Disminuir por %**: Ej. +10% aumenta, -15% disminuye
  2. **Sumar/Restar monto fijo**: Ej. +$500 suma, -$200 resta
  3. **Asignar precio fijo**: Ej. $5000 a todos los productos filtrados
  4. **Activar/Desactivar**: Cambiar estado activo/inactivo masivamente
- Filtros opcionales:
  - Por familia
  - Por marca
  - Por tipo
- Muestra cantidad de productos afectados
- Validación según tipo de acción

### 5. **Historial de Cambios**
- Página dedicada con lista cronológica
- Muestra: producto, campo modificado, valor anterior/nuevo, fecha
- Iconos y colores por tipo de cambio
- Últimos 100 cambios guardados

### 6. **Exportación a PDF** (`pdf_catalogo_api.dart`)
- ✅ **Portada compacta**: Información del negocio en formato reducido
  - DISTRIBUIDORA ALUSOL
  - Dirección: Eva Peron 417, Temperley
  - Teléfono: +54 9 11 66338293
  - **Envios a todo el pais**
  - Fecha de generación
  - Borde y fondo en tonos naranjas
- ✅ **Sección de Ofertas** (Primera página):
  - 🔥 Banner "OFERTAS ESPECIALES" color naranja
  - Lista todos los productos marcados como oferta
  - Sin agrupación, ordenados alfabéticamente
  - Tabla con fondo naranja claro
- ✅ **Filtrado automático**: Solo productos con `activo = true`
- ✅ **Agrupación por familia**: Una página por cada familia (páginas siguientes)
- ✅ **Ordenamiento**: Productos ordenados alfabéticamente dentro de cada familia
- ✅ **Columnas mostradas**: Nombre, Tipo, Precio (formateado)
- ✅ **Diseño profesional con colores naranjas**: 
  - Encabezados naranja 700
  - Tabla con filas alternadas en gris/naranja claro
  - Bordes y textos en tonos naranjas
  - Pie de página con número de página
  - Formato consistente con facturas existentes
- ✅ **Nombre de archivo**: `Catalogo_YYYY-MM-DD.pdf`
- ⚠️ **Nota**: Los productos en oferta aparecen tanto en la sección de ofertas como en su familia correspondiente

### 7. **Exportación a Excel** (`excel_catalogo_api.dart`)
- ✅ **Dos modalidades de exportación**:
  
  **Modo Básico** (`generate()`):
  - Una sola hoja "Catálogo"
  - Todos los productos (activos e inactivos)
  - 12 columnas completas: ID, Nombre, Precio, Tipo, Marca, Código Stock, Familia, Descripción, Activo, Es Oferta, Fecha Creación, Fecha Modificación
  - Productos ordenados por ID
  - Nombre: `Catalogo_YYYY-MM-DD.xlsx`
  
  **Modo Con Estadísticas** (`generateConEstadisticas()`):
  - **Hoja 1 "Catálogo"**: Lista completa de productos
  - **Hoja 2 "Estadísticas"**: Análisis automático del catálogo
    - Total de productos (activos/inactivos/ofertas)
    - Precios (promedio, mínimo, máximo)
    - Distribución por familia
  - Nombre: `Catalogo_Completo_YYYY-MM-DD.xlsx`

- ✅ **Estilos visuales**:
  - Encabezados con fondo naranja (#FF9800) y texto blanco
  - Productos en oferta: Fondo naranja claro (#FFF3E0)
  - Productos inactivos: Fondo rojo claro (#FFEBEE)
  - Negrita en encabezados y productos destacados

- ✅ **Formato de datos**:
  - Precios como texto (compatible con formato argentino)
  - Fechas formateadas: "YYYY-MM-DD HH:MM:SS"
  - Valores booleanos: "Sí" / "No"
  - Campos vacíos: cadena vacía (no NULL)

- ✅ **Compatibilidad**:
  - Web: Descarga automática del archivo
  - Android/iOS: Guarda en directorio de documentos y abre
  - Compatible con Excel, Google Sheets, LibreOffice

## 🚀 Acceso al Módulo
Desde `PrincipalPage`, nuevo botón en AppBar:
- Icono: 🛒 (Shopping Cart)
- Tooltip: "Gestión de Catálogo"
- Ruta: `"catalogo"`

## 📁 Estructura de Archivos

```
lib/
├── models/
│   └── producto.dart              # Modelo de datos extendido
├── services/
│   └── catalogo_service_with_firebase.dart      # Lógica de negocio y persistencia
├── api/
│   ├── pdf_catalogo_api.dart      # Generación de PDF del catálogo
│   └── excel_catalogo_api.dart    # Generación de Excel del catálogo
├── pages/
│   └── catalogo_page.dart         # UI completa del módulo
└── routes/
    └── routes.dart                # Registro de rutas (actualizado)
```

## 🔄 Migración a Firebase (Pendiente)

El servicio está preparado para migración. Cuando configures Firebase:

1. Cambiar flag en `catalogo_service_with_firebase.dart`:
   ```dart
   bool _useFirebase = true;
   ```

2. Implementar métodos:
   - `_cargarDesdeFirebase()`
   - `_guardarEnFirebase()`

3. Colección sugerida: `productos`
4. ID del documento: usar campo `id` del producto

## 📊 Formato de Datos

### Producto JSON
```json
{
  "ID": "1",
  "nombre": "CORDÓN 4,5 mm",
  "precio": "6634",
  "tipo": "100 Mts",
  "marca": "Acme",
  "codigoStock": "CORD-45",
  "familia": "Cordones",
  "descripcion": "Cordón resistente de 4.5mm",
  "activo": true,
  "esOferta": false,
  "fechaCreacion": "2025-11-04T10:30:00.000Z",
  "fechaModificacion": "2025-11-04T10:30:00.000Z"
}
```

### Historial JSON
```json
{
  "id": "1730728800000",
  "productoId": "1",
  "nombreProducto": "CORDÓN 4,5 mm",
  "campo": "precio",
  "valorAnterior": "6634",
  "valorNuevo": "7297",
  "fecha": "2025-11-04T10:30:00.000Z",
  "usuario": null
}
```

## 🎯 Próximos Pasos (Para ti)

### Corto Plazo
1. ⏳ **Importar desde Excel**
   - Usar package `excel` o `csv`
   - Mapear columnas a campos de `Producto`
   - Validar antes de importar

2. ✅ **Exportar a PDF** (COMPLETADO)
   - ✅ PDF generado con `pdf` package
   - ✅ Portada con información del negocio
   - ✅ Solo productos activos
   - ✅ Agrupado por familia
   - ✅ Muestra: nombre, tipo y precio
   - ✅ Similar a `pdf_invoice_api.dart`
   
3. ✅ **Exportar a Excel** (COMPLETADO)
   - ✅ Package `excel` v4.0.6 integrado
   - ✅ Dos modalidades de exportación:
     - **Básico**: Solo lista con todos los campos
     - **Con Estadísticas**: Lista + hoja de análisis
   - ✅ Exporta TODOS los productos (activos e inactivos)
   - ✅ Todas las 12 columnas incluidas
   - ✅ Estilos visuales (ofertas en naranja, inactivos en rojo)
   - ✅ Formato automático de fechas

### Largo Plazo
3. ✅ **Configurar Firebase**
   - Agregar Firebase al proyecto
   - Crear colección `productos`
   - Activar flag en `CatalogoService`

4. ✅ **Autenticación** (opcional)
   - Firebase Auth
   - Controlar quién puede editar
   - Registrar usuario en historial

## 🧪 Testing

### Probar funcionalidades:
1. **Crear producto**: Botón "Nuevo Producto"
2. **Editar producto**: Click en icono azul de edición
3. **Eliminar producto**: Click en icono rojo (con confirmación)
4. **Búsqueda**: Buscar por nombre en barra superior
5. **Ordenar**: Click en headers de columnas (incluido estado activo/inactivo)
6. **Edición masiva**: 
   - Seleccionar productos (checkbox) o aplicar con filtros
   - Click "Editar Precios"
   - Elegir acción:
     - **Aumentar %**: +10 (aumenta 10%)
     - **Sumar monto**: 500 (suma $500)
     - **Asignar precio**: 5000 (todos a $5000)
     - **Activar/Desactivar**: cambiar estado
   - Aplicar filtros opcionales (familia/marca/tipo)
7. **Historial**: Click en icono de historial (AppBar)
8. **Ver estado**: Badge verde (Activo) o rojo (Inactivo) en columna Estado

## 💡 Notas Importantes

- ✅ Datos se guardan en `SharedPreferences` (clave: `catalogo_modificado`)
- ✅ Historial limitado a 100 últimos cambios
- ✅ Formato compatible con `catalogo.json` actual
- ✅ IDs numéricos autoincrementales
- ✅ Todos los campos opcionales excepto id, nombre y precio
- ✅ **Campos Tipo y Familia**: Integrados con enums `StockType` y `Proveedor`
  - Opciones predefinidas en dropdown
  - Escritura manual permitida para valores personalizados
- ✅ Sin errores de compilación
- ✅ Integrado con navegación existente

## 🎨 UI/UX

- Colores consistentes con el resto de la app
- AppBar: `Colors.blueGrey`
- Formateo de precios: `\$6.634` (sin decimales)
- Iconos intuitivos para acciones
- Confirmación antes de eliminar
- Feedback con `SnackBar` para todas las acciones

---

**Estado**: ✅ **COMPLETO Y FUNCIONAL**  
**Listo para**: Pruebas y extensión con Excel/PDF/Firebase
