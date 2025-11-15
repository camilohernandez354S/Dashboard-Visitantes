# Script para copiar archivos Flutter a Laravel
# Uso: .\copy-to-laravel.ps1 -LaravelPath "C:\ruta\a\laravel"

param(
    [Parameter(Mandatory=$true)]
    [string]$LaravelPath
)

$destination = Join-Path $LaravelPath "public\dashboard-ingreso-salida"

# Verificar que existe build/web
if (-not (Test-Path "build\web")) {
    Write-Host "❌ Error: No se encontró build\web\" -ForegroundColor Red
    Write-Host "   Ejecuta primero: flutter build web --release --base-href=/dashboard-ingreso-salida/" -ForegroundColor Yellow
    exit 1
}

# Verificar que Laravel existe
if (-not (Test-Path $LaravelPath)) {
    Write-Host "❌ Error: No se encontró el directorio Laravel: $LaravelPath" -ForegroundColor Red
    exit 1
}

# Verificar que existe public/
$publicPath = Join-Path $LaravelPath "public"
if (-not (Test-Path $publicPath)) {
    Write-Host "❌ Error: No se encontró public/ en Laravel" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Copiando archivos Flutter a Laravel..." -ForegroundColor Cyan
Write-Host "   Origen: build\web\" -ForegroundColor Gray
Write-Host "   Destino: $destination" -ForegroundColor Gray
Write-Host ""

# Crear directorio si no existe
New-Item -ItemType Directory -Force -Path $destination | Out-Null

# Copiar archivos
try {
    Copy-Item -Path "build\web\*" -Destination $destination -Recurse -Force
    Write-Host "✅ Archivos copiados exitosamente!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al copiar archivos: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "   1. Configurar rutas en Laravel (routes/web.php)" -ForegroundColor White
Write-Host "      Ver archivo: INTEGRAR_EN_LARAVEL.md" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Probar la aplicación:" -ForegroundColor White
Write-Host "      cd $LaravelPath" -ForegroundColor Gray
Write-Host "      php artisan serve" -ForegroundColor Gray
Write-Host "      Visitar: http://localhost:8000/dashboard-ingreso-salida" -ForegroundColor Gray
Write-Host ""




