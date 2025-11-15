# 🔌 Integrar Flutter App en Laravel

Tu aplicación Flutter ya está construida. Sigue estos pasos para integrarla en Laravel.

---

## ✅ Estado Actual

- ✅ Build completado en `build\web`
- ✅ Base href configurado: `/dashboard-ingreso-salida/`
- ✅ Listo para copiar a Laravel

---

## 📋 Paso 1: Copiar Archivos a Laravel

### Opción A: PowerShell (Recomendada)

```powershell
# Reemplaza C:\ruta\a\tu\proyecto\laravel con la ruta real de tu proyecto Laravel
$laravelPath = "C:\ruta\a\tu\proyecto\laravel\public\dashboard-ingreso-salida"

# Crear directorio si no existe
New-Item -ItemType Directory -Force -Path $laravelPath

# Copiar archivos
Copy-Item -Path "build\web\*" -Destination $laravelPath -Recurse -Force

Write-Host "✅ Archivos copiados a: $laravelPath" -ForegroundColor Green
```

### Opción B: Comando Manual

```powershell
# Navega a tu proyecto Laravel
cd C:\ruta\a\tu\proyecto\laravel

# Crea el directorio
mkdir public\dashboard-ingreso-salida

# Copia los archivos (desde el proyecto Flutter)
Copy-Item -Path "C:\dev\Dashboard-Visitantes\build\web\*" -Destination "C:\dev\cdattg_web\public\dashboard-ingreso-salida\" -Recurse
```

---

## 🔧 Paso 2: Configurar Rutas en Laravel

Edita el archivo `routes/web.php` de tu proyecto Laravel:

```php
<?php

use Illuminate\Support\Facades\Route;

// Ruta principal del dashboard Flutter
Route::get('/dashboard-ingreso-salida', function () {
    $indexPath = public_path('dashboard-ingreso-salida/index.html');
    
    if (!file_exists($indexPath)) {
        abort(404, 'Dashboard no encontrado. Asegúrate de haber copiado los archivos.');
    }
    
    return response()->file($indexPath);
});

// Ruta catch-all para assets y rutas internas de Flutter
Route::get('/dashboard-ingreso-salida/{path}', function ($path) {
    $filePath = public_path("dashboard-ingreso-salida/{$path}");
    
    // Si el archivo existe, servirlo
    if (file_exists($filePath) && is_file($filePath)) {
        return response()->file($filePath);
    }
    
    // Si no existe, devolver index.html (para rutas internas de Flutter)
    $indexPath = public_path('dashboard-ingreso-salida/index.html');
    if (file_exists($indexPath)) {
        return response()->file($indexPath);
    }
    
    abort(404);
})->where('path', '.*');
```

**Nota:** El `->where('path', '.*')` permite que la ruta capture cualquier path, incluyendo barras `/`.

---

## ⚙️ Paso 3: Configurar CORS (Si es Necesario)

Si tu app Flutter hace peticiones a APIs de Laravel, configura CORS:

**`config/cors.php`:**
```php
<?php

return [
    'paths' => ['api/*', 'dashboard-ingreso-salida/*'],
    
    'allowed_methods' => ['*'],
    
    'allowed_origins' => ['*'], // O especifica tu dominio en producción
    
    'allowed_origins_patterns' => [],
    
    'allowed_headers' => ['*'],
    
    'exposed_headers' => [],
    
    'max_age' => 0,
    
    'supports_credentials' => false,
];
```

---

## 🔐 Paso 4: Verificar Variables de Entorno

Si tu app Flutter usa variables de entorno (API_BASE_URL, WS_URL, REVERB_APP_KEY), asegúrate de que estén configuradas correctamente en el build.

**Para reconstruir con variables específicas:**

```powershell
flutter build web --release `
  --base-href=/dashboard-ingreso-salida/ `
  --dart-define=API_BASE_URL=https://tu-dominio.com/api `
  --dart-define=WS_URL=wss://tu-dominio.com/app `
  --dart-define=REVERB_APP_KEY=tu-clave-reverb
