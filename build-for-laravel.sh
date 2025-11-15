#!/bin/bash
# Script de construcción para Laravel (Linux/Mac)
# Uso: ./build-for-laravel.sh [base-href] [api-url] [ws-url] [reverb-key]

set -e

BASE_HREF="${1:-/dashboard/}"
API_URL="${2:-}"
WS_URL="${3:-}"
REVERB_KEY="${4:-}"

echo "🚀 Construyendo aplicación Flutter para Laravel"
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Construir comando base
BUILD_CMD="flutter build web --release --base-href=$BASE_HREF"

# Agregar variables de entorno si se proporcionan
if [ -n "$API_URL" ]; then
    BUILD_CMD="$BUILD_CMD --dart-define=API_BASE_URL=$API_URL"
fi

if [ -n "$WS_URL" ]; then
    BUILD_CMD="$BUILD_CMD --dart-define=WS_URL=$WS_URL"
fi

if [ -n "$REVERB_KEY" ]; then
    BUILD_CMD="$BUILD_CMD --dart-define=REVERB_APP_KEY=$REVERB_KEY"
fi

# Construir
echo "🔨 Construyendo para producción..."
echo "   Base href: $BASE_HREF"
[ -n "$API_URL" ] && echo "   API URL: $API_URL"
[ -n "$WS_URL" ] && echo "   WebSocket URL: $WS_URL"
[ -n "$REVERB_KEY" ] && echo "   Reverb Key: $REVERB_KEY"
echo ""

eval $BUILD_CMD

echo ""
echo "✅ Build completado exitosamente!"
echo ""
echo "📁 Archivos generados en: build/web/"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Copiar archivos a Laravel:"
echo "      cp -r build/web/* /ruta/laravel/public/dashboard/"
echo ""
echo "   2. Configurar ruta en Laravel (routes/web.php):"
echo "      Route::get('/dashboard', function () {"
echo "          return response()->file(public_path('dashboard/index.html'));"
echo "      });"
echo ""
echo "   3. Probar:"
echo "      php artisan serve"
echo "      Visitar: http://localhost:8000/dashboard"
echo ""




