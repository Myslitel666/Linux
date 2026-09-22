#!/bin/bash
# Если отказано в доступе, то chmod +x ~/Programming/Linux/create-launcher.sh

echo "=== AppImage Launcher ==="
echo

read -e -i "/home/nexus/Programs/" -p "Путь до AppImage: " APPIMAGE
read -e -i "/home/nexus/MyFolder/Design/Icons/" -p "Путь до иконки PNG: " ICON
read -r -p "Название приложения: " NAME

echo

if [ ! -f "$APPIMAGE" ]; then
    echo "Ошибка: AppImage не найден:"
    echo "$APPIMAGE"
    exit 1
fi

if [ ! -f "$ICON" ]; then
    echo "Ошибка: иконка не найдена:"
    echo "$ICON"
    exit 1
fi

LOG="/tmp/appimage-launcher.log"

echo "Запускаю AppImage..."

WAYLAND_DEBUG=1 "$APPIMAGE" >"$LOG" 2>&1 &
PID=$!

echo "PID: $PID"
echo "Жду app_id..."

for i in {1..100}; do
    if grep -q 'set_app_id' "$LOG"; then
        break
    fi

    sleep 0.1
done

APP_ID=$(grep -oP 'set_app_id\("\K[^"]+' "$LOG" | head -n1)

if [ -z "$APP_ID" ]; then
    echo
    echo "Ошибка: не удалось определить app_id."
    echo
    echo "Последний вывод AppImage:"
    tail -30 "$LOG"

    kill "$PID" 2>/dev/null
    exit 1
fi

echo "app_id: $APP_ID"

kill "$PID" 2>/dev/null
wait "$PID" 2>/dev/null

APPLICATIONS_DIR="$HOME/.local/share/applications"
mkdir -p "$APPLICATIONS_DIR"

# Безопасное имя файла .desktop
DESKTOP_ID="$APP_ID"
DESKTOP="$APPLICATIONS_DIR/$DESKTOP_ID.desktop"

cat > "$DESKTOP" <<EOF
[Desktop Entry]
Name=$NAME
Exec=$APPIMAGE
Icon=$ICON
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=$APP_ID
EOF

#Обновляем иконку на самом файле AppImage для отображения в папке
gio set "$APPIMAGE" metadata::custom-icon "file://$ICON"

update-desktop-database "$APPLICATIONS_DIR" 2>/dev/null || true

echo
echo "=== Готово ==="
echo "Название: $NAME"
echo "AppImage: $APPIMAGE"
echo "Иконка: $ICON"
echo "App ID: $APP_ID"
echo "Launcher: $DESKTOP"