```

**Luego vuelve a copiar los archivos a Laravel.**

---

## 🧪 Paso 5: Probar la Integración

### 1. Iniciar servidor Laravel

```powershell
cd C:\ruta\a\tu\proyecto\laravel
php artisan serve
```

### 2. Acceder a la aplicación

Abre tu navegador y visita:
```
http://localhost:8000/dashboard-ingreso-salida
```

### 3. Verificar

- ✅ La aplicación carga correctamente
- ✅ No hay errores en la consola del navegador (F12)
- ✅ Los assets (JS, CSS, imágenes) se cargan
- ✅ Las peticiones API funcionan (si aplica)
- ✅ WebSocket se conecta (si aplica)

---

## 🐛 Solución de Problemas

### Problema: Pantalla en Blanco

**Posibles causas:**
1. Base href incorrecto
2. Archivos no copiados correctamente
3. Rutas de Laravel no configuradas

**Solución:**
1. Verifica que los archivos estén en `public/dashboard-ingreso-salida/`
2. Abre `public/dashboard-ingreso-salida/index.html` y verifica que tenga:
   ```html
   <base href="/dashboard-ingreso-salida/">
   ```
3. Revisa la consola del navegador (F12) para ver errores específicos

### Problema: Assets No Cargan (404)

**Causa:** La ruta catch-all no está capturando los assets.

**Solución:**
Asegúrate de que la ruta tenga `->where('path', '.*')`:
```php
Route::get('/dashboard-ingreso-salida/{path}', ...)->where('path', '.*');
```

### Problema: CORS Error

**Causa:** Laravel bloquea peticiones desde Flutter.

**Solución:**
1. Verifica que `config/cors.php` incluya `dashboard-ingreso-salida/*` en `paths`
2. Limpia la caché de configuración:
   ```powershell
   php artisan config:clear
   ```

### Problema: WebSocket No Conecta

**Causa:** URL de WebSocket incorrecta o Reverb no configurado.

**Solución:**
1. Verifica que Laravel Reverb esté configurado y corriendo
2. Verifica que `REVERB_APP_KEY` en el build coincida con `.env` de Laravel
3. Revisa la consola del navegador para ver errores de conexión

---

## 📝 Script de Copia Automática

Crea un archivo `copy-to-laravel.ps1` en tu proyecto Flutter:

```powershell
# copy-to-laravel.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$LaravelPath
)

$destination = Join-Path $LaravelPath "public\dashboard-ingreso-salida"

Write-Host "📁 Copiando archivos a Laravel..." -ForegroundColor Yellow
Write-Host "   Origen: build\web\" -ForegroundColor Gray
Write-Host "   Destino: $destination" -ForegroundColor Gray

# Crear directorio si no existe
New-Item -ItemType Directory -Force -Path $destination | Out-Null

# Copiar archivos
Copy-Item -Path "build\web\*" -Destination $destination -Recurse -Force

Write-Host "✅ Archivos copiados exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximo paso: Configurar rutas en Laravel (routes/web.php)" -ForegroundColor Cyan
```

**Uso:**
```powershell
.\copy-to-laravel.ps1 -LaravelPath "C:\ruta\a\tu\proyecto\laravel"
```

---

## 🎯 Resumen Rápido

```powershell
# 1. Construir (ya hecho ✅)
flutter build web --release --base-href=/dashboard-ingreso-salida/

# 2. Copiar a Laravel
Copy-Item -Path "build\web\*" -Destination "C:\laravel\public\dashboard-ingreso-salida\" -Recurse

# 3. Configurar rutas en Laravel (routes/web.php)
# Ver código arriba

# 4. Probar
php artisan serve
# Visitar: http://localhost:8000/dashboard-ingreso-salida
```

---

## 📚 Estructura Final en Laravel

```
tu-proyecto-laravel/
├── public/
│   ├── dashboard-ingreso-salida/
│   │   ├── index.html
│   │   ├── main.dart.js
│   │   ├── flutter.js
│   │   ├── assets/
│   │   └── ...
│   ├── index.php
│   └── ...
├── routes/
│   └── web.php          # 👈 Rutas configuradas aquí
└── ...
```

---

**✅ Listo para integrar en Laravel**

