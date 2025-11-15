# 🚀 Construir Flutter App para Laravel

Guía completa para construir la aplicación Flutter y montarla en Laravel.

---

## 📋 Requisitos Previos

1. Flutter SDK instalado y configurado
2. Laravel instalado y funcionando
3. Node.js (opcional, para optimizaciones)

---

## 🔧 Paso 1: Construir la Aplicación Flutter para Web

### Opción A: Construcción Básica (Recomendada)

```bash
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Construir para producción
flutter build web --release
```

**Resultado:** Los archivos se generan en `build/web/`

### Opción B: Construcción con Base Path Personalizado

Si Laravel servirá la app en una ruta específica (ej: `/dashboard`):

```bash
flutter build web --release --base-href=/dashboard/
```

**Importante:** El base-href debe terminar con `/`

### Opción C: Construcción con Variables de Entorno

Si necesitas configurar URLs de API o WebSocket:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://tu-dominio.com/api \
  --dart-define=WS_URL=wss://tu-dominio.com/app \
  --dart-define=REVERB_APP_KEY=tu-clave-reverb
```

---

## 📁 Paso 2: Estructura de Archivos Generados

Después de `flutter build web --release`, tendrás:

```
build/web/
├── index.html          # Punto de entrada
├── main.dart.js        # Código compilado
├── flutter.js          # Runtime de Flutter
├── flutter_bootstrap.js # Bootstrap
├── assets/             # Assets estáticos
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   └── ...
└── canvaskit/          # CanvasKit (si se usa)
```

---

## 🔌 Paso 3: Integración en Laravel

### Opción 1: Servir desde `public/` (Recomendada)

**Estructura Laravel:**
```
tu-proyecto-laravel/
├── public/
│   ├── dashboard/          # 👈 Carpeta para Flutter
│   │   ├── index.html
│   │   ├── main.dart.js
│   │   └── ...
│   ├── index.php
│   └── ...
└── ...
```

**Pasos:**

1. **Copiar archivos a Laravel:**
```bash
# Desde el directorio del proyecto Flutter
cp -r build/web/* /ruta/a/laravel/public/dashboard/
```

**En Windows (PowerShell):**
```powershell
Copy-Item -Path "build\web\*" -Destination "C:\ruta\a\laravel\public\dashboard\" -Recurse
```

2. **Crear ruta en Laravel** (`routes/web.php`):

```php
Route::get('/dashboard', function () {
    return response()->file(public_path('dashboard/index.html'));
});

// Ruta catch-all para assets de Flutter
Route::get('/dashboard/{path}', function ($path) {
    $filePath = public_path("dashboard/{$path}");
    
    if (file_exists($filePath) && is_file($filePath)) {
        return response()->file($filePath);
    }
    
    // Si no existe, devolver index.html (para rutas de Flutter)
    return response()->file(public_path('dashboard/index.html'));
})->where('path', '.*');
```

### Opción 2: Servir desde Subdirectorio con Base Path

Si usaste `--base-href=/dashboard/`:

1. **Copiar archivos:**
```bash
cp -r build/web/* /ruta/a/laravel/public/dashboard/
```

2. **Ruta Laravel:**
```php
Route::get('/dashboard', function () {
    return response()->file(public_path('dashboard/index.html'));
});

Route::get('/dashboard/{path}', function ($path) {
    $filePath = public_path("dashboard/{$path}");
    return file_exists($filePath) 
        ? response()->file($filePath)
        : response()->file(public_path('dashboard/index.html'));
})->where('path', '.*');
```

### Opción 3: Servir desde Raíz (Reemplazar Laravel Frontend)

**⚠️ Advertencia:** Esto reemplazará la vista principal de Laravel.

```bash
# Copiar a public/
cp -r build/web/* /ruta/a/laravel/public/
```

**Ruta Laravel:**
```php
Route::get('/', function () {
    return response()->file(public_path('index.html'));
});

Route::get('/{path}', function ($path) {
    $filePath = public_path($path);
    return file_exists($filePath) 
        ? response()->file($filePath)
        : response()->file(public_path('index.html'));
})->where('path', '.*');
```

---

## ⚙️ Paso 4: Configuración de CORS (Si es Necesario)

Si la app Flutter hace peticiones a APIs externas, configura CORS en Laravel:

**`config/cors.php`:**
```php
'paths' => ['api/*', 'dashboard/*'],
'allowed_origins' => ['*'], // O especifica tu dominio
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

---

## 🔐 Paso 5: Configurar Variables de Entorno

### En Flutter (Build Time)

Las variables se definen al construir:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://tu-dominio.com/api \
  --dart-define=WS_URL=wss://tu-dominio.com/app \
  --dart-define=REVERB_APP_KEY=tu-clave
```

### En Laravel (.env)

Asegúrate de que Laravel tenga las mismas configuraciones:

```env
REVERB_APP_KEY=tu-clave-reverb
REVERB_HOST=tu-dominio.com
REVERB_PORT=443
REVERB_SCHEME=https
```

---

## 🧪 Paso 6: Probar la Integración

1. **Iniciar servidor Laravel:**
```bash
php artisan serve
```

2. **Acceder a la app:**
```
http://localhost:8000/dashboard
```

3. **Verificar:**
   - ✅ La app carga correctamente
   - ✅ Los assets (JS, CSS, imágenes) se cargan
   - ✅ Las peticiones API funcionan
   - ✅ WebSocket se conecta (si aplica)

---

## 🐛 Solución de Problemas

### Problema: Pantalla en Blanco

**Causa:** Base href incorrecto o rutas no configuradas.

**Solución:**
1. Verifica que `index.html` tenga `<base href="/dashboard/">` (o la ruta correcta)
2. Reconstruye con el base-href correcto:
```bash
flutter build web --release --base-href=/dashboard/
```

### Problema: Assets No Cargan (404)

**Causa:** Rutas de Laravel no capturan los assets.

**Solución:**
Asegúrate de que la ruta catch-all esté configurada correctamente:
```php
Route::get('/dashboard/{path}', ...)->where('path', '.*');
```

### Problema: CORS Error

**Causa:** Laravel bloquea peticiones desde Flutter.

**Solución:**
1. Configura CORS en `config/cors.php`
2. O usa middleware de CORS en las rutas de API

### Problema: WebSocket No Conecta

**Causa:** URL de WebSocket incorrecta o CORS.

**Solución:**
1. Verifica que `WS_URL` en el build coincida con Laravel Reverb
2. Asegúrate de que Reverb esté configurado y corriendo
3. Verifica que `REVERB_APP_KEY` coincida en ambos lados

---

## 📝 Script de Construcción Automática

Crea un script para automatizar el proceso:

**`build-for-laravel.sh` (Linux/Mac):**
```bash
#!/bin/bash
set -e

echo "🧹 Limpiando builds anteriores..."
flutter clean

echo "📦 Obteniendo dependencias..."
flutter pub get

echo "🔨 Construyendo para producción..."
flutter build web --release --base-href=/dashboard/

echo "✅ Build completado en build/web/"
echo "📋 Próximo paso: Copiar build/web/* a Laravel public/dashboard/"
```

**`build-for-laravel.ps1` (Windows):**
```powershell
Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean

Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "🔨 Construyendo para producción..." -ForegroundColor Yellow
flutter build web --release --base-href=/dashboard/

Write-Host "✅ Build completado en build/web/" -ForegroundColor Green
Write-Host "📋 Próximo paso: Copiar build/web/* a Laravel public/dashboard/" -ForegroundColor Cyan
```

---

## 🎯 Resumen Rápido

```bash
# 1. Construir
flutter build web --release --base-href=/dashboard/

# 2. Copiar a Laravel
cp -r build/web/* /ruta/laravel/public/dashboard/

# 3. Configurar ruta en Laravel
# (Ver Opción 1 arriba)

# 4. Probar
php artisan serve
# Visitar: http://localhost:8000/dashboard
```

---

## 📚 Referencias

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Laravel Routing](https://laravel.com/docs/routing)
- [Laravel Reverb](https://laravel.com/docs/reverb)

---

**✅ Listo para producción**

